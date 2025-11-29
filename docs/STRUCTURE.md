# Project Structure

This document describes the organized folder structure of the Ollama Terraform deployment project.

## Directory Layout

```
ollama-terraform/
├── .github/
│   └── workflows/
│       ├── deploy-to-aws.yml          # Automated deployment workflow
│       └── destroy-infrastructure.yml  # Infrastructure destruction workflow
│
├── .kiro/
│   └── specs/                         # Kiro AI specifications
│       └── ec2-auto-deploy/           # EC2 deployment spec
│
├── docs/
│   ├── QUICKSTART.md                  # Quick start guide
│   └── STRUCTURE.md                   # This file
│
├── scripts/
│   ├── fix-deployment.sh              # Emergency fix script for EC2
│   └── kernel-tuning.sh               # Kernel optimization for AI workloads
│
├── terraform/
│   ├── .terraform/                    # Terraform providers (gitignored)
│   ├── terraform-ec2.tf               # Main infrastructure definition
│   ├── user-data.sh.tpl               # EC2 initialization template
│   ├── terraform.tfvars.example       # Configuration template
│   ├── terraform.tfvars               # Your configuration (gitignored)
│   └── *.tfstate                      # Terraform state files (gitignored)
│
├── .gitignore                         # Git ignore rules
├── LICENSE                            # MIT License
├── ollama-key.pem                     # SSH key (gitignored)
└── README.md                          # Main documentation
```

## Key Directories

### `.github/workflows/`
Contains GitHub Actions workflows for CI/CD automation:
- **deploy-to-aws.yml**: Automatically deploys infrastructure on push to main
- **destroy-infrastructure.yml**: Safely destroys all AWS resources

### `terraform/`
All Terraform infrastructure-as-code files:
- **terraform-ec2.tf**: Defines EC2 instance, security groups, VPC, etc.
- **user-data.sh.tpl**: Bootstrap script that runs on EC2 first boot
- **terraform.tfvars**: Your configuration values (not committed to git)

### `scripts/`
Utility scripts for deployment and maintenance:
- **fix-deployment.sh**: Emergency repair script for failed deployments
- **kernel-tuning.sh**: Optimizes Linux kernel for AI workloads

### `docs/`
Documentation files:
- **QUICKSTART.md**: 3-step setup guide
- **STRUCTURE.md**: This file

### `.kiro/specs/`
Kiro AI agent specifications for automated development

## Changes Made

### Removed Files
The following redundant documentation files were removed:
- `CHANGELOG.md` - Version history (use git log instead)
- `CONTRIBUTING.md` - Contribution guidelines (simplified in README)
- `GITHUB-ACTIONS-SETUP.md` - Detailed setup (consolidated into QUICKSTART)
- `GITOPS-QUICKSTART.md` - Quick start (consolidated into QUICKSTART)
- `KERNEL-TUNING.md` - Kernel tuning details (script is self-documenting)
- `TROUBLESHOOTING.md` - Troubleshooting guide (key points in QUICKSTART)

### Reorganized Files
- Moved all Terraform files to `terraform/` directory
- Moved utility scripts to `scripts/` directory
- Created `docs/` directory for essential documentation
- Updated `.gitignore` to reflect new structure

### Updated References
- Updated README.md with new folder structure
- Updated GitHub Actions workflows to use `terraform/` directory
- Updated all documentation links

## Benefits

1. **Cleaner Root Directory**: Only essential files at root level
2. **Logical Organization**: Related files grouped together
3. **Easier Navigation**: Clear separation of concerns
4. **Better Maintainability**: Easier to find and update files
5. **Reduced Redundancy**: Consolidated documentation

## Usage

### Deploy Infrastructure
```bash
# Push to GitHub (automatic deployment)
git push origin main

# Or manually trigger via GitHub Actions UI
```

### Destroy Infrastructure
```bash
# Via GitHub Actions UI:
# 1. Go to Actions tab
# 2. Select "Destroy AWS Infrastructure"
# 3. Type "destroy" to confirm
# 4. Run workflow
```

### Local Development
```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply
```

## Notes

- All sensitive files (`.pem`, `.tfvars`, `.tfstate`) are gitignored
- Terraform state is stored locally (consider remote backend for production)
- GitHub Actions automatically creates `terraform.tfvars` from secrets/variables
- Scripts in `scripts/` directory can be run directly on EC2 instances
