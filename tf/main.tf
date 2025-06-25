terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.55"
    }
  }

  required_version = ">= 1.7.0"

  backend "s3" {
    bucket = "ameer-tf-state"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region  = var.region
  profile = "default"
}

# ✅ VPC created at root
module "polybot_service_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "AmeerVPC2"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.0.4.0/24", "10.0.5.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = false
}

# ✅ Call k8s module and pass VPC + subnets + worker vars
module "k8s_cluster" {
  source = "./modules/k8s-cluster"

  ami_id   = var.ami_id
  vpc_id   = module.polybot_service_vpc.vpc_id
  subnet_id = module.polybot_service_vpc.public_subnets[0]

  # NEW: pass worker & region info for ASG
  worker_ami_id             = var.worker_ami_id
  worker_instance_type      = "t3.micro"          # or a variable
  key_name                  = var.key_name
  region                    = var.region
  join_command_secret_name  = "kubeadm-join-command"
  public_subnets            = module.polybot_service_vpc.public_subnets
}
