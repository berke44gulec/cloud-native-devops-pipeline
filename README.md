# Cloud-Native DevOps Pipeline

Automated deployment pipeline with AWS, Terraform, Docker, Prometheus, and Grafana.

## Overview

This project implements a complete DevOps pipeline with hybrid CI/CD approach, combining cloud-native tools with traditional configuration management for production-grade deployment automation.

## Key Features

- Infrastructure as Code with Terraform
- Containerized application deployment
- Hybrid CI/CD (GitHub Actions + Ansible)
- Comprehensive monitoring with Prometheus and Grafana
- Cost optimization (~$2/month)
- Automated backup and recovery

## Architecture

```
Developer → Git Push → GitHub Actions (CI)
                            ↓
                    Build & Test & Push
                            ↓
                       Docker Hub
                            
Local Machine → Ansible (CD) → EC2
                                ↓
                    Docker + Prometheus + Grafana
                                ↓
                    S3 Backup + CloudWatch Logs
```

## Technology Stack

**Infrastructure**
- Terraform (AWS EC2, VPC, Security Groups, S3, CloudWatch)
- Ansible (Configuration management and deployment automation)

**Application**
- Node.js Express with Prometheus metrics
- Docker containerization
- Docker Hub registry

**CI/CD**
- GitHub Actions (Continuous Integration)
- Ansible (Continuous Deployment)

**Monitoring**
- Prometheus (Metrics collection)
- Grafana (Visualization with 3 dashboards)
- Node Exporter (System metrics)
- AWS CloudWatch (Logs)

**Cloud**
- AWS EC2 (t3.micro)
- AWS S3 (Backup storage)
- AWS CloudWatch (Log aggregation)
- AWS Budgets (Cost tracking)

## CI/CD Pipeline

### Hybrid Approach

This project uses a **hybrid CI/CD approach** combining the best of both worlds:

**GitHub Actions (CI)**
- Automated build on every push
- Docker image creation
- Image push to Docker Hub
- Automated testing

**Ansible (CD)**
- Automated deployment to EC2
- Configuration management
- Idempotent operations
- Versioned playbooks

This separation provides:
- Better security (no SSH keys in GitHub)
- Flexibility in deployment targets
- Version-controlled deployment scripts
- Industry-standard practices

## Prerequisites

```
Terraform >= 1.0
Ansible >= 2.9
Docker >= 20.10
AWS CLI >= 2.0
Node.js >= 18
AWS Free Tier account
```

## Installation

### 1. Clone Repository

```bash
git clone https://github.com/berke44gulec/cloud-native-devops-pipeline.git
cd cloud-native-devops-pipeline
```

### 2. Configure AWS

```bash
aws configure
```

### 3. Generate SSH Key

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/devops-pipeline
chmod 600 ~/.ssh/devops-pipeline
```

### 4. Deploy Infrastructure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Update values

terraform init
terraform plan
terraform apply
```

### 5. Build and Push Docker Image

```bash
docker build -t YOUR_USERNAME/cloud-native-devops:latest .
docker login
docker push YOUR_USERNAME/cloud-native-devops:latest
```

### 6. Configure Ansible Inventory

```bash
nano ansible/inventory/hosts
# Update EC2 IP address and Docker image name
```

### 7. Deploy Application with Ansible

```bash
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/deploy.yml
```

## GitHub Actions Setup

### Required Secrets

Configure these secrets in GitHub repository settings:

- `DOCKER_USERNAME`: Docker Hub username
- `DOCKER_PASSWORD`: Docker Hub password or access token

### Workflow

The CI pipeline automatically:
1. Runs tests on every push
2. Builds Docker image on main branch
3. Pushes to Docker Hub with version tags
4. Provides deployment instructions

## Deployment Workflow

### Automated CI (GitHub Actions)

```bash
git add .
git commit -m "feat: New feature"
git push origin main
# GitHub Actions automatically builds and pushes Docker image
```

### Automated CD (Ansible)

```bash
# Deploy to EC2
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/deploy.yml

# Setup monitoring
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/setup-monitoring.yml

# Run backup
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/backup.yml
```

## Access

After deployment:

```
Application:  http://EC2_IP:3000
Prometheus:   http://EC2_IP:9090
Grafana:      http://EC2_IP:3001 (admin/password)
```

## Dashboards

### System Metrics Dashboard
- CPU Usage
- Memory Usage
- Disk Usage
- Network Traffic
- System Load Average
- Disk I/O

### Application Metrics Dashboard
- HTTP Request Rate
- Average Response Time
- Response Time p95
- Total Requests
- Requests by Status Code
- Process Memory Usage

### Overview Dashboard
- System Health Gauges
- Application Statistics
- Trend Graphs

## Cost Analysis

```
EC2 (t3.micro):    $0.00 (Free Tier)
EBS (20GB):        $0.00 (Free Tier)
S3 (5GB):          $0.00 (Free Tier)
Data Transfer:     ~$0.50
CloudWatch:        $0.00 (Free Tier)
-------------------------------------------
Total:             ~$0.50-2.00/month
```

## Security

- Security Groups with IP whitelisting for SSH
- Encrypted EBS volumes
- S3 versioning enabled
- Non-root container user
- IAM least privilege policies
- SSH keys stored locally (not in GitHub)

## Project Structure

```
cloud-native-devops-pipeline/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── scripts/
├── ansible/
│   ├── inventory/
│   ├── playbooks/
│   │   ├── deploy.yml
│   │   ├── setup-monitoring.yml
│   │   └── backup.yml
│   └── roles/
│       ├── docker/
│       ├── prometheus/
│       └── app-deploy/
├── app/
│   ├── src/
│   │   └── server.js
│   └── package.json
├── monitoring/
│   ├── prometheus/
│   └── grafana/
├── .github/workflows/
│   └── deploy.yml
├── Dockerfile
└── README.md
```

## Testing

```bash
# Health check
curl http://EC2_IP:3000/health

# Metrics endpoint
curl http://EC2_IP:3000/metrics

# Load test
for i in {1..100}; do curl http://EC2_IP:3000; done
```

## Troubleshooting

### Cannot connect to EC2

Check Security Group:

```bash
aws ec2 describe-security-groups --group-names devops-pipeline-sg
```

Check your current IP:

```bash
curl https://api.ipify.org
```

Update IP in terraform.tfvars and reapply.

### Container not running

Check logs:

```bash
docker logs app
```

Restart container:

```bash
docker restart app
```

### Prometheus targets down

Check service status:

```bash
sudo systemctl status prometheus
```

Restart service:

```bash
sudo systemctl restart prometheus
```

## Ansible Playbook Usage

```bash
# Deploy application
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/deploy.yml

# Setup monitoring stack
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/setup-monitoring.yml

# Run backup
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/backup.yml

# Dry run
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/deploy.yml --check

# Verbose output
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/deploy.yml -v
```

## Future Improvements

- Kubernetes migration (EKS)
- Auto-scaling implementation
- Blue-Green deployment
- Advanced alerting (PagerDuty/Slack)
- Security scanning (Trivy)
- Load testing (K6)
- Multi-region deployment
- Vault integration for secrets

## What I Learned

### Technical Skills
- Infrastructure as Code with Terraform
- Container orchestration with Docker
- Cloud platform management (AWS)
- Monitoring and observability (Prometheus, Grafana)
- Configuration management with Ansible
- CI/CD pipeline design (hybrid approach)
- Cost optimization strategies

### DevOps Practices
- Infrastructure versioning
- Immutable infrastructure
- Automated deployment workflows
- Security best practices
- Separation of concerns in CI/CD

## Note:
This project is for educational purposes.
