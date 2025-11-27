# Ollama Infrastructure on AWS

Production-ready Terraform infrastructure for deploying Ollama AI service with Open-WebUI on AWS.

## 🚀 Quick Deploy

```powershell
# Deploy to AWS
.\scripts\deploy.ps1
```

---

## 📋 What This Deploys

A complete, production-ready infrastructure including:

- **🤖 Ollama AI Service**: Large language model serving platform
- **🌐 Open-WebUI**: Web interface for interacting with Ollama
- **⚖️ Load Balancer**: Distributes traffic across multiple instances
- **📈 Auto Scaling**: Automatically scales 2-10 instances based on load
- **🗄️ DynamoDB**: NoSQL database with point-in-time recovery
- **📦 S3 + CloudFront**: Object storage with global CDN
- **📊 CloudWatch**: Comprehensive monitoring, logging, and alerting
- **🔒 Security**: Encryption at rest/transit, IAM roles, security groups
- **🌍 Multi-AZ**: High availability across multiple availability zones

---

## 🔧 Prerequisites

1. **AWS CLI** (v2.x or later)
   ```bash
   aws --version
   ```

2. **Terraform** (v1.5.0 or later)
   ```bash
   terraform version
   ```

3. **PowerShell** (v7.0 or later)
   ```bash
   pwsh --version
   ```

4. **AWS Credentials**
   ```bash
   aws configure
   # Enter your AWS Access Key ID
   # Enter your AWS Secret Access Key
   # Enter default region: us-east-1
   # Enter default output format: json
   ```

---

## 🚀 Deployment

### Step 1: Configure (Optional)

Edit `infrastructure/terraform.tfvars` to customize:

```hcl
instance_type = "t3.xlarge"      # Instance size
ollama_model  = "deepseek-r1:8b" # Ollama model to use
aws_region    = "us-east-1"      # AWS region
```

### Step 2: Deploy

```powershell
# Deploy infrastructure
.\scripts\deploy.ps1

# The script will:
# 1. Validate prerequisites
# 2. Require typing "DEPLOY" to confirm
# 3. Initialize Terraform
# 4. Create and apply infrastructure
# 5. Display access URLs
```

### Step 3: Wait for Initialization

- **5-10 minutes**: Instances boot and install Ollama
- **5-15 minutes**: Ollama downloads the model
- **Total**: ~10-25 minutes until fully operational

### Step 4: Access

The deployment outputs:
```
🌐 Open-WebUI URL:
   http://ollama-alb-xxxxx.us-east-1.elb.amazonaws.com:8080

🤖 Ollama API URL:
   http://ollama-alb-xxxxx.us-east-1.elb.amazonaws.com:11434
```

1. Open the Open-WebUI URL in your browser
2. Create an account (first user = admin)
3. Start chatting with Ollama!

---

## 📊 Infrastructure Details

### Compute
- **Instances**: 2-10x t3.xlarge (auto-scales)
- **OS**: Ubuntu 22.04 LTS
- **Software**: Ollama + Open-WebUI (Docker)

### Networking
- **VPC**: 10.0.0.0/16
- **Subnets**: 2 public, 2 private (multi-AZ)
- **Load Balancer**: Application Load Balancer
- **Auto Scaling**: CPU-based (40% scale up, 30% scale down)

### Storage
- **DynamoDB**: On-demand billing, PITR enabled
- **S3**: Versioning, encryption, lifecycle policies
- **CloudFront**: Global CDN for static assets

### Security
- **Encryption**: At rest (S3, DynamoDB) and in transit (HTTPS)
- **IAM**: Least-privilege roles
- **Security Groups**: Specific port ranges
- **SSH**: Key-based authentication only

### Monitoring
- **CloudWatch**: Dashboards, logs, alarms
- **SNS**: Alert notifications
- **Metrics**: CPU, memory, requests, errors

---

## 🔄 Common Operations

### Check Status
```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names ollama-asg
```

### View Logs
```bash
aws logs tail /aws/ec2/ollama-app --follow
```

### Test API
```bash
curl http://your-alb-dns:11434/api/tags
```

### Scale Manually
```bash
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name ollama-asg \
  --desired-capacity 5
```

### SSH into Instance
```bash
# Get instance IP
INSTANCE_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=ollama-asg-instance" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

# Connect
ssh -i .ssh/ollama-key ubuntu@$INSTANCE_IP
```

### Update Ollama Model
1. Edit `infrastructure/terraform.tfvars`:
   ```hcl
   ollama_model = "llama3.2:8b"
   ```
2. Redeploy:
   ```powershell
   .\scripts\deploy.ps1
   ```

---

## 🗑️ Destroy Infrastructure

```powershell
.\scripts\destroy.ps1

# Requires typing "DESTROY" and "YES" to confirm
# Use -Force to skip confirmations (dangerous!)
```

**⚠️ WARNING**: This permanently deletes all resources and data!

---

## 💰 Estimated Costs

**Production** (2-10x t3.xlarge, 24/7):
- EC2: ~$240-$1,200/month
- Load Balancer: ~$20/month
- Data Transfer: ~$50/month
- Storage: ~$20/month
- **Total: ~$330-$1,290/month**

Costs scale with:
- Number of instances (auto-scales 2-10)
- Data transfer volume
- Storage usage

---

## 🔒 Security Best Practices

### 1. Restrict SSH Access
```bash
# Update security group to allow SSH only from your IP
YOUR_IP=$(curl -s ifconfig.me)
aws ec2 authorize-security-group-ingress \
  --group-id $(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=ollama-app-sg" \
    --query 'SecurityGroups[0].GroupId' \
    --output text) \
  --protocol tcp \
  --port 22 \
  --cidr $YOUR_IP/32
```

### 2. Set Up Email Alerts
```bash
aws sns subscribe \
  --topic-arn $(cd infrastructure && terraform output -raw ollama_sns_topic_arn) \
  --protocol email \
  --notification-endpoint your-email@example.com
```

### 3. Enable CloudTrail
```bash
aws cloudtrail create-trail \
  --name ollama-audit-trail \
  --s3-bucket-name your-cloudtrail-bucket
```

---

## 🐛 Troubleshooting

### Instances Not Healthy
```bash
# Check Auto Scaling activities
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name ollama-asg \
  --max-records 10

# Check instance logs
aws ec2 get-console-output --instance-id i-xxxxx
```

### Ollama Not Responding
```bash
# SSH into instance
ssh -i .ssh/ollama-key ubuntu@INSTANCE_IP

# Check Ollama status
sudo systemctl status snap.ollama.ollama

# Restart Ollama
sudo systemctl restart snap.ollama.ollama

# Check if model is downloaded
ollama list
```

### Open-WebUI Not Accessible
```bash
# Check Docker container
docker ps -a | grep open-webui

# View logs
docker logs open-webui

# Restart container
docker restart open-webui
```

---

## 📁 Project Structure

```
.
├── infrastructure/
│   ├── main.tf              # Provider configuration
│   ├── vpc.tf               # VPC and networking
│   ├── alb.tf               # Load balancer
│   ├── asg.tf               # Auto Scaling Group
│   ├── dynamodb.tf          # DynamoDB table
│   ├── s3.tf                # S3 bucket
│   ├── cloudfront.tf        # CloudFront CDN
│   ├── iam.tf               # IAM roles
│   ├── monitoring.tf        # CloudWatch
│   ├── variables.tf         # Variables
│   ├── outputs.tf           # Outputs
│   └── terraform.tfvars     # Configuration
├── scripts/
│   ├── deploy.ps1           # Deployment script
│   └── destroy.ps1          # Destruction script
└── README.md                # This file
```

---

## 🎯 What's Included

### ✅ Production Features
- Multi-AZ high availability
- Auto-scaling (2-10 instances)
- Load balancing
- Encryption at rest and in transit
- Point-in-time recovery (DynamoDB)
- S3 versioning and lifecycle policies
- CloudWatch monitoring and alarms
- SNS alerting
- IAM least-privilege policies
- Security groups with specific rules
- VPC with public/private subnets
- CloudFront CDN
- Automated backups

### ✅ Monitoring
- CloudWatch dashboards
- CPU, memory, disk, network metrics
- Request count and latency
- Error rates
- Auto Scaling activities
- S3 and CloudFront metrics
- Custom Ollama metrics

### ✅ Security
- Encryption at rest (S3, DynamoDB)
- Encryption in transit (HTTPS ready)
- IAM roles with least privilege
- Security groups with specific ports
- SSH key-based authentication
- VPC isolation
- Private subnets for future use

---

## 📞 Support

For issues:
1. Check CloudWatch logs
2. Review Terraform state: `terraform show`
3. Check AWS Service Health Dashboard
4. Review this documentation

---

## 🎉 Ready to Deploy!

```powershell
.\scripts\deploy.ps1
```

**Your production-ready Ollama infrastructure awaits!** 🚀🤖✨
