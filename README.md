# Cloud-Native DevOps Pipeline

Automated deployment pipeline with AWS, Terraform, Docker, Prometheus, and Grafana.

---

## Overview

This project implements a complete DevOps pipeline including infrastructure as code, containerized deployment, monitoring, and cost optimization.

## Architecture

    GitHub --> CI/CD --> EC2 (Docker + Monitoring) --> S3 Backup
                                                   --> CloudWatch Logs

## Technology Stack

* Terraform - Infrastructure as Code
* Ansible - Configuration Management
* Docker - Containerization
* AWS EC2 - Compute
* AWS S3 - Backup Storage
* Prometheus - Metrics Collection
* Grafana - Visualization
* Node.js - Application Runtime
* AWS CloudWatch - Log Management

## Features

* Automated infrastructure provisioning with Terraform
* Dockerized Node.js application
* Three monitoring dashboards
* Prometheus metrics endpoint
* Grafana visualization
* S3 backup with versioning
* Budget alerts and cost tracking
* Security group configuration

## Prerequisites

* Terraform >= 1.0
* Ansible >= 2.9
* Docker >= 20.10
* AWS CLI >= 2.0
* Node.js >= 18
* AWS Free Tier account

## Installation

### Clone Repository

    git clone https://github.com/berke44gulec/cloud-native-devops-pipeline.git
    cd cloud-native-devops-pipeline

### Configure AWS

    aws configure

Enter your AWS Access Key ID, Secret Access Key, region (us-east-1), and output format (json).

### Generate SSH Key

    ssh-keygen -t rsa -b 4096 -f ~/.ssh/devops-pipeline
    chmod 600 ~/.ssh/devops-pipeline

### Deploy Infrastructure

    cd terraform
    cp terraform.tfvars.example terraform.tfvars
    nano terraform.tfvars

Update the following values:
* alert_email
* allowed_ssh_ips

Then run:

    terraform init
    terraform plan
    terraform apply

### Build Docker Image

    docker build -t YOUR_USERNAME/cloud-native-devops:latest .
    docker login
    docker push YOUR_USERNAME/cloud-native-devops:latest

### Deploy Application

Get EC2 IP address:

    EC2_IP=$(cd terraform && terraform output -raw instance_public_ip)

Connect via SSH:

    ssh -i ~/.ssh/devops-pipeline ubuntu@$EC2_IP

Run container on EC2:

    docker pull YOUR_USERNAME/cloud-native-devops:latest
    docker run -d --name app --restart unless-stopped -p 3000:3000 YOUR_USERNAME/cloud-native-devops:latest

## Access

* Application: http://EC2_IP:3000
* Prometheus: http://EC2_IP:9090
* Grafana: http://EC2_IP:3001

Grafana credentials: admin / your_password

## Dashboards

### System Metrics Dashboard

* CPU Usage
* Memory Usage
* Disk Usage
* Network Traffic
* System Load Average
* Disk I/O

### Application Metrics Dashboard

* HTTP Request Rate
* Average Response Time
* Response Time p95
* Total Requests
* Requests by Status Code
* Process Memory Usage

### Overview Dashboard

* System Health Gauges
* Application Statistics
* Trend Graphs

## Cost Analysis

    EC2 (t3.micro):      $0.00 (Free Tier)
    EBS (20GB):          $0.00 (Free Tier)
    S3 (5GB):            $0.00 (Free Tier)
    Data Transfer:       ~$0.50
    CloudWatch:          $0.00 (Free Tier)
    -------------------------------------------
    Total:               ~$0.50-2.00/month

## Security

* Security Groups with IP whitelisting for SSH
* Encrypted EBS volumes
* S3 versioning enabled
* Non-root container user
* IAM least privilege policies

## Project Structure

    cloud-native-devops-pipeline/
    |-- terraform/
    |   |-- main.tf
    |   |-- variables.tf
    |   |-- outputs.tf
    |   `-- scripts/
    |-- ansible/
    |   |-- playbooks/
    |   `-- roles/
    |-- app/
    |   |-- src/
    |   |   `-- server.js
    |   `-- package.json
    |-- monitoring/
    |   |-- prometheus/
    |   `-- grafana/
    |-- Dockerfile
    `-- README.md

## Testing

Health check:

    curl http://EC2_IP:3000/health

Metrics endpoint:

    curl http://EC2_IP:3000/metrics

Load test:

    for i in {1..100}; do curl http://EC2_IP:3000; done

## Troubleshooting

### Cannot connect to EC2

Check Security Group:

    aws ec2 describe-security-groups --group-names devops-pipeline-sg

Check your current IP:

    curl https://api.ipify.org

Update IP in terraform.tfvars and reapply.

### Container not running

Check logs:

    docker logs app

Restart container:

    docker restart app

### Prometheus targets down

Check service status:

    sudo systemctl status prometheus

Restart service:

    sudo systemctl restart prometheus

## Future Improvements

* Kubernetes migration
* Auto-scaling implementation
* Blue-Green deployment
* Advanced alerting with PagerDuty or Slack
* Security scanning with Trivy
* Load testing with K6
* Multi-region deployment

## Author

Berke Güleç

GitHub: https://github.com/berke44gulec

Email: 02220201024@ogr.inonu.edu.tr

## License

This project is for educational purposes.

---

Last updated: 2025
