
# Create a record set for the subdomain jenkins.
resource "aws_route53_record" "subdomain" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = "${var.subdomain}" 
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.load_balancer.dns_name]
}

# Create Application Load Balancer (ALB)
resource "aws_lb" "load_balancer" {
  name               = "jenkins-alb"
  load_balancer_type = "application"
  security_groups    = [
    aws_security_group.jenkins-docker.id
  ]
 
  subnets = [
      data.aws_subnet.subnet1.id,
      data.aws_subnet.subnet2.id,
    ]

  tags = {
    Name = "jenkins-alb"  # can be customized
  }
}

# Create ALB listener for http request
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Create ALB listener for https request and terminate the ssl
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = data.aws_acm_certificate.example_certificate.arn

  default_action {
    type            = "forward"
    target_group_arn = aws_lb_target_group.jenkins.arn
  }

  
}

# Create ALB target group
resource "aws_lb_target_group" "jenkins" {
  name     = "jenkins-target-group"
  port     = var.port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.vpc.id 
}

# Create EC2 instance
resource "aws_instance" "jenkins_instance" {
  ami           = data.aws_ami.ubuntu.id  # Replace with your desired AMI ID. Make sure you package the software of your choice (eg. jenkins and dependencies) in the image.
  instance_type = var.instance_type  # Replace with your desired instance type
  subnet_id     = data.aws_subnet.subnet1.id 
  key_name      = var.keypair
  security_groups = [
    aws_security_group.jenkins-docker.id
  ]

    user_data = <<-EOF
#!/bin/bash

# This script will install Java and Jenkins
echo "Checking the operating system"
OS=$(cat /etc/os-release | grep PRETTY_NAME | awk -F= '{print $2}' | awk -F '"' '{print $2}' | awk '{print $1}')

echo 'Checking if Jenkins is installed'
ls /var/lib | grep jenkins
if [[ $? -eq 0 ]]; then 
    echo "Jenkins is installed"
    exit 1
else
    sudo apt update
    sudo apt install ca-certificates -y
    sudo apt update
    sudo apt install fontconfig openjdk-17-jre -y
    java -version
    sudo ufw allow 8080/tcp 2> /dev/null
    sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update
    sudo apt-get install jenkins -y
    sudo systemctl start jenkins 
    sudo systemctl enable jenkins
    touch /tmp/password
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword > /tmp/password
    echo "Jenkins password is: $(cat /tmp/password)"
fi

# Uninstall any previous Docker engine
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Install Docker engine using apt repository
# Set up Docker's apt repository.
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install curl -y
sudo install -m 0755 -d /etc/apt/keyrings -y
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install the Docker packages.
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Verify that the Docker Engine installation is successful by running the hello-world image.
sudo docker run hello-world
if [[ $? -eq 0 ]]; then 
    echo "Succesfully installed Docker"
    exit 0
else
    echo "Fail to install Docker"
fi
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins


  EOF

  tags = {
    Name = "jenkins-instance"   # can be customized
  }
}

# Create ALB target group attachment
resource "aws_lb_target_group_attachment" "jenkins_instance_attachment" {
  target_group_arn = aws_lb_target_group.jenkins.arn
  target_id        = aws_instance.jenkins_instance.id
  port             = var.port
}

# Create ALB listener rule
resource "aws_lb_listener_rule" "jenkins" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins.arn
  }

  condition {
    host_header {
      values = ["${var.subdomain}.${var.domain_name}"]
    }
  }
}

resource "aws_security_group" "jenkins-docker" {
  name        = "jenkins-docker"
  description = "Allow inbound traffic to specific ports and outbound to all destinations"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
