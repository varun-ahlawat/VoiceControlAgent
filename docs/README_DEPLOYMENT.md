# Persona Plex GCP Deployment - Complete Setup

This repository provides a complete, production-ready setup for deploying NVIDIA's **Persona Plex** on Google Cloud Platform (GCP) with optimal GPU instances.

## What is Persona Plex?

Persona Plex is NVIDIA's advanced multimodal conversational AI model designed for **full-duplex voice interactions**. It enables:

- ✅ Real-time bidirectional voice communication (full duplex)
- ✅ Complex reasoning and tool use capabilities
- ✅ State management for agentic behavior
- ✅ Natural, human-like voice interactions

This project extends Persona Plex with agentic capabilities and provides deployment infrastructure for GCP.

## 📋 What This Repository Provides

### 1. **Simplified Deployment for MVP**
- One-command deploy with `deploy.sh`
- Uses default VPC (no custom network permissions needed)
- NVIDIA T4 GPU — cost-effective for MVP with GCP free credits
- Easy upgrade path to A100 for production

### 2. **Complete Deployment Infrastructure**
- **deploy.sh**: One-command deployment (recommended)
- **Terraform**: Infrastructure as Code for reproducible deployments
- **gcloud Scripts**: Alternative deployment using gcloud CLI
- **Docker**: Containerized deployment with GPU support
- **Startup Scripts**: Automated instance configuration

### 3. **Setup and Configuration**
- Python environment setup with all dependencies
- Model download scripts with Hugging Face integration
- GPU driver installation and verification

### 4. **Comprehensive Documentation**
- Step-by-step deployment guide
- Troubleshooting guide
- Cost optimization tips
- Scaling recommendations

## 🚀 Quick Start

### Prerequisites

1. **GCP Account** with billing enabled (free credits work)
2. **GPU Quota** for T4 ([Request here](https://console.cloud.google.com/iam-admin/quotas))
3. **gcloud CLI** ([Install](https://cloud.google.com/sdk/docs/install))

### Deployment Steps

#### Recommended: deploy.sh

```bash
# 1. Clone repository
git clone https://github.com/varun-ahlawat/VoiceControlAgent.git
cd VoiceControlAgent

# 2. Deploy with single command
cd deployment/gcp
./deploy.sh

# 3. Access
# Get IP: gcloud compute instances describe persona-plex-gpu --zone=us-central1-a --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
# Visit: http://EXTERNAL_IP:8998

# 4. Stop when done (save credits)
gcloud compute instances stop persona-plex-gpu --zone=us-central1-a
```

#### Alternative: Terraform

```bash
# 1. Clone repository
git clone https://github.com/varun-ahlawat/VoiceControlAgent.git
cd VoiceControlAgent

# 2. Configure deployment
cd deployment/gcp
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Add your GCP project ID

# 3. Deploy infrastructure
terraform init
terraform plan
terraform apply

# 4. Connect to instance
gcloud compute ssh persona-plex-gpu --zone=us-central1-a
```

#### Alternative: gcloud CLI

```bash
# 1. Clone repository
git clone https://github.com/varun-ahlawat/VoiceControlAgent.git
cd VoiceControlAgent

# 2. Deploy with single command
cd deployment/gcp
./gcloud-deploy.sh YOUR_PROJECT_ID
```

### Post-Deployment

```bash
# SSH into instance
gcloud compute ssh persona-plex-gpu --zone=us-central1-a

# Verify GPU
nvidia-smi

# Test PyTorch CUDA
python3 -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
```

## 📊 Instance Recommendations

### MVP (Default)

```
Instance: n1-standard-4 + NVIDIA T4 (16GB)
- vCPUs: 4
- RAM: 15 GB
- GPU: 1x T4 (16GB VRAM)
- Storage: 200 GB SSD
- Network: Default VPC
- Cost: ~$0.67/hour (~$489/month)
- With $300 free credits: ~18 days of 24/7 usage
```

### Production (Upgrade)

```
Instance: n1-standard-8 + NVIDIA A100 (40GB)
- vCPUs: 8
- RAM: 30 GB
- GPU: 1x A100 (40GB VRAM)
- Storage: 500 GB SSD
- Cost: ~$2.95/hour (~$2,150/month)
- With commitment: ~$1,400/month (save 35%)
```

See [PERSONA_PLEX_GCP_SETUP.md](docs/PERSONA_PLEX_GCP_SETUP.md) for detailed analysis.

## 📁 Repository Structure

```
VoiceControlAgent/
├── deployment/
│   └── gcp/
│       ├── deploy.sh                  # One-command deployment (recommended)
│       ├── main.tf                    # Terraform main configuration
│       ├── terraform.tfvars.example   # Example variables
│       ├── startup-script.sh          # Instance initialization
│       ├── Dockerfile                 # Container image
│       ├── docker-compose.yml         # Container deployment
│       ├── gcloud-deploy.sh          # gcloud deployment script
│       ├── gcloud-cleanup.sh         # Resource cleanup script
│       └── README.md                  # Deployment README
├── scripts/
│   ├── setup.sh                      # Environment setup
│   └── download_models.sh            # Model download script
└── docs/
    ├── PERSONA_PLEX_GCP_SETUP.md     # Instance recommendations
    └── DEPLOYMENT_GUIDE.md           # Complete deployment guide
```

## 📚 Documentation

- **[Persona Plex GCP Setup](docs/PERSONA_PLEX_GCP_SETUP.md)** - Detailed instance type analysis and recommendations
- **[Deployment Guide](docs/DEPLOYMENT_GUIDE.md)** - Complete step-by-step deployment walkthrough
- **[GCP Deployment README](deployment/gcp/README.md)** - Quick reference for deployment files

## 🔧 Model Download

Persona Plex models are hosted on Hugging Face. You may need:

1. **Hugging Face Account** ([Sign up](https://huggingface.co/join))
2. **Access Token** ([Create token](https://huggingface.co/settings/tokens))
3. **Model Access** - Request access if the model is gated

### Download Options

**Option 1: Interactive Script**
```bash
sudo bash /opt/persona-plex/scripts/download_models.sh
```

**Option 2: Manual Download**
```bash
# Login to Hugging Face
huggingface-cli login

# Download model
huggingface-cli download nvidia/Persona-Plex \
    --local-dir /opt/persona-plex/models/persona-plex
```

**Option 3: From Google Cloud Storage**
```bash
# If you have model in GCS
gsutil -m cp -r gs://your-bucket/persona-plex/* \
    /opt/persona-plex/models/persona-plex/
```

## 💰 Cost Estimation

### Monthly Costs (24/7 Operation)

| Configuration | Compute | Storage | Network | Total/Month |
|--------------|---------|---------|---------|-------------|
| **T4 (Default/MVP)** | $489 | $34 | $20 | **$543** |
| A100 (On-Demand) | $2,153 | $85 | $50 | **$2,288** |
| A100 (1-year commit) | $1,327 | $85 | $50 | **$1,462** |

### Cost Optimization Tips

1. **Stop when idle**: Most important — stop the instance when not in use
2. **$300 free credits**: T4 at ~$0.67/hour = ~18 days of 24/7 usage
3. **Preemptible Instances**: Save 60-70% for development (use in terraform with `preemptible = true`)
4. **Regional Selection**: Some regions are cheaper (check current pricing)

## 🔍 Monitoring

### GPU Monitoring
```bash
# Real-time GPU stats
watch -n 1 nvidia-smi

# Detailed monitoring
nvidia-smi dmon -s pucvmet
```

### Application Monitoring

For MVP, use `nvidia-smi` and GCP Cloud Logging. Prometheus and Grafana can be added later by extending `docker-compose.yml`.

## 🛠️ Troubleshooting

### GPU Not Detected
```bash
# Verify driver
nvidia-smi

# Reinstall if needed
sudo apt-get update
sudo apt-get install -y nvidia-driver-525
sudo reboot
```

### CUDA Out of Memory
- Reduce batch size
- Use model quantization (INT8)
- Upgrade to A100 80GB

```python
# Load with 8-bit quantization
model = AutoModelForCausalLM.from_pretrained(
    "nvidia/Persona-Plex",
    load_in_8bit=True,
    device_map="auto"
)
```

### Model Download Issues
```bash
# Check authentication
huggingface-cli whoami

# Re-authenticate
huggingface-cli login

# Resume download
huggingface-cli download nvidia/Persona-Plex \
    --local-dir /opt/persona-plex/models/persona-plex \
    --resume-download
```

See [Deployment Guide](docs/DEPLOYMENT_GUIDE.md) for more troubleshooting tips.

## 🔒 Security Best Practices

1. **Restrict SSH Access**
   ```bash
   gcloud compute firewall-rules update persona-plex-allow-ssh \
       --source-ranges=YOUR_IP/32
   ```

2. **Use Secret Manager**
   ```bash
   gcloud secrets create hf-token --data-file=-
   ```

3. **Enable OS Login**
   ```bash
   gcloud compute instances add-metadata persona-plex-gpu \
       --metadata enable-oslogin=TRUE
   ```

4. **Regular Updates**
   ```bash
   sudo apt-get update && sudo apt-get upgrade -y
   ```

## 📈 Scaling

### Horizontal Scaling (Multiple Instances)
- Use GCP Load Balancer
- Deploy multiple instances
- Share state via Cloud SQL or Redis

### Vertical Scaling (Bigger Instance)
```bash
# Stop instance
gcloud compute instances stop persona-plex-gpu --zone=us-central1-a

# Change machine type
gcloud compute instances set-machine-type persona-plex-gpu \
    --machine-type=a2-highgpu-1g --zone=us-central1-a

# Start instance
gcloud compute instances start persona-plex-gpu --zone=us-central1-a
```

## 🧹 Cleanup

To remove all deployed resources:

### With Terraform:
```bash
cd deployment/gcp
terraform destroy
```

### With gcloud:
```bash
cd deployment/gcp
./gcloud-cleanup.sh YOUR_PROJECT_ID
```

⚠️ **Warning**: This deletes all resources including the instance and data. Backup important data first!

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

See [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **NVIDIA** for Persona Plex model
- **Google Cloud Platform** for infrastructure
- **Hugging Face** for model hosting

## 📞 Support

For issues or questions:
1. Check the [Deployment Guide](docs/DEPLOYMENT_GUIDE.md)
2. Review [Troubleshooting Section](#troubleshooting)
3. Open an issue on GitHub
4. Check GCP documentation

## 🔗 Useful Links

- [NVIDIA Persona Plex Research](https://research.nvidia.com/labs/adlr/personaplex/)
- [GCP Compute Engine Pricing](https://cloud.google.com/compute/all-pricing)
- [GCP GPU Quota Request](https://console.cloud.google.com/iam-admin/quotas)
- [Hugging Face Models](https://huggingface.co/nvidia)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

---

**Ready to deploy Persona Plex on GCP?** Start with the [Quick Start](#-quick-start) section above!
