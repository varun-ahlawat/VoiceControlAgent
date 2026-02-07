#!/bin/bash
# Setup script for Persona Plex on GCP instance
# Run this after the instance is created and you've SSH'd into it

set -e

WORK_DIR="/opt/persona-plex"
MODEL_DIR="${WORK_DIR}/models"
VENV_DIR="${WORK_DIR}/venv"

echo "===================================="
echo "Persona Plex Setup Script"
echo "===================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (sudo)"
    exit 1
fi

# Verify GPU
echo "Verifying GPU..."
if ! command -v nvidia-smi &> /dev/null; then
    echo "ERROR: NVIDIA drivers not found. Please check your instance configuration."
    exit 1
fi

nvidia-smi
echo ""

# Create Python virtual environment
echo "Creating Python virtual environment..."
cd ${WORK_DIR}
python3 -m venv ${VENV_DIR}
source ${VENV_DIR}/bin/activate

# Upgrade pip
pip install --upgrade pip setuptools wheel

# Install PyTorch with CUDA support
echo "Installing PyTorch with CUDA 12.1..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install Transformers and related packages
echo "Installing Hugging Face libraries..."
pip install transformers>=4.35.0
pip install accelerate>=0.25.0
pip install bitsandbytes>=0.41.0
pip install sentencepiece
pip install protobuf

# Install audio processing libraries
echo "Installing audio processing libraries..."
pip install librosa
pip install soundfile
pip install pyaudio
pip install webrtcvad
pip install pydub

# Install API and server frameworks
echo "Installing server frameworks..."
pip install fastapi
pip install uvicorn[standard]
pip install websockets
pip install pydantic
pip install python-multipart

# Install utilities
echo "Installing utilities..."
pip install requests
pip install aiohttp
pip install python-dotenv
pip install pyyaml
pip install tqdm

# Install monitoring and logging
pip install prometheus-client
pip install python-json-logger

# Test PyTorch CUDA availability
echo ""
echo "Testing PyTorch CUDA availability..."
python3 << 'PYEOF'
import torch
print(f"PyTorch version: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"CUDA version: {torch.version.cuda}")
    print(f"GPU Name: {torch.cuda.get_device_name(0)}")
    print(f"GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.2f} GB")
else:
    print("WARNING: CUDA is not available!")
PYEOF

echo ""
echo "===================================="
echo "Setup completed successfully!"
echo "===================================="
echo ""
echo "Next steps:"
echo "1. Download Persona Plex weights: ./download_models.sh"
echo "2. Configure environment: cp .env.example .env && nano .env"
echo "3. Start the service: systemctl start persona-plex"
echo ""
echo "Virtual environment is at: ${VENV_DIR}"
echo "To activate: source ${VENV_DIR}/bin/activate"
echo ""
