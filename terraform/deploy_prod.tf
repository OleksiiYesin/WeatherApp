
provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}
data "aws_ami" "ubuntu_latest" {
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

#-----------------------------------------------------------------

resource "aws_security_group" "prod" {
  name        = "SG-production"
  description = "inbound traffic"

  ingress {
    from_port   = 8000
    to_port     = 8000
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

resource "aws_launch_configuration" "prod" {
  name_prefix     = "ProdServer-lc"
  image_id        = data.aws_ami.ubuntu_latest.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.prod.id]
  user_data       = file("docker.sh")

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "prod" {
  name                 = "ASG---${aws_launch_configuration.prod.name}"
  launch_configuration = aws_launch_configuration.prod.name
  min_size             = 2
  max_size             = 2
  min_elb_capacity     = 2
  health_check_type    = "ELB"
  vpc_zone_identifier  = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  load_balancers       = [aws_elb.prod.name]

  dynamic "tag" {
    for_each = {
      Name   = "ProdServer in asg"
      Owner  = "Oleksii Yesin"
      TAGKEY = "TAGVALUE"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "prod" {
  name               = "ProdServer-elb"
  availability_zones = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  security_groups    = [aws_security_group.prod.id]

  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 8000
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 10
  }

  tags = {
    Name = "ProdServer-ELB"
  }
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = data.aws_availability_zones.available.names[1]
}
