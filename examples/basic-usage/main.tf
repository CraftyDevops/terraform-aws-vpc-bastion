module "vpc_bastion_example" {
  source = "CraftyDevops/vpc-bastion/aws"

  name_prefix    = "vpc-dev"
  vpc_cidr_block = "10.10.0.0/16"
  azs            = ["eu-west-2a", "eu-west-2b"]

  // Enable NAT Gateway (single for cost saving)
  enable_nat_gateway = true
  single_nat_gateway = true

  // Enable Bastion Host
  enable_bastion_host         = true
  bastion_ssh_key_name        = aws_key_pair.test.key_name
  bastion_ingress_cidr_blocks = ["YOUR_PUBLIC_IP/32"]
  bastion_instance_type       = "t2.micro"

  tags = {
    Environment = "development"
    Project     = "vpc-dev"
  }
}

resource "aws_key_pair" "test" {
  key_name   = "test-key"
  public_key = "public-key"
}
