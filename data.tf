# get details about a route 53 hosted zone
data "aws_route53_zone" "route53_zone" {
  name = var.domain_name
  # This can be true or false
  private_zone = false
}

# Use this data source to get the ARN of a certificate in AWS Certificate Manager (ACM)
data "aws_acm_certificate" "example_certificate" {
  domain       = var.domain_name 
  most_recent  = true
}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name] # ["default"]  # Your vpc name
  }
}

data "aws_subnet" "subnet1" {   
  filter {
    name   = "tag:Name"
    values = [var.subnet1_name] # ["default-1"]  # Your 1st public subnet name 
  }
}

data "aws_subnet" "subnet2" {
  filter {
    name   = "tag:Name"
    values = [var.subnet2_name] # ["default-2"]   # Your 2nd public subnet name
  }
}

# # Data block to fetch security group ID
# data "aws_security_group" "lb_sg" {
#   name = var.lb_sg_name
# }

# # Data block to fetch security group ID
# data "aws_security_group" "instance_sg" {
#   name = var.instance_sg_name
# }

# # Output the security group ID  - OPTIONAL
# output "security_group_id" {
#   value = data.aws_security_group.lb_sg.id
# }

# # Data block to fetch a custom AMI ID in your account
# data "aws_ami" "custom_ami" {
#   most_recent = true
#   owners      = ["self"]
#   filter {
#     name   = "tag:Name"
#     values = ["my-bastion-host-jenkins"]   # The name of your custom ami
#   }
# }

# Data block to fetch a custom UBUNTU AMI ID in your account
data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# # Output the custom AMI ID - OPTIONAL
# output "custom_ami_id" {
#   value = data.aws_ami.custom_ami.id
# }

