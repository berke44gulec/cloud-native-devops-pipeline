terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Cloud-Native-DevOps"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_caller_identity" "current" {}

resource "aws_key_pair" "devops" {
  key_name   = "devops-pipeline-key"
  public_key = file(var.public_key_path)
  
  tags = {
    Name = "DevOps Pipeline Key"
  }
}

resource "aws_security_group" "devops_sg" {
  name        = "devops-pipeline-sg"
  description = "Security group for DevOps pipeline"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_ips
    description = "SSH"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "App"
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_ips
    description = "Prometheus"
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_ips
    description = "Node Exporter"
  }

  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Grafana"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DevOps Pipeline SG"
  }
}

resource "aws_instance" "devops" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.devops.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]
  
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = file("${path.module}/scripts/user-data.sh")

  tags = {
    Name = "DevOps-Pipeline-Server"
  }
}

resource "aws_eip" "devops" {
  instance = aws_instance.devops.id
  domain   = "vpc"

  tags = {
    Name = "DevOps Pipeline EIP"
  }
}

resource "aws_s3_bucket" "backups" {
  bucket = "${var.project_name}-backups-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "DevOps Pipeline Backups"
  }
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/devops-pipeline"
  retention_in_days = 7

  tags = {
    Name = "DevOps Pipeline Logs"
  }
}

resource "aws_budgets_budget" "monthly" {
  name              = "devops-pipeline-monthly"
  budget_type       = "COST"
  limit_amount      = "10"
  limit_unit        = "USD"
  time_period_start = "2025-01-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
}
