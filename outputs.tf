output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC."
  value       = aws_vpc.main.cidr_block
}

output "vpc_default_security_group_id" {
  description = "The ID of the default security group for the VPC."
  value       = aws_vpc.main.default_security_group_id
}

output "public_subnet_ids" {
  description = "A list of IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "A list of IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

output "public_route_table_id" {
  description = "The ID of the public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "A list of IDs of the private route tables."
  value       = aws_route_table.private[*].id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway."
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_public_ips" {
  description = "List of public Elastic IP addresses allocated to the NAT Gateways."
  value       = var.enable_nat_gateway ? aws_eip.nat_gateway[*].public_ip : []
}

output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways."
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[*].id : []
}

output "nat_instance_public_ips" {
  description = "List of public Elastic IP addresses allocated to the NAT Instances."
  value       = local.nat_instance_enabled ? aws_eip.nat_instance[*].public_ip : []
}

output "nat_instance_ids" {
  description = "List of IDs of the NAT Instances."
  value       = local.nat_instance_enabled ? aws_instance.nat[*].id : []
}

output "bastion_host_id" {
  description = "The ID of the Bastion Host instance (if created)."
  value       = var.enable_bastion_host ? aws_instance.bastion[0].id : null
}

output "bastion_host_public_ip" {
  description = "The public IP address of the Bastion Host (if created and has one)."
  value       = var.enable_bastion_host && var.associate_public_ip_address_bastion ? aws_instance.bastion[0].public_ip : null
}

output "bastion_host_private_ip" {
  description = "The private IP address of the Bastion Host (if created)."
  value       = var.enable_bastion_host ? aws_instance.bastion[0].private_ip : null
}

output "bastion_security_group_id" {
  description = "The ID of the Bastion Host's security group (if created)."
  value       = var.enable_bastion_host ? aws_security_group.bastion[0].id : null
}