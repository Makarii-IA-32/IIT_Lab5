variable "aws_region" {
  type = string
  default = "eu-north-1"
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "key_name" {
  type = string
}

variable "docker_images" {
  type = map(string)
  default = {
    redis = "redis:alpine"
    web-app = "makariikpi/flask-app:latest"
    watchtower = "containrrr/watchtower"
  }
}