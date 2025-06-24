variable "ami_id" {
  description = "AMI ID for EC2"
  type        = string
}

variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the control plane EC2"
  type        = string
}
