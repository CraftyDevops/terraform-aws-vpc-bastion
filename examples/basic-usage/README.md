# Basic VPC with NAT Gateway and Bastion Host Example

This directory contains a basic example of how to use the `terraform-aws-vpc-bastion` module to create a common networking setup on AWS.

## Overview

This example will provision the following infrastructure:

*   A new **VPC** with a specified CIDR block.
*   **Public and Private Subnets** distributed across two Availability Zones.
*   An **Internet Gateway** attached to the VPC.
*   A **single NAT Gateway** (for cost-effectiveness in this example) deployed in one of the public subnets to allow outbound internet access for instances in private subnets.
*   Route tables configured accordingly:
    *   Public subnets route `0.0.0.0/0` to the Internet Gateway.
    *   Private subnets route `0.0.0.0/0` to the NAT Gateway.
*   An **EC2 Bastion Host** deployed in a public subnet to provide secure SSH access to resources in private subnets.
*   Associated **Security Groups** for the Bastion Host.

This setup is suitable for development, testing, or small production environments where a single NAT Gateway is acceptable. For higher availability in production, you would typically set `single_nat_gateway = false` in the module call to deploy a NAT Gateway in each Availability Zone.

## Prerequisites

1.  **Terraform Installed:** Ensure you have Terraform v1.0 or newer installed.
2.  **AWS Account and Credentials:** You need an AWS account and your AWS credentials configured for Terraform to use (e.g., via AWS CLI configuration, environment variables, or an IAM role).
3.  **EC2 Key Pair:** You must have an existing EC2 Key Pair in the AWS region you intend to deploy this example to. You will need to provide its name for the `bastion_ssh_key_name` variable.
4.  **Your Public IP Address:** To securely access the Bastion Host, you should know your current public IP address to restrict SSH access.

## How to Use This Example

1. **Customize Variables:**
    Open the `main.tf` file in this directory (`examples/basic-usage/main.tf`).
    You **MUST** update the following placeholder values in the `module "vpc_bastion_example"` block:
    *   `bastion_ssh_key_name`: Change `"your-ec2-key-pair-name"` to the name of your existing EC2 Key Pair.
    *   `bastion_ingress_cidr_blocks`: Change `["YOUR_PUBLIC_IP/32"]` to a list containing your actual public IP address followed by `/32` (e.g., `["1.2.3.4/32"]`).

    You might also want to adjust:
    *   `aws_region` in `variables.tf` (or in the `provider` block in `main.tf`) to your preferred AWS region.
    *   `azs` in `main.tf` to use Availability Zones available and suitable for your chosen region.
    *   Other variables like `name_prefix`, `vpc_cidr_block`, etc., as needed.

2. **Initialize Terraform:**
    Run the following command in the `examples/basic-usage` directory:
    ```bash
    terraform init
    ```
    This will download the necessary AWS provider plugins and initialize the module.

3. **Review the Plan:**
    Run the following command to see what resources Terraform will create:
    ```bash
    terraform plan
    ```
    Carefully review the output.

4. **Apply the Configuration:**
    If the plan looks good, apply the configuration:
    ```bash
    terraform apply
    ```
    Terraform will ask for confirmation before proceeding. Type `yes` and press Enter.

5. **Accessing the Bastion Host:**
    After the `apply` is complete, Terraform will output the public IP address of the Bastion Host (if `enable_bastion_host` was true). You can SSH into it using:
    ```bash
    ssh -i /path/to/your/private-key.pem ec2-user@<BASTION_PUBLIC_IP>
    ```
    Replace `/path/to/your/private-key.pem` with the path to the private key file corresponding to `bastion_ssh_key_name`, and `<BASTION_PUBLIC_IP>` with the actual public IP.

6. **Cleaning Up:**
    When you are finished with this example and want to remove all created resources, run:
    ```bash
    terraform destroy
    ```
    Terraform will ask for confirmation. Type `yes` and press Enter.

## Main Files in This Example

*   `main.tf`: Contains the module block calling the root VPC module and provider configuration. **This is the primary file you'll modify for this example.**
*   `variables.tf`: Defines variables specific to this example, like the AWS region.
*   `outputs.tf`: Defines what outputs from the root module should be displayed after a successful `terraform apply`.
*   `README.md`: This file.

This example serves as a starting point. You can adapt it further to explore different configurations of the main VPC module.