<!-- BEGIN_TF_DOCS -->

# Terraform AWS VPC Bastion Module

Terraform module to create a secure and flexible AWS VPC with public/private subnets, NAT Gateway/Instance, and a bastion host.

## Features

- Creates a VPC with a user-defined CIDR block.
- Creates public and private subnets across multiple Availability Zones.
- Optionally creates a NAT Gateway or NAT Instance for outbound internet access from private subnets.
- Optionally creates a Bastion Host in a public subnet for secure access to private resources.
- Configurable Security Groups.

## Usage

```terraform
module "vpc_bastion" {

  source = "CraftyDevops/vpc-bastion/aws"

  name_prefix    = "prod-app"
  vpc_cidr_block = "10.0.0.0/16"
  azs            = ["us-east-1a", "us-east-1b", "us-east-1c"] // Ensure these AZs are available in your selected region

  # --- NAT Gateway Configuration (Recommended for most production workloads) ---
  enable_nat_gateway = true
  # To create one NAT Gateway per AZ for higher availability (more costly):
  single_nat_gateway = false
  # To create a single NAT Gateway for all AZs (less costly, suitable for dev/test or smaller prod):
  # single_nat_gateway = true

  # --- NAT Instance Configuration (Alternative, lower cost, self-managed) ---
  # If you prefer a NAT instance instead of a NAT Gateway, set enable_nat_gateway = false
  # and uncomment the following:
  # enable_nat_instance = true
  # nat_instance_type   = "t3.micro" # Choose an appropriate instance type
  # nat_instance_key_name = "my-nat-instance-keypair" # Optional: Key pair for SSH access to NAT instance for troubleshooting

  # --- Bastion Host Configuration ---
  enable_bastion_host         = true
  bastion_instance_type       = "t2.micro"
  bastion_ssh_key_name        = "your-bastion-key-pair-name"      // IMPORTANT: REPLACE with your actual EC2 Key Pair name
  bastion_ingress_cidr_blocks = ["YOUR_PUBLIC_IP_ADDRESS/32"]     // IMPORTANT: REPLACE with your public IP address for secure SSH access

  # Example user data for the bastion host (e.g., install common tools)
  # bastion_user_data = <<-EOF
  # #!/bin/bash
  # yum update -y
  # yum install -y telnet bind-utils
  # EOF

  # --- Common Tags ---
  tags = {
    Environment = "production"
    Project     = "WebAppX"
    Owner       = "DevOpsTeam"
    Terraform   = "true"
  }
}

# Example Outputs
output "vpc_id" {
  description = "The ID of the created VPC"
  value       = module.my_secure_vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.my_secure_vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.my_secure_vpc.private_subnet_ids
}

output "bastion_public_ip" {
  description = "Public IP address of the Bastion Host (if enabled)"
  value       = module.my_secure_vpc.bastion_host_public_ip
}

output "nat_gateway_public_ips" {
  description = "List of public IP addresses for the NAT Gateways (if enabled)"
  value       = module.my_secure_vpc.nat_gateway_public_ips
}
```

## Requirements

| Name                                                                     | Version |
| ------------------------------------------------------------------------ | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.0  |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >= 4.0  |

## Providers

| Name                                             | Version |
| ------------------------------------------------ | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | 5.98.0  |

## Modules

No modules.

## Resources

| Name                                                                                                                                       | Type        |
| ------------------------------------------------------------------------------------------------------------------------------------------ | ----------- |
| [aws_eip.nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip)                                     | resource    |
| [aws_eip.nat_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip)                                    | resource    |
| [aws_eip_association.nat_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip_association)            | resource    |
| [aws_instance.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)                               | resource    |
| [aws_instance.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)                                   | resource    |
| [aws_internet_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway)                  | resource    |
| [aws_nat_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway)                            | resource    |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table)                         | resource    |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table)                          | resource    |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource    |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association)  | resource    |
| [aws_security_group.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                   | resource    |
| [aws_security_group.nat_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)              | resource    |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet)                                   | resource    |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet)                                    | resource    |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc)                                            | resource    |
| [aws_ami.bastion_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami)                                  | data source |
| [aws_ami.nat_instance_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami)                             | data source |

## Inputs

| Name                                                                                                                                       | Description                                                                                                           | Type           | Default                             | Required |
| ------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------- | -------------- | ----------------------------------- | :------: |
| <a name="input_associate_public_ip_address_bastion"></a> [associate_public_ip_address_bastion](#input_associate_public_ip_address_bastion) | Associate a public IP address with the bastion host. Set to false if using an Elastic IP.                             | `bool`         | `true`                              |    no    |
| <a name="input_azs"></a> [azs](#input_azs)                                                                                                 | A list of Availability Zones to use for subnets.                                                                      | `list(string)` | n/a                                 |   yes    |
| <a name="input_bastion_ami_id"></a> [bastion_ami_id](#input_bastion_ami_id)                                                                | The AMI ID for the Bastion Host. If null, latest Amazon Linux 2 will be used.                                         | `string`       | `null`                              |    no    |
| <a name="input_bastion_ingress_cidr_blocks"></a> [bastion_ingress_cidr_blocks](#input_bastion_ingress_cidr_blocks)                         | A list of CIDR blocks allowed to SSH into the Bastion Host.                                                           | `list(string)` | <pre>[<br/> "0.0.0.0/0"<br/>]</pre> |    no    |
| <a name="input_bastion_instance_type"></a> [bastion_instance_type](#input_bastion_instance_type)                                           | The instance type to use for the Bastion Host.                                                                        | `string`       | `"t2.micro"`                        |    no    |
| <a name="input_bastion_ssh_key_name"></a> [bastion_ssh_key_name](#input_bastion_ssh_key_name)                                              | The EC2 Key Pair name for the Bastion Host (required if enable_bastion_host is true).                                 | `string`       | `null`                              |    no    |
| <a name="input_bastion_user_data"></a> [bastion_user_data](#input_bastion_user_data)                                                       | User data script to run on the Bastion Host at launch.                                                                | `string`       | `null`                              |    no    |
| <a name="input_enable_bastion_host"></a> [enable_bastion_host](#input_enable_bastion_host)                                                 | Set to true to create a Bastion Host in a public subnet.                                                              | `bool`         | `false`                             |    no    |
| <a name="input_enable_nat_gateway"></a> [enable_nat_gateway](#input_enable_nat_gateway)                                                    | Set to true to create a NAT Gateway for outbound internet access from private subnets.                                | `bool`         | `false`                             |    no    |
| <a name="input_enable_nat_instance"></a> [enable_nat_instance](#input_enable_nat_instance)                                                 | Set to true to create a NAT Instance. Ignored if enable_nat_gateway is true.                                          | `bool`         | `false`                             |    no    |
| <a name="input_name_prefix"></a> [name_prefix](#input_name_prefix)                                                                         | A prefix to be added to the names of all created resources.                                                           | `string`       | `"tf-vpc-bastion"`                  |    no    |
| <a name="input_nat_instance_ami_id"></a> [nat_instance_ami_id](#input_nat_instance_ami_id)                                                 | The AMI ID for the NAT instance. If null, latest Amazon Linux 2 will be used. Ensure it's configured for NAT.         | `string`       | `null`                              |    no    |
| <a name="input_nat_instance_key_name"></a> [nat_instance_key_name](#input_nat_instance_key_name)                                           | The EC2 Key Pair name for the NAT instance (for SSH access if needed).                                                | `string`       | `null`                              |    no    |
| <a name="input_nat_instance_type"></a> [nat_instance_type](#input_nat_instance_type)                                                       | The instance type to use for the NAT instance.                                                                        | `string`       | `"t3.micro"`                        |    no    |
| <a name="input_private_subnet_cidrs"></a> [private_subnet_cidrs](#input_private_subnet_cidrs)                                              | A list of CIDR blocks for private subnets. Must match the number of AZs.                                              | `list(string)` | `[]`                                |    no    |
| <a name="input_public_subnet_cidrs"></a> [public_subnet_cidrs](#input_public_subnet_cidrs)                                                 | A list of CIDR blocks for public subnets. Must match the number of AZs.                                               | `list(string)` | `[]`                                |    no    |
| <a name="input_single_nat_gateway"></a> [single_nat_gateway](#input_single_nat_gateway)                                                    | Set to true to create a single NAT Gateway. If false, a NAT Gateway will be created in each AZ with a private subnet. | `bool`         | `true`                              |    no    |
| <a name="input_subnet_map_public_ip_on_launch"></a> [subnet_map_public_ip_on_launch](#input_subnet_map_public_ip_on_launch)                | Specify true to indicate that instances launched into the public subnet receive a public IP address.                  | `bool`         | `true`                              |    no    |
| <a name="input_tags"></a> [tags](#input_tags)                                                                                              | A map of tags to add to all resources.                                                                                | `map(string)`  | `{}`                                |    no    |
| <a name="input_vpc_cidr_block"></a> [vpc_cidr_block](#input_vpc_cidr_block)                                                                | The CIDR block for the VPC.                                                                                           | `string`       | `"10.0.0.0/16"`                     |    no    |
| <a name="input_vpc_enable_dns_hostnames"></a> [vpc_enable_dns_hostnames](#input_vpc_enable_dns_hostnames)                                  | Enable DNS hostnames in the VPC.                                                                                      | `bool`         | `true`                              |    no    |
| <a name="input_vpc_enable_dns_support"></a> [vpc_enable_dns_support](#input_vpc_enable_dns_support)                                        | Enable DNS support in the VPC.                                                                                        | `bool`         | `true`                              |    no    |

## Outputs

| Name                                                                                                                       | Description                                                         |
| -------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| <a name="output_bastion_host_id"></a> [bastion_host_id](#output_bastion_host_id)                                           | The ID of the Bastion Host instance (if created).                   |
| <a name="output_bastion_host_private_ip"></a> [bastion_host_private_ip](#output_bastion_host_private_ip)                   | The private IP address of the Bastion Host (if created).            |
| <a name="output_bastion_host_public_ip"></a> [bastion_host_public_ip](#output_bastion_host_public_ip)                      | The public IP address of the Bastion Host (if created and has one). |
| <a name="output_bastion_security_group_id"></a> [bastion_security_group_id](#output_bastion_security_group_id)             | The ID of the Bastion Host's security group (if created).           |
| <a name="output_internet_gateway_id"></a> [internet_gateway_id](#output_internet_gateway_id)                               | The ID of the Internet Gateway.                                     |
| <a name="output_nat_gateway_ids"></a> [nat_gateway_ids](#output_nat_gateway_ids)                                           | List of IDs of the NAT Gateways.                                    |
| <a name="output_nat_gateway_public_ips"></a> [nat_gateway_public_ips](#output_nat_gateway_public_ips)                      | List of public Elastic IP addresses allocated to the NAT Gateways.  |
| <a name="output_nat_instance_ids"></a> [nat_instance_ids](#output_nat_instance_ids)                                        | List of IDs of the NAT Instances.                                   |
| <a name="output_nat_instance_public_ips"></a> [nat_instance_public_ips](#output_nat_instance_public_ips)                   | List of public Elastic IP addresses allocated to the NAT Instances. |
| <a name="output_private_route_table_ids"></a> [private_route_table_ids](#output_private_route_table_ids)                   | A list of IDs of the private route tables.                          |
| <a name="output_private_subnet_ids"></a> [private_subnet_ids](#output_private_subnet_ids)                                  | A list of IDs of the private subnets.                               |
| <a name="output_public_route_table_id"></a> [public_route_table_id](#output_public_route_table_id)                         | The ID of the public route table.                                   |
| <a name="output_public_subnet_ids"></a> [public_subnet_ids](#output_public_subnet_ids)                                     | A list of IDs of the public subnets.                                |
| <a name="output_vpc_cidr_block"></a> [vpc_cidr_block](#output_vpc_cidr_block)                                              | The CIDR block of the VPC.                                          |
| <a name="output_vpc_default_security_group_id"></a> [vpc_default_security_group_id](#output_vpc_default_security_group_id) | The ID of the default security group for the VPC.                   |
| <a name="output_vpc_id"></a> [vpc_id](#output_vpc_id)                                                                      | The ID of the VPC.                                                  |

<!-- END_TF_DOCS -->
