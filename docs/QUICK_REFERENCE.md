# Quick Reference Guide - Persona Plex GCP Deployment

## One-Page Reference for Common Tasks

### Initial Deployment

```bash
# Recommended: One-command deploy
cd deployment/gcp
./deploy.sh

# Alternative: Terraform
cd deployment/gcp
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply

# Alternative: gcloud CLI
cd deployment/gcp
./gcloud-deploy.sh YOUR_PROJECT_ID
```

### Connect to Instance

```bash
gcloud compute ssh persona-plex-gpu --zone=us-central1-a
```

### Setup Instance

```bash
sudo bash /opt/persona-plex/setup.sh
```

### Download Model

```bash
# Interactive
sudo bash /opt/persona-plex/scripts/download_models.sh

# Manual
huggingface-cli login
huggingface-cli download nvidia/Persona-Plex --local-dir /opt/persona-plex/models/persona-plex
```

### GPU Monitoring

```bash
# Watch GPU usage
watch -n 1 nvidia-smi

# Detailed stats
nvidia-smi dmon -s pucvmet
```

### Check Status

```bash
# GPU
nvidia-smi

# PyTorch CUDA
python3 -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"

# Disk space
df -h

# Memory
free -h

# Processes
htop
```

### Docker Deployment

```bash
cd deployment/gcp

# Build
docker build -t persona-plex:latest .

# Run
docker-compose up -d

# Logs
docker-compose logs -f persona-plex

# Stop
docker-compose down
```

### Cost Management

```bash
# Stop instance (when not in use)
gcloud compute instances stop persona-plex-gpu --zone=us-central1-a

# Start instance
gcloud compute instances start persona-plex-gpu --zone=us-central1-a

# Check current cost
gcloud billing accounts list
```

### Security

```bash
# Restrict SSH to your IP
gcloud compute firewall-rules update persona-plex-allow-ssh \
    --source-ranges=YOUR_IP/32

# Store secrets
gcloud secrets create hf-token --data-file=-

# Enable OS login
gcloud compute instances add-metadata persona-plex-gpu \
    --metadata enable-oslogin=TRUE
```

### Troubleshooting

```bash
# View startup logs
gcloud compute instances get-serial-port-output persona-plex-gpu --zone=us-central1-a

# SSH with logs
gcloud compute ssh persona-plex-gpu --zone=us-central1-a --ssh-flag="-vvv"

# Check systemd services
systemctl status persona-plex

# View logs
journalctl -u persona-plex -f
```

### Cleanup

```bash
# Terraform
cd deployment/gcp
terraform destroy

# gcloud
cd deployment/gcp
./gcloud-cleanup.sh YOUR_PROJECT_ID
```

### Common Issues

**GPU Not Detected**
```bash
sudo apt-get update
sudo apt-get install -y nvidia-driver-525
sudo reboot
```

**Out of Memory**
```python
# Use quantization
model = AutoModelForCausalLM.from_pretrained(
    "nvidia/Persona-Plex",
    load_in_8bit=True,
    device_map="auto"
)
```

**Model Download Fails**
```bash
# Re-authenticate
huggingface-cli login
# Resume download
huggingface-cli download nvidia/Persona-Plex --resume-download
```

### Useful Commands

```bash
# Get instance IP
gcloud compute instances describe persona-plex-gpu \
    --zone=us-central1-a \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)'

# Copy files to instance
gcloud compute scp LOCAL_FILE persona-plex-gpu:~/REMOTE_PATH --zone=us-central1-a

# Copy files from instance
gcloud compute scp persona-plex-gpu:~/REMOTE_FILE ./LOCAL_PATH --zone=us-central1-a
```

### Instance Types Quick Reference

| Instance | vCPU | RAM | GPU | VRAM | Cost/hr | Use Case |
|----------|------|-----|-----|------|---------|----------|
| n1-standard-4 + T4 | 4 | 15GB | T4 | 16GB | $0.67 | **MVP (Default)** |
| n1-standard-8 + A100 | 8 | 30GB | A100 | 40GB | $2.95 | Production |
| a2-highgpu-1g | 12 | 85GB | A100 | 80GB | $3.67 | High-Performance |

### Environment Variables

```bash
# Essential
export HF_TOKEN="your_token"
export MODEL_PATH="/opt/persona-plex/models/persona-plex"
export CUDA_VISIBLE_DEVICES=0

# Performance
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
export OMP_NUM_THREADS=8
```

### Quick Links

- [Full Deployment Guide](DEPLOYMENT_GUIDE.md)
- [Instance Recommendations](PERSONA_PLEX_GCP_SETUP.md)
- [Deployment Summary](DEPLOYMENT_SUMMARY.md)
- [GCP Console](https://console.cloud.google.com)
- [Hugging Face Tokens](https://huggingface.co/settings/tokens)
