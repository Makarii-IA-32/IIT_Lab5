terraform {
    required_version = ">= 1.5.0"

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "default" {
    filter {
        name   = "vpc-id"
        values = [data.aws_vpc.default.id]
    }
}

data "aws_ami" "ubuntu" {
    most_recent = true
    owners = ["099720109477"]

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

resource "aws_security_group" "lab6_security" {
    name = "lab6-security-group"
    vpc_id = data.aws_vpc.default.id

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTP"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        description = "Allow from all"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "lab6_vm" {
    ami           = data.aws_ami.ubuntu.id
    instance_type = var.instance_type
    key_name = var.key_name
    subnet_id = data.aws_subnets.default.ids[0]
    vpc_security_group_ids = [aws_security_group.lab6_security.id]

    user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker

              sudo usermod -aG docker ubuntu || true

              docker network create web-net

              docker rm -f redis_db || true
              docker pull ${var.docker_images.redis}
              docker run -d --name redis_db --network web-net ${var.docker_images.redis}

              docker rm -f web_app || true
              docker pull ${var.docker_images.web-app}
              docker run -d --name web_app -p 80:5000 --network web-net ${var.docker_images.web-app}

              docker rm -f watchtower || true
              docker pull ${var.docker_images.watchtower}
              docker run -d --name watchtower -e DOCKER_API_VERSION=1.40 -v /var/run/docker.sock:/var/run/docker.sock \
                  ${var.docker_images.watchtower} --interval 300 web_app
              EOF

    tags = {
        Name = "Lab-6-Terraform-Instance"
    }
}