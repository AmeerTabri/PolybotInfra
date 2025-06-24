resource "aws_instance" "control-plane" {
  ami                         = var.ami_id
  instance_type               = "t2.medium"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.control_plane_sg.id]
  associate_public_ip_address = true

  key_name = "AmeerKeyPair"

  tags = {
    Name      = "ameer-control-plane"
    Terraform = "true"
  }
}

resource "aws_security_group" "control_plane_sg" {
  name        = "ameer-control-plane-sg"
  description = "Allow SSH and Kubernetes API"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
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
