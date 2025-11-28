# Fix: Internet Gateway Limit Exceeded

## Problem

You're seeing this error:
```
Error: creating EC2 Internet Gateway: operation error EC2: CreateInternetGateway, 
https response error StatusCode: 400, RequestID: ..., 
api error InternetGatewayLimitExceeded: The maximum number of internet gateways has been reached.
```

## Root Cause

AWS limits you to **5 Internet Gateways per region**. You likely have old VPCs with Internet Gateways that weren't cleaned up from previous deployments.

## Solution

I've updated the Terraform configuration to use the **default VPC** instead of creating a new one. This avoids the Internet Gateway limit.

### Step 1: Clean Up Old Resources

**Option A: Using Terraform (Recommended)**

```powershell
# Run the cleanup script
.\cleanup-old-resources.ps1

# Or manually:
terraform destroy -auto-approve
```

**Option B: Manual Cleanup in AWS Console**

1. Go to AWS Console → VPC
2. Delete custom VPCs (keep the default VPC)
3. Internet Gateways will be automatically deleted when VPCs are deleted
4. Delete any orphaned Elastic IPs
5. Delete old EC2 instances if any

### Step 2: Reinitialize Terraform

```powershell
# Remove old state
Remove-Item .terraform -Recurse -Force
Remove-Item .terraform.lock.hcl -Force

# Reinitialize
terraform init
```

### Step 3: Deploy with New Configuration

```powershell
# Deploy
terraform apply

# Or use the deployment script
.\deploy.ps1
```

## What Changed

### Old Configuration (terraform-ec2-custom-vpc.tf.backup)
- Created a new VPC
- Created a new Internet Gateway
- Created new subnets
- Created route tables

### New Configuration (terraform-ec2.tf)
- Uses the **default VPC** (already has Internet Gateway)
- Uses default subnets
- Only creates Security Group and EC2 instance
- **No Internet Gateway limit issues!**

## Benefits of Using Default VPC

✅ No Internet Gateway limit issues
✅ Faster deployment (no VPC creation)
✅ Simpler configuration
✅ Lower chance of hitting AWS limits
✅ Easier cleanup

## Verify Default VPC Exists

```powershell
# Check if default VPC exists
aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text
```

If you don't have a default VPC, create one:

```powershell
aws ec2 create-default-vpc
```

## Check Current Internet Gateways

```powershell
# List all Internet Gateways
aws ec2 describe-internet-gateways --query 'InternetGateways[*].[InternetGatewayId,Attachments[0].VpcId]' --output table
```

## Manual Cleanup Commands

If you need to manually delete resources:

```powershell
# List all VPCs
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,IsDefault,Tags[?Key==`Name`].Value|[0]]' --output table

# Delete a specific VPC (replace vpc-xxxxx)
aws ec2 delete-vpc --vpc-id vpc-xxxxx

# Detach and delete Internet Gateway
aws ec2 detach-internet-gateway --internet-gateway-id igw-xxxxx --vpc-id vpc-xxxxx
aws ec2 delete-internet-gateway --internet-gateway-id igw-xxxxx

# Release Elastic IP
aws ec2 release-address --allocation-id eipalloc-xxxxx
```

## Troubleshooting

### Error: "Network vpc-xxx is not attached to any internet gateway"

This means the VPC was partially created but the Internet Gateway failed. Clean up:

```powershell
terraform destroy -auto-approve
```

### Error: "VPC has dependencies and cannot be deleted"

Delete resources in this order:
1. EC2 Instances
2. Elastic IPs
3. NAT Gateways
4. Subnets
5. Route Tables
6. Internet Gateways
7. VPC

### Still Having Issues?

Contact AWS Support to increase your Internet Gateway limit, or use the default VPC configuration (already implemented).

## Success!

After following these steps, your deployment should work without Internet Gateway limit errors! 🚀

The new configuration uses the default VPC and will deploy successfully.
