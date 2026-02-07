# Persona Plex GCP Deployment Guide

This guide walks you through deploying Persona Plex on Google Cloud Platform with optimal GPU instances.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Detailed Setup](#detailed-setup)
4. [Model Download](#model-download)
5. [Deployment Options](#deployment-options)
6. [Monitoring](#monitoring)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools
- Google Cloud SDK (`gcloud`) - [Install Guide](https://cloud.google.com/sdk/docs/install)
- Terraform (>= 1.0) - [Install Guide](https://developer.hashicorp.com/terraform/downloads)
- Git
- (Optional) Docker for containerized deployment

### GCP Requirements
- Active GCP account with billing enabled (free credits work)
- Project with Compute Engine API enabled
- GPU quota for T4 instances in us-central1
- Sufficient permissions (Project Editor or Compute Admin)

### Request GPU Quota

By default, GCP limits GPU usage. Request quota increase:

1. Go to [GCP Console > IAM & Admin > Quotas](https://console.cloud.google.com/iam-admin/quotas)
2. Filter by: "NVIDIA T4 GPUs"
3. Select region: us-central1
4. Click "EDIT QUOTAS" and request at least 1 GPU
5. Wait for approval (usually 24-48 hours)

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/varun-ahlawat/VoiceControlAgent.git
cd VoiceControlAgent
```

### 2. Configure GCP Authentication

```bash
# Login to GCP
gcloud auth login

# Set your project
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable storage.googleapis.com
```

### 3. Deploy with deploy.sh (Recommended)

```bash
cd deployment/gcp
./deploy.sh
```

### Alternative: Deploy with Terraform

```bash
cd deployment/gcp

# Copy and edit configuration
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edit with your project details

# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy (takes 5-10 minutes)
terraform apply
```

### 4. Access

```bash
# Get instance IP
gcloud compute instances describe persona-plex-gpu \
    --zone=us-central1-a \
    --format="get(networkInterfaces[0].accessConfigs[0].natIP)"

# Visit: https://EXTERNAL_IP:8998

# SSH into the instance
gcloud compute ssh persona-plex-gpu --zone=us-central1-a
```

## Detailed Setup

### Terraform Configuration Options

Edit `terraform.tfvars`:

```hcl
# Required
project_id = "your-gcp-project-id"

# Instance Configuration
region        = "us-central1"        # Choose closest to users
zone          = "us-central1-a"
instance_name = "persona-plex-gpu"
machine_type  = "n1-standard-4"      # 4 vCPUs, 15 GB RAM

# GPU Configuration
gpu_type  = "nvidia-tesla-t4"        # default for MVP
gpu_count = 1
disk_size_gb = 200                    # SSD storage

# Environment
environment = "prod"                  # or "dev", "staging"
```

### Budget Options

**MVP (Default):**
```hcl
machine_type = "n1-standard-4"
gpu_type     = "nvidia-tesla-t4"
disk_size_gb = 200
```
Cost: ~$0.67/hour (~$489/month)

**Production (Upgrade):**
```hcl
machine_type = "n1-standard-8"
gpu_type     = "nvidia-tesla-a100"
disk_size_gb = 500
```
Cost: ~$2.95/hour (~$2,150/month)

## Model Download

### Option 1: Interactive Script (Recommended)

```bash
# SSH into instance
gcloud compute ssh persona-plex-gpu --zone=us-central1-a

# Activate virtual environment
source /opt/persona-plex/venv/bin/activate

# Run download script
cd /opt/persona-plex
sudo bash scripts/download_models.sh
```

The script will guide you through:
1. Hugging Face authentication
2. Model repository selection
3. Download progress
4. Verification

### Option 2: Manual Download with Hugging Face CLI

```bash
# Login to Hugging Face
huggingface-cli login
# Enter your token from: https://huggingface.co/settings/tokens

# Download model
huggingface-cli download nvidia/Persona-Plex \
    --local-dir /opt/persona-plex/models/persona-plex \
    --local-dir-use-symlinks False
```

### Option 3: Download from GCS Bucket

If you have the model in Google Cloud Storage:

```bash
# Copy from bucket
gsutil -m cp -r gs://your-bucket/persona-plex/* \
    /opt/persona-plex/models/persona-plex/
```

### Hugging Face Token Setup

1. Go to [Hugging Face Tokens](https://huggingface.co/settings/tokens)
2. Create a new token with "Read" permissions
3. Copy the token
4. On your instance:
   ```bash
   export HF_TOKEN="your_token_here"
   # Or add to .bashrc for persistence
   echo 'export HF_TOKEN="your_token_here"' >> ~/.bashrc
   ```

### Model Access Requirements

**Important Notes:**
- Persona Plex may require access request on Hugging Face
- Go to the model page: https://huggingface.co/nvidia/Persona-Plex
- Click "Request Access" if gated
- Wait for approval (usually instant to 24 hours)
- Then run the download script

## Deployment Options

### Option 1: Direct Python Deployment

```bash
# Activate virtual environment
source /opt/persona-plex/venv/bin/activate

# Run your application
cd /opt/persona-plex
python your_app.py
```

### Option 2: Docker Deployment

```bash
# Build Docker image
cd deployment/gcp
docker build -t persona-plex:latest .

# Run with GPU support
docker run --gpus all -p 8000:8000 persona-plex:latest
```

### Option 3: Docker Compose (Recommended for Production)

```bash
cd deployment/gcp

# Copy model files to ./models directory
cp -r /opt/persona-plex/models ./models

# Start services
docker-compose up -d

# View logs
docker-compose logs -f persona-plex

# Stop services
docker-compose down
```

### Option 4: Systemd Service

Create a systemd service for auto-start:

```bash
# Edit the service file
sudo nano /etc/systemd/system/persona-plex.service
```

Example service file:
```ini
[Unit]
Description=Persona Plex Voice AI Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/persona-plex
Environment="CUDA_VISIBLE_DEVICES=0"
ExecStart=/opt/persona-plex/venv/bin/python /opt/persona-plex/app.py
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable persona-plex
sudo systemctl start persona-plex
sudo systemctl status persona-plex
```

## Monitoring

### GPU Monitoring

```bash
# Watch GPU usage
watch -n 1 nvidia-smi

# Detailed GPU stats
nvidia-smi dmon -s pucvmet
```

### System Monitoring

```bash
# CPU and memory
htop

# Disk usage
df -h

# Network usage
iftop
```

### Application Logs

```bash
# View logs
tail -f /opt/persona-plex/logs/app.log

# Systemd logs
journalctl -u persona-plex -f
```

### Prometheus Metrics

Prometheus and Grafana are not included in the default MVP deployment to keep things simple.
To add monitoring later, you can extend `docker-compose.yml` with Prometheus and Grafana services.

## Troubleshooting

### GPU Not Detected

```bash
# Check NVIDIA driver
nvidia-smi

# If not working, reinstall driver
sudo apt-get update
sudo apt-get install -y nvidia-driver-525
sudo reboot
```

### CUDA Out of Memory

Solutions:
1. Reduce batch size
2. Enable gradient checkpointing
3. Use model quantization (INT8)
4. Upgrade to A100 80GB

```python
# Example: Load model with 8-bit quantization
from transformers import AutoModelForCausalLM
import torch

model = AutoModelForCausalLM.from_pretrained(
    "nvidia/Persona-Plex",
    load_in_8bit=True,
    device_map="auto",
    torch_dtype=torch.float16
)
```

### Slow Model Loading

```bash
# Use local SSD for model caching
sudo mkdir -p /mnt/disks/local-ssd
sudo mount /dev/nvme0n1 /mnt/disks/local-ssd
export HF_HOME=/mnt/disks/local-ssd/cache
```

### Network Connectivity Issues

```bash
# Check firewall rules
gcloud compute firewall-rules list

# Add custom rule if needed
gcloud compute firewall-rules create allow-custom-port \
    --allow tcp:8000 \
    --target-tags=persona-plex
```

### Model Download Fails

```bash
# Check Hugging Face authentication
huggingface-cli whoami

# Re-login if needed
huggingface-cli login

# Try manual download with resume
huggingface-cli download nvidia/Persona-Plex \
    --local-dir /opt/persona-plex/models/persona-plex \
    --resume-download
```

### Permission Errors

```bash
# Fix ownership
sudo chown -R $(whoami):$(whoami) /opt/persona-plex

# Fix permissions
sudo chmod -R 755 /opt/persona-plex
```

## Cost Optimization

### 1. Stop When Not in Use (Most Important for MVP)

```bash
# Stop instance when done
gcloud compute instances stop persona-plex-gpu --zone=us-central1-a

# Start when needed
gcloud compute instances start persona-plex-gpu --zone=us-central1-a
```

With $300 free credits:
- 24/7 usage: ~18 days
- 12 hours/day: ~37 days
- Stop when idle to maximize credit lifetime

### 2. Use Committed Use Discounts (Production)
- Save 37% with 1-year commitment
- Save 55% with 3-year commitment

```bash
# Create commitment (example)
gcloud compute commitments create my-commitment \
    --region=us-central1 \
    --plan=12-month \
    --resources=vcpu=8,memory=30GB,accelerator=type=nvidia-tesla-a100,count=1
```

### 2. Use Preemptible Instances for Development

In `terraform.tfvars`:
```hcl
preemptible = true  # Add this variable
```

### 3. Auto-Shutdown During Off Hours

```bash
# Create shutdown script
crontab -e

# Add line (shutdown at 6 PM, start at 8 AM on weekdays)
0 18 * * 1-5 gcloud compute instances stop persona-plex-gpu --zone=us-central1-a
0 8 * * 1-5 gcloud compute instances start persona-plex-gpu --zone=us-central1-a
```

### 4. Monitor Costs

```bash
# View current costs
gcloud billing accounts list
gcloud billing accounts describe BILLING_ACCOUNT_ID

# Set budget alerts in GCP Console
```

## Scaling

### Horizontal Scaling (Multiple Instances)

1. Modify Terraform to create instance group
2. Add load balancer
3. Use Cloud SQL or Redis for state management

### Vertical Scaling (Bigger Instance)

```bash
# Stop instance
gcloud compute instances stop persona-plex-gpu --zone=us-central1-a

# Change machine type
gcloud compute instances set-machine-type persona-plex-gpu \
    --machine-type=a2-highgpu-1g \
    --zone=us-central1-a

# Start instance
gcloud compute instances start persona-plex-gpu --zone=us-central1-a
```

## Security Best Practices

1. **Restrict SSH Access**
   ```bash
   # Update firewall to allow only your IP
   gcloud compute firewall-rules update persona-plex-allow-ssh \
       --source-ranges=YOUR_IP/32
   ```

2. **Use Secret Manager for Tokens**
   ```bash
   # Store HF token
   gcloud secrets create hf-token --data-file=-
   # Enter token and press Ctrl+D
   ```

3. **Enable OS Login**
   ```bash
   gcloud compute instances add-metadata persona-plex-gpu \
       --metadata enable-oslogin=TRUE
   ```

4. **Regular Updates**
   ```bash
   sudo apt-get update
   sudo apt-get upgrade -y
   ```

## Support

For issues:
1. Check logs: `/opt/persona-plex/logs/`
2. Review Terraform output: `terraform show`
3. Check GCP quotas and limits
4. Open an issue on GitHub

## Cleanup

To destroy all resources:

```bash
cd deployment/gcp
terraform destroy
```

⚠️ This will delete the instance and all data. Backup important data first!
