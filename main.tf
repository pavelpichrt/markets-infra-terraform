provider "aws" {
  profile = "default"
  region  = var.region
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_subnet_ids" "default" {
  vpc_id = aws_default_vpc.default.id
}

resource "aws_key_pair" "terraform_key" {
  key_name   = "terraform_key"
  public_key = file(var.pub_key_file)
}

resource "aws_ecr_repository" "node_alpine_build_img" {
  name                 = "node-alpine-build-img"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_cluster" "markets_app" {
  name = "markets-app"
}

resource "aws_s3_bucket" "markets_data" {
  bucket = "markets-data-base"
  acl    = "private"
}

resource "aws_s3_bucket" "markets_logs" {
  bucket = "markets-logs-all"
  acl    = "private"
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "postgres_ip_public" {
  value = aws_eip.pg_instance.public_ip
}
output "postgres_ip_private" {
  value = aws_eip.pg_instance.private_ip
}

output "ECR_URL_node_alpine_build" {
  value = aws_ecr_repository.node_alpine_build_img.repository_url
}
