variable "aws_region" {
  type = string
  default = "us-east-1"    # Replace with your desired AWS region
}

variable "domain_name" {
  type = string
  default = "beitcloud.com"  # Replace with your existing domain name
}

variable "subdomain" {
  type = string
  default = "jenkins"    # Replace with the subdomain name you want to create
}

variable "port" {
  type = number
  default = 8080
}

variable "keypair" {
  type = string
  default = "jenkins"  
}


variable "lb_sg_name" {
  type = string
  default = "jenkins-server"  # Replace with the name of an existing  security-group you want to assign to your loadbalancer
}

variable "instance_sg_name" {
  type = string
  default = "jenkins-server"  # Replace with the name of an existing  security-group you want to assign to your ec2-instance
}


variable "instance_type" {
  type = string
  default = "t2.micro"
}



/* variable "common_tags" {
  type = map(any)
} */
