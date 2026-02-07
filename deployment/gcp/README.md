# GCP Deployment Files for Persona Plex

This directory contains all necessary files to deploy Persona Plex on Google Cloud Platform with a T4 GPU on Compute Engine.

## Why Compute Engine with T4 GPU?

- **Stateful streaming**: PersonaPlex runs in `streaming_forever(1)` mode — not suited for serverless
- **Low latency**: <200ms required for natural voice interaction; Cloud Run cold starts (~5s) break conversation flow
- **Cost-effective**: T4 GPU at ~$0.67/hour; $300 GCP free credits give ~18 days of 24/7 usage
- **Simple networking**: Uses default VPC — no custom network permissions needed

## Contents

### Deployment Script
- **deploy.sh** - One-command deployment (recommended)

### Terraform Files
- **main.tf** - Terraform configuration for GCP infrastructure
- **terraform.tfvars.example** - Example variables file (copy to terraform.tfvars)
- **startup-script.sh** - Instance initialization script

### Docker Files
- **Dockerfile** - Container image for Persona Plex
- **docker-compose.yml** - Container deployment with GPU support

### gcloud CLI Scripts
- **gcloud-deploy.sh** - Deploy using gcloud CLI (alternative to deploy.sh with more options)
- **gcloud-cleanup.sh** - Remove all deployed resources

## Quick Start

```bash
# 1. Request T4 GPU quota (if needed)
# Go to: https://console.cloud.google.com/iam-admin/quotas
# Search: "NVIDIA T4 GPUs" in us-central1
# Request: 1 GPU

# 2. Deploy
./deploy.sh

# 3. Access
# Get IP: gcloud compute instances describe persona-plex-gpu --zone=us-central1-a --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
# Visit: http://EXTERNAL_IP:8998

# 4. Stop when done (save credits)
gcloud compute instances stop persona-plex-gpu --zone=us-central1-a
```

### Alternative: Deploy with Terraform

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edit your project ID

terraform init
terraform plan
terraform apply
```

### Alternative: Deploy with gcloud CLI

```bash
chmod +x gcloud-deploy.sh
./gcloud-deploy.sh your-project-id
```

## Prerequisites

1. **GCP Account** with billing enabled (free credits work)
2. **GPU Quota** - Request T4 quota in us-central1
3. **gcloud CLI** installed and authenticated
4. **Terraform** (only for Terraform deployment option)

## Instance Specifications

**Default Configuration (MVP):**
- Machine: n1-standard-4 (4 vCPUs, 15 GB RAM)
- GPU: 1x NVIDIA T4 (16GB)
- Disk: 200 GB SSD
- Region: us-central1
- Network: Default VPC
- Cost: ~$0.67/hour (~$490/month)

See [PERSONA_PLEX_GCP_SETUP.md](../../docs/PERSONA_PLEX_GCP_SETUP.md) for detailed specifications.

## Post-Deployment

After deployment:

1. **SSH to instance:**
   ```bash
   gcloud compute ssh persona-plex-gpu --zone=us-central1-a
   ```

2. **Access your application:**
   ```bash
   http://EXTERNAL_IP:8998
   ```

## Cleanup

### With deploy.sh / gcloud:
```bash
chmod +x gcloud-cleanup.sh
./gcloud-cleanup.sh your-project-id
```

### With Terraform:
```bash
terraform destroy
```

## Documentation

- [Persona Plex GCP Setup](../../docs/PERSONA_PLEX_GCP_SETUP.md) - Detailed instance recommendations
- [Deployment Guide](../../docs/DEPLOYMENT_GUIDE.md) - Complete deployment walkthrough

## Cost Estimation

With $300 GCP free credits and T4 GPU:
- **T4 cost**: ~$0.67/hour
- **24/7 runtime**: ~18 days on free credits
- **12 hours/day**: ~37 days on free credits

To save credits, stop the instance when not in use:
```bash
gcloud compute instances stop persona-plex-gpu --zone=us-central1-a
gcloud compute instances start persona-plex-gpu --zone=us-central1-a
```
