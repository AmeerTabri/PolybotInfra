resource "aws_iam_role" "control_plane_role" {
  name = "ameer-control-plane-role"
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

resource "aws_iam_role_policy" "control_plane_policy" {
  name = "ameer-control-plane-policy"
  role = aws_iam_role.control_plane_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["ssm:PutParameter"],
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "control_plane_profile" {
  name = "ameer-control-plane-profile"
  role = aws_iam_role.control_plane_role.name
}

resource "aws_instance" "control-plane" {
  ami                         = var.ami_id
  instance_type               = "t2.medium"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.control_plane_sg.id]
  associate_public_ip_address = true
  key_name                    = "AmeerKeyPair"
  user_data                   = file("${path.module}/user_data_control_plane.sh")
  iam_instance_profile        = aws_iam_instance_profile.control_plane_profile.name

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
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.control_plane_sg.id]
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
      Action = ["ssm:GetParameter"],
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "worker_profile" {
  name = "ameer-worker-instance-profile"
  role = aws_iam_role.worker_role.name
}

resource "aws_launch_template" "worker_lt" {
  name           = "ameer-template"
  image_id       = var.worker_ami_id
  instance_type  = var.worker_instance_type
  key_name       = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.worker_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.worker_sg.id]
  }

  user_data = base64encode(templatefile("${path.module}/user_data_worker.sh.tpl", {
    region      = var.region,
    secret_name = var.join_command_secret_name
  }))
}

resource "aws_autoscaling_group" "worker_asg" {
  name                = "ameer-worker-asg"
  desired_capacity    = 0
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

resource "aws_sns_topic" "asg_notifications" {
  name = "asg-worker-launch-topic"
}

resource "aws_iam_role" "asg_lifecycle_role" {
  name = "ameer-asg-lifecycle-sns-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "autoscaling.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy_attachment" "asg_lifecycle_policy" {
  name       = "asg-lifecycle-sns-policy"
  roles      = [aws_iam_role.asg_lifecycle_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AutoScalingNotificationAccessRole"
}

resource "aws_autoscaling_lifecycle_hook" "worker_launch_hook" {
  name                    = "worker-launch-hook"
  autoscaling_group_name = aws_autoscaling_group.worker_asg.name
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_LAUNCHING"
  notification_target_arn = aws_sns_topic.asg_notifications.arn
  role_arn                = aws_iam_role.asg_lifecycle_role.arn
  heartbeat_timeout       = 30
  default_result          = "CONTINUE"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.asg_notifications.arn
  protocol  = "email"
  endpoint  = "ameer.t.2000@gmail.com"
}

resource "aws_iam_role" "lambda_log_role" {
  name = "ameer-sns-lambda-log-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_log_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "sns_log" {
  function_name = "ameer-sns-log-function"
  role          = aws_iam_role.lambda_log_role.arn
  handler       = "sns_log_lambda.lambda_handler"
  runtime       = "python3.11"
  filename      = "function.zip"
  source_code_hash = filebase64sha256("function.zip")
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sns_log.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.asg_notifications.arn
}

resource "aws_sns_topic_subscription" "lambda_sub" {
  topic_arn = aws_sns_topic.asg_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.sns_log.arn
}
