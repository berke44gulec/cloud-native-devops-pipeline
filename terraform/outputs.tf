output "instance_public_ip" {
  description = "Public IP address"
  value       = aws_eip.devops.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name"
  value       = aws_instance.devops.public_dns
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh -i ~/.ssh/devops-pipeline ubuntu@${aws_eip.devops.public_ip}"
}

output "app_url" {
  description = "Application URL"
  value       = "http://${aws_eip.devops.public_ip}:3000"
}

output "s3_bucket_name" {
  description = "S3 Backup Bucket"
  value       = aws_s3_bucket.backups.bucket
}
