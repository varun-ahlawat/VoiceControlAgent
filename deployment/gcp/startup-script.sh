#!/bin/bash
# Startup script for Persona Plex GPU instance
# This script runs when the instance first boots

set -e

LOG_FILE="/var/log/persona-plex-startup.log"
exec > >(tee -a ${LOG_FILE})
exec 2>&1

echo "==================================="
echo "Persona Plex Instance Startup"
echo "Started at: $(date)"
echo "==================================="

# Update system
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install essential packages
echo "Installing essential packages..."
apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    vim \
    htop \
    tmux \
    python3-pip \
    python3-dev \
    python3-venv \
    libsndfile1 \
    ffmpeg \
    docker.io \
    docker-compose

# Install NVIDIA Container Toolkit
echo "Installing NVIDIA Container Toolkit..."
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
    && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

apt-get update
apt-get install -y nvidia-container-toolkit
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

# Verify GPU
echo "Verifying GPU availability..."
nvidia-smi

# Create working directory
echo "Setting up working directories..."
mkdir -p /opt/persona-plex
mkdir -p /opt/persona-plex/models
mkdir -p /opt/persona-plex/logs
mkdir -p /opt/persona-plex/data

# Set permissions
chmod 755 /opt/persona-plex

# Install Python dependencies (basic setup)
echo "Installing Python packages..."
pip3 install --upgrade pip setuptools wheel

# Create systemd service for auto-start (placeholder)
cat > /etc/systemd/system/persona-plex.service <<'EOF'
[Unit]
Description=Persona Plex Voice AI Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/persona-plex
ExecStart=/opt/persona-plex/start.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

echo "==================================="
echo "Startup script completed successfully"
echo "Completed at: $(date)"
echo "==================================="
echo ""
echo "Next steps:"
echo "1. SSH into the instance: gcloud compute ssh <instance-name> --zone=<zone>"
echo "2. Run the setup script: /opt/persona-plex/setup.sh"
echo "3. Download model weights from Hugging Face"
echo ""
