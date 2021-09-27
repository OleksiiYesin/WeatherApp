provider "aws" {
  region = "us-west-2"
}

resource "aws_eip" "static_ip" {
  instance = aws_instance.prod.id
}

resource "aws_instance" "prod" {
  ami                    = "ami-03d5c68bab01f3496" # Ubuntu_20.04
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.prod.id]
  user_data              = file("docker.sh")

  tags = {
    Name = "production"
  }
  
  lifecycle {
     create_before_destroy = true
  }
}


resource "aws_security_group" "prod" {
  name        = "web_security_group"
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

output "prod_public_ip" {
  value = aws_eip.static_ip.public_ip
}
