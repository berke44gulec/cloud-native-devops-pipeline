variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cloud-native-devops"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID (Ubuntu 22.04 LTS)"
  type        = string
  default     = "ami-0c7217cdde317cfec"
}

variable "public_key_path" {
  description = "Path to SSH public key"
  type        = string
}

variable "allowed_ssh_ips" {
  description = "List of IPs allowed to SSH"
  type        = list(string)
}

variable "alert_email" {
  description = "Email for budget alerts"
  type        = string
}
