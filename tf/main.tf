terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.55"
    }
  }

  required_version = ">= 1.7.0"

  backend "s3" {
    bucket = "ameer-tf-state"    # ✅ your S3 bucket
    key    = "terraform.tfstate" # ✅ state file name
    region = "us-west-2"         # ✅ backend region (must be static)
  }
}

provider "aws" {
  region  = var.region
  profile = "default"
}

resource "aws_instance" "polybot_app" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  subnet_id                   = module.polybot_service_vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.polybot_app_sg.id]
  associate_public_ip_address = true

  key_name = "AmeerKeyPair"  # ✅ Directly use the existing key name

  tags = {
    Name      = "ameer-control-plane"
    Terraform = "true"
  }
}

module "polybot_service_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "AmeerVPC"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.0.4.0/24", "10.0.5.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = false

  tags = {
    Env = var.env
  }
}

resource "aws_security_group" "polybot_app_sg" {
  name        = "ameer-tf-group"   # ✅ use your name
  description = "Allow SSH and HTTP traffic"
  vpc_id      = module.polybot_service_vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # allow SSH from anywhere (or limit to your IP)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # allow HTTP from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]   # allow all outbound traffic
  }
}
