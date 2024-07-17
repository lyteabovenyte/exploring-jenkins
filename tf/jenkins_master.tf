resource "aws_instance" "jenkins_master" {
  ami                    = data.aws_ami.jenkins-master.id
  instance_type          = var.jenkins_master_instance_type
  key_name               = aws_key_pair.management.id
  vpc_security_group_ids = [aws_security_group.jenkins-master_sg.id]
  subnet_id              = element(aws_subnet.private_subnets, 0)

  # the instance is backed by an EBS volume (SSD)
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = false
  }

  tags = {
    Name   = "jenkins_master"
    Author = var.author
  }
}

data "aws_ami" "jenkins-master" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["jenkins-master-*"]
  }
}

resource "aws_security_group" "jenkins_master_sg" {
  name        = "jenkins_master_sg"
  description = "Allow traffic on port 8080 and enable SSH"
  vpc_id      = aws_vpc.management.id

  # enabling SSH into jenkins-master instance in the private subnet
  ingress {
    from_port       = "22"
    to_port         = "22"
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_host.id]
  }

  # enabling connection on port 8080 into jenkins master for the jenkins web console
  # only allow traffic on port 8080 from the load balancer sucurity_group ID
  ingress {
    from_port   = "8080"
    to_port     = "8080"
    protocol    = "tcp"
    cidr_blocks = [aws_security_group.elb_jenkins_sg.id]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name   = "jenkins_master_sg"
    Author = var.author
  }
}

resource "aws_elb" "jenkins_elb" {
  subnets                   = [for subnet in aws_subnet.public_subnets : subnet.id]
  cross_zone_load_balancing = true
  security_groups           = [aws_security_group.elb_jenkins_sg.id]
  instances                 = [aws_instance.jenkins_master.id]

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  # enabling SSL on port 443 with generated ACM
  listener {
    instance_port      = 8080
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = var.ssl_arn
  }

  # health check on the target instance on port 8080
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:8080"
    interval            = 5
  }

  tags = {
    Name   = "jenkins_elb"
    Author = var.author
  }
}

resource "aws_security_group" "elb_jenkins_sg" {
  name        = "elb_jenkins_sg"
  description = "Allow http traffic"
  vpc_id      = aws_vpc.management.id

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = "443"
    to_port = "443"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name   = "elb_jenkins_sg"
    Author = var.author
  }
}

# creating an A record in Route53 pointing to the load balancer's FQDN
resource "aws_route53_record" "jenkins_master" {
  zone_id = var.hosted_zone_id
  name = "jenkins.${var.domain_name}" # route this domain, to the alias's name attribute dns_name
  type = "A"

  alias {
    name = aws_elb.jenkins_elb.dns_name
    zone_id = aws_elb.jenkins_elb.zone_id
    evaluate_target_health = true
  }
}
