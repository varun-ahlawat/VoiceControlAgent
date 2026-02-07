# VoiceControlAgent

World's first full duplex agentic voice layer for AI agents, that can do complex tool use. This includes a coupled state management system built on NVIDIA's open-source model called Persona Plex. Out of the box, Persona Plex lacks agentic capabilities, which this project provides.

## 🚀 Quick Start - GCP Deployment

This repository includes a **complete, production-ready deployment setup** for hosting Persona Plex on Google Cloud Platform with optimized GPU instances.

### 📖 Documentation

- **[GCP Deployment Guide](docs/DEPLOYMENT_GUIDE.md)** - Complete step-by-step deployment walkthrough
- **[Instance Recommendations](docs/PERSONA_PLEX_GCP_SETUP.md)** - Detailed analysis of GCP instance types and costs
- **[Deployment Summary](docs/DEPLOYMENT_SUMMARY.md)** - Complete review of all deliverables
- **[Quick Start README](docs/README_DEPLOYMENT.md)** - High-level overview

### 🎯 Recommended Setup

**Production Configuration:**
- **Instance**: n1-standard-8 (8 vCPUs, 30 GB RAM)
- **GPU**: 1x NVIDIA A100 (40GB VRAM)
- **Storage**: 500 GB SSD
- **Cost**: ~$2.95/hour (~$2,150/month on-demand, ~$1,400/month with 1-year commitment)

**Why A100?**
- ✅ 40GB VRAM perfect for 7B-13B parameter models
- ✅ 312 TFLOPS FP16 performance for real-time inference
- ✅ Low latency (<200ms) for natural voice interaction
- ✅ Future-proof for model upgrades

### 📦 What's Included

#### Infrastructure as Code
- **Terraform Configuration** - Complete GCP infrastructure setup
- **gcloud Scripts** - Alternative CLI-based deployment
- **Docker Setup** - Containerized deployment with GPU support

#### Automated Setup
- **Environment Setup Script** - Installs PyTorch, CUDA, and all dependencies
- **Model Download Script** - Automated Hugging Face model retrieval
- **Startup Scripts** - Instance initialization and configuration

#### Monitoring & Operations
- **Prometheus** - Metrics collection and alerting
- **Grafana** - Visualization dashboards
- **Logging** - Integrated with GCP Cloud Logging

### 🔧 Quick Deploy

#### Option 1: Terraform (Recommended)

```bash
# 1. Clone and configure
git clone https://github.com/varun-ahlawat/VoiceControlAgent.git
cd VoiceControlAgent/deployment/gcp
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Add your GCP project ID

# 2. Deploy infrastructure
terraform init
terraform plan
terraform apply

# 3. Connect and setup
gcloud compute ssh persona-plex-gpu --zone=us-central1-a
sudo bash /opt/persona-plex/setup.sh
sudo bash /opt/persona-plex/scripts/download_models.sh
```

#### Option 2: gcloud CLI

```bash
# One-command deployment
cd deployment/gcp
./gcloud-deploy.sh YOUR_PROJECT_ID
```

### 📋 Prerequisites

1. **GCP Account** with billing enabled
2. **GPU Quota** - Request A100 or T4 quota ([Instructions](https://console.cloud.google.com/iam-admin/quotas))
3. **gcloud CLI** - [Install Guide](https://cloud.google.com/sdk/docs/install)
4. **Hugging Face Token** - [Create Token](https://huggingface.co/settings/tokens)

### 💰 Cost Optimization

- **Committed Use**: Save 35-55% with 1-3 year commitments
- **Budget Option**: Use T4 GPU (~$700/month) for development
- **Auto-Shutdown**: Script included for off-hours shutdown
- **Preemptible**: Available for non-production workloads

### 🛠️ Features

- ✅ **Multiple Deployment Options**: Terraform, gcloud CLI, Docker
- ✅ **Production-Ready**: Proper networking, security, and monitoring
- ✅ **Automated Setup**: One-command deployment and configuration
- ✅ **Cost-Optimized**: Detailed cost analysis and optimization tips
- ✅ **Well-Documented**: 20+ pages of comprehensive guides
- ✅ **Scalable**: Horizontal and vertical scaling strategies included

### 🔐 Security

- Service account with minimal permissions
- Firewall rules for controlled access
- VPC networking for isolation
- Secret management integration
- OS Login enabled

### 📊 Monitoring

- Real-time GPU metrics (`nvidia-smi`)
- Prometheus metrics collection
- Grafana visualization dashboards
- GCP Cloud Logging integration
- Custom alerting support

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
