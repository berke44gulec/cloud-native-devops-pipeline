#!/bin/bash

cd ~/projects/cloud-native-devops-pipeline

echo "=== ADIM 1: Proje Yapısını Oluştur ==="

mkdir -p terraform/{modules/{ec2,security,s3},environments/{dev,prod},scripts}
mkdir -p ansible/{playbooks,roles/docker/tasks,roles/prometheus/tasks,inventory}
mkdir -p app/src
mkdir -p monitoring/{prometheus,grafana}
mkdir -p scripts
mkdir -p docs
mkdir -p .github/workflows

echo "✅ Dizin yapısı oluşturuldu"

echo ""
echo "=== ADIM 2: .gitignore Oluştur ==="

cat > .gitignore << 'EOF'
# Terraform
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
*.tfvars
!terraform.tfvars.example

# Ansible
*.retry
ansible/inventory/hosts

# AWS
.aws/
*.pem
*.key

# Environment
.env
*.log

# IDE
.vscode/
.idea/
*.swp

# OS
.DS_Store
EOF

git add .gitignore
git commit -m "Initial commit: project structure and gitignore"

echo "✅ .gitignore oluşturuldu"

echo ""
echo "=== ADIM 3: Node.js Uygulaması ==="

cat > app/package.json << 'EOF'
{
  "name": "cloud-native-devops-app",
  "version": "1.0.0",
  "description": "Cloud-Native DevOps Pipeline Demo Application",
  "main": "server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js",
    "test": "jest --coverage"
  },
  "keywords": ["devops", "nodejs", "prometheus", "docker"],
  "author": "Berke",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "prom-client": "^15.0.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.1",
    "jest": "^29.7.0",
    "supertest": "^6.3.3"
  }
}
EOF

echo "✅ package.json oluşturuldu"

echo ""
echo "=== ADIM 4: Server.js Oluştur ==="

cat > app/src/server.js << 'EOF'
const express = require('express');
const prometheus = require('prom-client');

const app = express();
const PORT = process.env.PORT || 3000;

// Prometheus metrics
const register = new prometheus.Registry();
prometheus.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDuration = new prometheus.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

const httpRequestTotal = new prometheus.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

// Middleware
app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration.labels(req.method, req.path, res.statusCode).observe(duration);
    httpRequestTotal.labels(req.method, req.path, res.statusCode).inc();
  });
  
  next();
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Metrics
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Main route
app.get('/', (req, res) => {
  res.json({
    message: 'Cloud-Native DevOps Pipeline',
    version: process.env.APP_VERSION || '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    hostname: require('os').hostname()
  });
});

// API endpoint
app.get('/api/info', (req, res) => {
  res.json({
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    cpu: process.cpuUsage()
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server is running on port ${PORT}`);
  console.log(`📊 Metrics available at http://localhost:${PORT}/metrics`);
  console.log(`❤️  Health check at http://localhost:${PORT}/health`);
});
EOF

echo "✅ server.js oluşturuldu"

echo ""
echo "=== ADIM 5: Dockerfile Oluştur ==="

cat > Dockerfile << 'EOF'
FROM node:18-alpine AS builder

WORKDIR /app

COPY app/package*.json ./
RUN npm ci --only=production

COPY app/src ./src

FROM node:18-alpine

WORKDIR /app

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

COPY --from=builder --chown=nodejs:nodejs /app /app

USER nodejs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

ENV NODE_ENV=production

CMD ["node", "src/server.js"]
EOF

echo "✅ Dockerfile oluşturuldu"

echo ""
echo "=== ADIM 6: npm install ==="

cd app
npm install
cd ..

echo "✅ npm packages kuruldu"

echo ""
echo "=== ADIM 7: Docker image oluştur ==="

docker build -t cloud-native-devops:1.0.0 .
docker build -t cloud-native-devops:latest .

echo "✅ Docker image oluşturuldu"

echo ""
echo "=== ADIM 8: Docker image test et ==="

echo "🔄 Container çalıştırılıyor..."
docker run -d --name app-test -p 3000:3000 cloud-native-devops:latest
sleep 3

echo "🔍 Health check..."
curl http://localhost:3000/health

echo ""
echo "🔍 Metrics endpoint..."
curl http://localhost:3000/metrics | head -20

echo ""
echo "Container durduruluyor..."
docker stop app-test
docker rm app-test

echo "✅ Docker test başarılı"

echo ""
echo "=== ADIM 9: Terraform Dosyalarını Oluştur ==="

cat > terraform/main.tf << 'TFEOF'
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
TFEOF

echo "✅ main.tf oluşturuldu"

echo ""
echo "=== ADIM 10: Variables.tf ve Outputs.tf ==="

cat > terraform/variables.tf << 'TFEOF'
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
TFEOF

cat > terraform/outputs.tf << 'TFEOF'
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
TFEOF

echo "✅ Variables ve outputs oluşturuldu"

echo ""
echo "=== ADIM 11: User Data Script ==="

mkdir -p terraform/scripts

cat > terraform/scripts/user-data.sh << 'BASHEOF'
#!/bin/bash
set -e
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== EC2 Initialization Started ==="

apt-get update
apt-get upgrade -y
apt-get install -y curl wget git unzip jq htop vim python3-pip

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker

DOCKER_COMPOSE_VERSION="2.24.0"
curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

mkdir -p /opt/app /opt/monitoring
chown -R ubuntu:ubuntu /opt/app /opt/monitoring

echo "=== EC2 Initialization Completed ==="
BASHEOF

chmod +x terraform/scripts/user-data.sh

echo "✅ User data script oluşturuldu"

echo ""
echo "=== ADIM 12: terraform.tfvars oluştur ==="

# Kendi IP adresini bul
MY_IP=$(curl -s https://api.ipify.org)

cat > terraform/terraform.tfvars << TFVARS
aws_region       = "us-east-1"
environment      = "dev"
project_name     = "cloud-native-devops"
instance_type    = "t2.micro"
public_key_path  = "~/.ssh/devops-pipeline.pub"
alert_email      = "berke@example.com"
allowed_ssh_ips  = ["${MY_IP}/32"]
ami_id           = "ami-0c7217cdde317cfec"
TFVARS

echo "✅ terraform.tfvars oluşturuldu"
echo "   IP: $MY_IP"

echo ""
echo "=== ADIM 13: Terraform Init ==="

cd terraform
terraform init

echo "✅ Terraform initialized"

echo ""
echo "=== ADIM 14: Terraform Plan ==="

terraform plan -out=tfplan

echo ""
echo "✅ Plan oluşturuldu: terraform/tfplan"
echo ""
echo "Sırada terraform apply var. Hazır mısın? (evet yazıp Enter tuşuna bas)"
