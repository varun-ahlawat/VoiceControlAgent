# GCP Deployment Files for Persona Plex

This directory contains all necessary files to deploy Persona Plex on Google Cloud Platform.

## Contents

### Terraform Files
- **main.tf** - Main Terraform configuration for GCP infrastructure
- **terraform.tfvars.example** - Example variables file (copy to terraform.tfvars)
- **startup-script.sh** - Instance initialization script

### Docker Files
- **Dockerfile** - Container image for Persona Plex
- **docker-compose.yml** - Multi-container deployment with monitoring

### gcloud CLI Scripts
- **gcloud-deploy.sh** - Deploy using gcloud CLI (alternative to Terraform)
- **gcloud-cleanup.sh** - Remove all deployed resources

## Quick Start

### Option 1: Deploy with Terraform (Recommended)

```bash
# 1. Configure
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edit your project ID

# 2. Deploy
terraform init
terraform plan
terraform apply

# 3. Connect
gcloud compute ssh persona-plex-gpu --zone=us-central1-a
```

### Option 2: Deploy with gcloud CLI

```bash
# Make script executable
chmod +x gcloud-deploy.sh

# Deploy
./gcloud-deploy.sh your-project-id
```

## Prerequisites

1. **GCP Account** with billing enabled
2. **GPU Quota** - Request A100 or T4 quota in your region
3. **gcloud CLI** installed and authenticated
4. **Terraform** (for Terraform deployment)

## Instance Specifications

**Default Configuration:**
- Machine: n1-standard-8 (8 vCPUs, 30 GB RAM)
- GPU: 1x NVIDIA A100 (40GB)
- Disk: 500 GB SSD
- Region: us-central1
- Cost: ~$2.95/hour (~$2,150/month)

**Budget Option:**
- Machine: n1-standard-4
- GPU: 1x NVIDIA T4 (16GB)
- Cost: ~$0.95/hour (~$700/month)

See [PERSONA_PLEX_GCP_SETUP.md](../docs/PERSONA_PLEX_GCP_SETUP.md) for detailed specifications.

## Post-Deployment

After deployment:

1. **SSH to instance:**
   ```bash
   gcloud compute ssh persona-plex-gpu --zone=us-central1-a
   ```

2. **Run setup:**
   ```bash
   sudo bash /opt/persona-plex/setup.sh
   ```

3. **Download models:**
   ```bash
   sudo bash /opt/persona-plex/scripts/download_models.sh
   ```

4. **Deploy your application**

## Cleanup

### With Terraform:
```bash
terraform destroy
```

### With gcloud CLI:
```bash
chmod +x gcloud-cleanup.sh
./gcloud-cleanup.sh your-project-id
```

## Documentation

- [Persona Plex GCP Setup](../../docs/PERSONA_PLEX_GCP_SETUP.md) - Detailed instance recommendations
- [Deployment Guide](../../docs/DEPLOYMENT_GUIDE.md) - Complete deployment walkthrough

## Support

For issues or questions:
1. Check the [Deployment Guide](../../docs/DEPLOYMENT_GUIDE.md)
2. Review GCP logs: `gcloud logging read`
3. Open an issue on GitHub

## Cost Estimation

Use the GCP Pricing Calculator:
https://cloud.google.com/products/calculator

Example for n1-standard-8 + A100:
- Compute: $2.95/hour
- Storage: $85/month (500 GB SSD)
- Network: ~$50/month
- **Total: ~$2,200/month**

With 1-year commitment: ~$1,400/month (save 36%)
