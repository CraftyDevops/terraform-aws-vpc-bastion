variable "name_prefix" {
  description = "A prefix to be added to the names of all created resources."
  type        = string
  default     = "tf-vpc-bastion"
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_enable_dns_support" {
  description = "Enable DNS support in the VPC."
  type        = bool
  default     = true
}

variable "vpc_enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC."
  type        = bool
  default     = true
}

variable "azs" {
  description = "A list of Availability Zones to use for subnets."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "A list of CIDR blocks for public subnets. Must match the number of AZs."
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "A list of CIDR blocks for private subnets. Must match the number of AZs."
  type        = list(string)
  default     = []
}

variable "subnet_map_public_ip_on_launch" {
  description = "Specify true to indicate that instances launched into the public subnet receive a public IP address."
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Set to true to create a NAT Gateway for outbound internet access from private subnets."
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Set to true to create a single NAT Gateway. If false, a NAT Gateway will be created in each AZ with a private subnet."
  type        = bool
  default     = true
}

variable "enable_nat_instance" {
  description = "Set to true to create a NAT Instance. Ignored if enable_nat_gateway is true."
  type        = bool
  default     = false
}

variable "nat_instance_type" {
  description = "The instance type to use for the NAT instance."
  type        = string
  default     = "t3.micro"
}

variable "nat_instance_ami_id" {
  description = "The AMI ID for the NAT instance. If null, latest Amazon Linux 2 will be used. Ensure it's configured for NAT."
  type        = string
  default     = null
}

variable "nat_instance_key_name" {
  description = "The EC2 Key Pair name for the NAT instance (for SSH access if needed)."
  type        = string
  default     = null
}

variable "enable_bastion_host" {
  description = "Set to true to create a Bastion Host in a public subnet."
  type        = bool
  default     = false
}

variable "bastion_instance_type" {
  description = "The instance type to use for the Bastion Host."
  type        = string
  default     = "t2.micro"
}

variable "bastion_ami_id" {
  description = "The AMI ID for the Bastion Host. If null, latest Amazon Linux 2 will be used."
  type        = string
  default     = null
}

variable "bastion_ssh_key_name" {
  description = "The EC2 Key Pair name for the Bastion Host (required if enable_bastion_host is true)."
  type        = string
  default     = null

}

variable "bastion_ingress_cidr_blocks" {
  description = "A list of CIDR blocks allowed to SSH into the Bastion Host."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "bastion_user_data" {
  description = "User data script to run on the Bastion Host at launch."
  type        = string
  default     = null
}

variable "associate_public_ip_address_bastion" {
  description = "Associate a public IP address with the bastion host. Set to false if using an Elastic IP."
  type        = bool
  default     = true
}