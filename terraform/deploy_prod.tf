
provider "aws" {
  region = var.aws_region
}

######################################################################
############ Create elastic ip for our production server #############
######################################################################

resource "aws_eip" "static_ip" {
  instance = aws_instance.prod.id
}

######################################################################
######################## Create EC2 instance  ########################
######################################################################

resource "aws_instance" "prod" {
  ami                    = var.ami_id #### Ubuntu_20.04 #####
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.prod.id]
  user_data              = file("docker.sh")

  tags = {
    Name = "PRODUCTION"
  }

  lifecycle {
    create_before_destroy = true ### This means create new server before destroy old server
  }
}

######################################################################
##############  Security group for our production server #############
######################################################################

resource "aws_security_group" "prod" {
  name        = "SG-prod.server"
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
