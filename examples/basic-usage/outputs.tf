output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc_bastion_example.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc_bastion_example.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc_bastion_example.private_subnet_ids
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = module.vpc_bastion_example.bastion_host_public_ip
}

output "nat_gateway_ips" {
  description = "Public IPs of the NAT Gateways"
  value       = module.vpc_bastion_example.nat_gateway_public_ips
}