variable "worker_ami_id" {
  description = "AMI ID for worker nodes"
  type        = string
}

variable "worker_instance_type" {
  description = "EC2 instance type for worker nodes"
  default     = "t3.micro"
}

variable "public_subnets" {
  description = "List of public subnets for worker ASG"
  type        = list(string)
}

variable "key_name" {
  description = "SSH key name"
  type        = string
}

variable "join_command_secret_name" {
  description = "Secrets Manager secret containing kubeadm join command"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for control plane"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for control plane"
  type        = string
}
