# VoiceControlAgent

World's first full duplex agentic voice layer for AI agents, that can do complex tool use. This includes a coupled state management system built on NVIDIA's open-source model called Persona Plex. Out of the box, Persona Plex lacks agentic capabilities, which this project provides.

## 🚀 Quick Start - GCP Deployment

This repository includes a deployment setup for hosting Persona Plex on GCP Compute Engine with a T4 GPU — optimized for the stateful, low-latency streaming that PersonaPlex requires.

### Why Compute Engine (not Cloud Run)?

- PersonaPlex runs in `streaming_forever(1)` mode — stateful, continuously streaming
- Needs <200ms latency for natural voice interaction
- Cloud Run's cold start (~5s) and best-effort session affinity breaks conversation flow
- T4 GPU at ~$0.67/hour — $300 GCP free credits give ~18 days of 24/7 usage

### 📖 Documentation

- **[GCP Deployment Guide](docs/DEPLOYMENT_GUIDE.md)** - Complete step-by-step deployment walkthrough
- **[Instance Recommendations](docs/PERSONA_PLEX_GCP_SETUP.md)** - Detailed analysis of GCP instance types and costs
- **[Deployment Summary](docs/DEPLOYMENT_SUMMARY.md)** - Complete review of all deliverables
- **[Quick Reference](docs/QUICK_REFERENCE.md)** - Quick reference for common tasks

### 🎯 Default Setup (MVP)

**Configuration:**
- **Instance**: n1-standard-4 (4 vCPUs, 15 GB RAM)
- **GPU**: 1x NVIDIA T4 (16GB VRAM)
- **Storage**: 200 GB SSD
- **Network**: Default VPC (no custom VPC permissions needed)
- **Cost**: ~$0.67/hour

### 📦 What's Included

#### Infrastructure as Code
- **deploy.sh** - One-command deployment script (recommended)
- **Terraform Configuration** - Complete GCP infrastructure setup
- **gcloud Scripts** - Alternative CLI-based deployment
- **Docker Setup** - Containerized deployment with GPU support

#### Automated Setup
- **Environment Setup Script** - Installs PyTorch, CUDA, and all dependencies
- **Model Download Script** - Automated Hugging Face model retrieval
- **Startup Scripts** - Instance initialization and configuration

### 🔧 Quick Deploy

```bash
# 1. Request T4 GPU quota (if needed)
# Go to: https://console.cloud.google.com/iam-admin/quotas
# Search: "NVIDIA T4 GPUs" in us-central1
# Request: 1 GPU

# 2. Deploy
cd VoiceControlAgent/deployment/gcp
./deploy.sh

# 3. Access
# Get IP: gcloud compute instances describe persona-plex-gpu --zone=us-central1-a --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
# Visit: http://EXTERNAL_IP:8998

# 4. Stop when done (save credits)
gcloud compute instances stop persona-plex-gpu --zone=us-central1-a
```

#### Alternative: Terraform

```bash
cd deployment/gcp
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Add your GCP project ID

terraform init
terraform plan
terraform apply
```

### 📋 Prerequisites

1. **GCP Account** with billing enabled (free credits work)
2. **GPU Quota** - Request T4 quota in us-central1 ([Instructions](https://console.cloud.google.com/iam-admin/quotas))
3. **gcloud CLI** - [Install Guide](https://cloud.google.com/sdk/docs/install)

### 💰 Cost Optimization

- **T4 GPU**: ~$0.67/hour — $300 free credits give ~18 days of 24/7 usage
- **Stop when idle**: `gcloud compute instances stop persona-plex-gpu --zone=us-central1-a`
- **Budget Option**: Use preemptible instances for development

### 🛠️ Features

- ✅ **One-Command Deploy**: Run `./deploy.sh` and you're live in ~20 minutes
- ✅ **Multiple Deployment Options**: deploy.sh, Terraform, gcloud CLI, Docker
- ✅ **Default VPC**: No custom networking permissions required
- ✅ **Cost-Optimized**: T4 GPU for MVP, easy upgrade path to A100 later
- ✅ **Well-Documented**: Comprehensive guides and quick reference

### 🔐 Security

- Service account with minimal permissions
- Firewall rules for controlled access
- OS Login enabled

### 📊 Monitoring

- Real-time GPU metrics (`nvidia-smi`)
- GCP Cloud Logging integration

### 🤝 Contributing

Contributions welcome! Please see the deployment documentation for details.

### 📄 License

See [LICENSE](LICENSE) file for details.

### 🔗 Resources

- [NVIDIA Persona Plex Research](https://research.nvidia.com/labs/adlr/personaplex/)
- [GCP Compute Pricing](https://cloud.google.com/compute/all-pricing)
- [Hugging Face Models](https://huggingface.co/nvidia)

---

**Ready to deploy?** Start with the [Deployment Guide](docs/DEPLOYMENT_GUIDE.md)!
