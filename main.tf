locals {
  num_azs = length(var.azs)

  calculated_public_subnet_cidrs = [
    for i in range(local.num_azs) :
    cidrsubnet(var.vpc_cidr_block, 8, i)
  ]
  calculated_private_subnet_cidrs = [
    for i in range(local.num_azs) :
    cidrsubnet(var.vpc_cidr_block, 8, i + local.num_azs)
  ]

  public_subnet_cidrs  = length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs : local.calculated_public_subnet_cidrs
  private_subnet_cidrs = length(var.private_subnet_cidrs) > 0 ? var.private_subnet_cidrs : local.calculated_private_subnet_cidrs

  common_tags = merge(
    var.tags,
    {
      "Name" = var.name_prefix
    }
  )

  base_name = var.name_prefix

  nat_instance_enabled = var.enable_nat_instance && !var.enable_nat_gateway
}

#------------------------------------------------------------------------------
# VPC
#------------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = var.vpc_enable_dns_support
  enable_dns_hostnames = var.vpc_enable_dns_hostnames

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.name_prefix}-vpc"
    }
  )
}

#------------------------------------------------------------------------------
# Internet Gateway
#------------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.name_prefix}-igw"
    }
  )
}

#------------------------------------------------------------------------------
# Subnets - Public
#------------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count                   = local.num_azs
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(local.public_subnet_cidrs, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = var.subnet_map_public_ip_on_launch

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.base_name}-public-subnet-${element(var.azs, count.index)}"
    }
  )
}

#------------------------------------------------------------------------------
# Subnets - Private
#------------------------------------------------------------------------------
resource "aws_subnet" "private" {
  count             = local.num_azs
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(local.private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.base_name}-private-subnet-${element(var.azs, count.index)}"
    }
  )
}

#------------------------------------------------------------------------------
# NAT Gateway & EIPs (if enabled)
#------------------------------------------------------------------------------
resource "aws_eip" "nat_gateway" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : local.num_azs) : 0
  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      "Name" = var.single_nat_gateway ? "${var.name_prefix}-nat-eip" : "${var.name_prefix}-nat-eip-${element(var.azs, count.index)}"
    }
  )
}

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : local.num_azs) : 0
  allocation_id = aws_eip.nat_gateway[count.index].id
  subnet_id     = aws_subnet.public[var.single_nat_gateway ? 0 : count.index].id

  tags = merge(
    local.common_tags,
    {
      "Name" = var.single_nat_gateway ? "${var.name_prefix}-nat-gateway" : "${var.name_prefix}-nat-gateway-${element(var.azs, count.index)}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

#------------------------------------------------------------------------------
# Routing - Public Subnets
#------------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.name_prefix}-public-rtb"
    }
  )
}

resource "aws_route_table_association" "public" {
  count          = local.num_azs
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

#------------------------------------------------------------------------------
# Routing - Private Subnets
#------------------------------------------------------------------------------
resource "aws_route_table" "private" {
  count  = local.num_azs
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[var.single_nat_gateway ? 0 : count.index].id
    }
  }

  dynamic "route" {
    for_each = local.nat_instance_enabled ? [1] : []
    content {
      cidr_block = "0.0.0.0/0"
      network_interface_id = aws_instance.nat[var.single_nat_gateway ? 0 : count.index].primary_network_interface_id
    }
  }

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.name_prefix}-private-rtb-${element(var.azs, count.index)}"
    }
  )
}

resource "aws_route_table_association" "private" {
  count          = local.num_azs
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

#------------------------------------------------------------------------------
# NAT Instance (if enabled and NAT Gateway is not)
#------------------------------------------------------------------------------
data "aws_ami" "nat_instance_ami" {
  count = local.nat_instance_enabled && var.nat_instance_ami_id == null ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_eip" "nat_instance" {
  count = local.nat_instance_enabled ? (var.single_nat_gateway ? 1 : local.num_azs) : 0
  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      "Name" = var.single_nat_gateway ? "${var.name_prefix}-nat-instance-eip" : "${var.name_prefix}-nat-instance-eip-${element(var.azs, count.index)}"
    }
  )
}

resource "aws_security_group" "nat_instance" {
  count       = local.nat_instance_enabled ? 1 : 0
  name        = "${var.name_prefix}-nat-instance-sg"
  description = "Security group for NAT instance, allows traffic from private subnets"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow all traffic from private subnets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.private_subnet_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.name_prefix}-nat-instance-sg"
    }
  )
}

resource "aws_instance" "nat" {
  count = local.nat_instance_enabled ? (var.single_nat_gateway ? 1 : local.num_azs) : 0

  ami                         = var.nat_instance_ami_id == null ? data.aws_ami.nat_instance_ami[0].id : var.nat_instance_ami_id
  instance_type               = var.nat_instance_type
  key_name                    = var.nat_instance_key_name
  subnet_id                   = aws_subnet.public[var.single_nat_gateway ? 0 : count.index].id
  vpc_security_group_ids      = [aws_security_group.nat_instance[0].id]
  associate_public_ip_address = false
  source_dest_check           = false

  tags = merge(
    local.common_tags,
    {
      "Name" = var.single_nat_gateway ? "${var.name_prefix}-nat-instance" : "${var.name_prefix}-nat-instance-${element(var.azs, count.index)}"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip_association" "nat_instance" {
  count         = local.nat_instance_enabled ? (var.single_nat_gateway ? 1 : local.num_azs) : 0
  instance_id   = aws_instance.nat[count.index].id
  allocation_id = aws_eip.nat_instance[count.index].id
}


#------------------------------------------------------------------------------
# Bastion Host (if enabled)
#------------------------------------------------------------------------------
data "aws_ami" "bastion_ami" {
  count = var.enable_bastion_host && var.bastion_ami_id == null ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "bastion" {
  count       = var.enable_bastion_host ? 1 : 0
  name        = "${var.name_prefix}-bastion-sg"
  description = "Security group for Bastion Host"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow SSH from specified CIDRs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_ingress_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.name_prefix}-bastion-sg"
    }
  )
}

resource "aws_instance" "bastion" {
  count = var.enable_bastion_host ? 1 : 0

  ami                         = var.bastion_ami_id == null ? data.aws_ami.bastion_ami[0].id : var.bastion_ami_id
  instance_type               = var.bastion_instance_type
  key_name                    = var.bastion_ssh_key_name
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.bastion[0].id]
  associate_public_ip_address = var.associate_public_ip_address_bastion
  user_data                   = var.bastion_user_data

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.name_prefix}-bastion-host"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}