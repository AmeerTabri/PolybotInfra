resource "aws_instance" "control-plane" {
  ami                         = var.ami_id
  instance_type               = "t2.medium"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.control_plane_sg.id]
  associate_public_ip_address = true
  key_name                    = "AmeerKeyPair"
  user_data                   = file("${path.module}/user_data_control_plane.sh")

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

# -------------------------------
# Worker Node Resources (ASG)
# -------------------------------

resource "aws_security_group" "worker_sg" {
  name   = "ameer-worker-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port         = 0
    to_port           = 65535
    protocol          = "tcp"
    security_groups   = [aws_security_group.control_plane_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "worker_role" {
  name = "ameer-worker-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "worker_policy" {
  name = "ameer-worker-policy"
  role = aws_iam_role.worker_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "ssm:GetParameter"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "worker_profile" {
  name = "ameer-worker-instance-profile"
  role = aws_iam_role.worker_role.name
}

resource "aws_launch_template" "worker_lt" {
  name         = "ameer-template"
  image_id     = var.worker_ami_id
  instance_type = var.worker_instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.worker_profile.name
  }

  key_name = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.worker_sg.id]
  }

  user_data = base64encode(
    templatefile("${path.module}/user_data_worker.sh.tpl", {
      region      = var.region,
      secret_name = var.join_command_secret_name
    })
  )
}

resource "aws_autoscaling_group" "worker_asg" {
  name                = "ameer-worker-asg"
  desired_capacity    = 1
  max_size            = 3
  min_size            = 0
  vpc_zone_identifier = var.public_subnets

  launch_template {
    id      = aws_launch_template.worker_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ameer-worker-node"
    propagate_at_launch = true
  }
}
