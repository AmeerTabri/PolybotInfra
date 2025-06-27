variable "ami_id" {
  description = "AMI ID for control plane"
  type        = string
}

variable "worker_ami_id" {
  description = "AMI ID for worker nodes"
  type        = string
}

variable "key_name" {
  description = "SSH key name for EC2 instances"
  type        = string
}

variable "region" {
  description = "AWS region"
  default     = "us-west-2"
}
