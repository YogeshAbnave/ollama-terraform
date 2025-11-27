# Remote State Setup for CI/CD

## Why Remote State?

When using GitHub Actions or any CI/CD, Terraform needs to store its state file remotely so multiple runs can access the same state. Without this, each CI/CD run starts fresh and tries to recreate existing resources.

## Option 1: Skip CI/CD Deployment (Current Setup)

The GitHub Actions workflow now **checks for existing infrastructure** and skips deployment if resources already exist. This works for:
- ✅ Monitoring infrastructure status
- ✅ Verifying deployments
- ❌ Updating infrastructure via CI/CD

**Use this if:** You deploy manually from your local machine.

## Option 2: Set Up Remote State (Recommended for CI/CD)

### Step 1: Create S3 Bucket for State

```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket ollama-terraform-state \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket ollama-terraform-state \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket ollama-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket ollama-terraform-state \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

### Step 2: Create DynamoDB Table for Locking

```bash
aws dynamodb create-table \
  --table-name ollama-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### Step 3: Update main.tf

Uncomment the backend configuration in `infrastructure/main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "ollama-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ollama-terraform-locks"
    encrypt        = true
  }
}
```

### Step 4: Migrate Existing State

```bash
cd infrastructure

# Initialize with new backend
terraform init -migrate-state

# Verify state is in S3
aws s3 ls s3://ollama-terraform-state/production/
```

### Step 5: Update GitHub Actions

The workflow will now automatically use the remote state!

## Option 3: Import Existing Resources (Alternative)

If you want to manage existing resources with a fresh Terraform state:

```bash
cd infrastructure

# Remove local state
rm -rf .terraform terraform.tfstate*

# Initialize
terraform init

# Import existing resources
terraform import aws_vpc.main vpc-02b78bc6172ebe97d
terraform import aws_lb.main arn:aws:elasticloadbalancing:us-east-1:992167236365:loadbalancer/app/ollama-alb/3fd7be4d309c1b0e
terraform import aws_autoscaling_group.app ollama-asg
terraform import aws_dynamodb_table.main ollama-data-table
terraform import aws_key_pair.deployer ollama-key
terraform import aws_iam_role.ec2_role ollama-ec2-role
terraform import aws_sns_topic.image_alerts arn:aws:sns:us-east-1:992167236365:ollama-storage-alerts
# ... import other resources as needed

# Verify
terraform plan
```

## Recommendation

**For your use case:**

Since your infrastructure is already deployed and working:

1. **Keep deploying locally** - Use `.\scripts\deploy.ps1` for updates
2. **Use GitHub Actions for monitoring** - The workflow now checks status without trying to recreate
3. **Optional: Set up remote state later** - If you want full CI/CD deployment

## Current Workflow Behavior

The updated GitHub Actions workflow:
- ✅ Checks if infrastructure exists
- ✅ Skips deployment if resources exist
- ✅ Shows infrastructure status
- ✅ Displays access URLs
- ✅ Verifies infrastructure health

This prevents the "resource already exists" errors while still providing visibility into your infrastructure status.

---

**Your infrastructure is production-ready and accessible at:**
- Open-WebUI: http://ollama-alb-2041931387.us-east-1.elb.amazonaws.com:8080
- Ollama API: http://ollama-alb-2041931387.us-east-1.elb.amazonaws.com:11434
