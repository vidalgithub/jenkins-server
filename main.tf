
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
    data.aws_security_group.instance_sg.id
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
  ami           = data.aws_ami.custom_ami.id  # Replace with your desired AMI ID. Make sure you package the software of your choice (eg. jenkins and dependencies) in the image.
  instance_type = var.instance_type  # Replace with your desired instance type
  subnet_id     = data.aws_subnet.subnet1.id 
  key_name      = var.keypair
  security_groups = [
    data.aws_security_group.instance_sg.id
  ]
  
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

