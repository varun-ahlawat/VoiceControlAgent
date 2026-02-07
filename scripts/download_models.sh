#!/bin/bash
# Script to download Persona Plex model weights from Hugging Face
# This script requires authentication if the model is gated

set -e

MODEL_DIR="/opt/persona-plex/models"
VENV_DIR="/opt/persona-plex/venv"

echo "===================================="
echo "Persona Plex Model Download Script"
echo "===================================="
echo ""

# Check if virtual environment exists
if [ ! -d "${VENV_DIR}" ]; then
    echo "ERROR: Virtual environment not found at ${VENV_DIR}"
    echo "Please run setup.sh first"
    exit 1
fi

# Activate virtual environment
source ${VENV_DIR}/bin/activate

# Check if huggingface-cli is installed
if ! command -v huggingface-cli &> /dev/null; then
    echo "Installing Hugging Face CLI..."
    pip install huggingface-hub[cli]
fi

echo ""
echo "Model download requires authentication with Hugging Face."
echo ""
echo "Options:"
echo "1. Login with Hugging Face token"
echo "2. Use environment variable HF_TOKEN"
echo "3. Skip authentication (for public models)"
echo ""
read -p "Choose option (1/2/3): " auth_option

case $auth_option in
    1)
        echo ""
        echo "Please enter your Hugging Face token:"
        echo "(Get it from: https://huggingface.co/settings/tokens)"
        huggingface-cli login
        ;;
    2)
        if [ -z "$HF_TOKEN" ]; then
            echo "ERROR: HF_TOKEN environment variable not set"
            exit 1
        fi
        echo "Using HF_TOKEN from environment"
        ;;
    3)
        echo "Skipping authentication (attempting public download)"
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

echo ""
echo "Downloading Persona Plex model..."
echo "This may take 30-60 minutes depending on your connection."
echo ""

# Create model directory
mkdir -p ${MODEL_DIR}

# Download the model
# Note: Update the model repository name when the official one is available
# For now, this is a placeholder

REPO_NAME="nvidia/Persona-Plex"

echo "Downloading from: ${REPO_NAME}"
echo "Target directory: ${MODEL_DIR}/persona-plex"
echo ""

# Use huggingface-hub to download
python3 << 'PYEOF'
import os
from huggingface_hub import snapshot_download
import sys

repo_id = "nvidia/Persona-Plex"  # Update this with the actual repo
local_dir = "/opt/persona-plex/models/persona-plex"

print(f"Downloading model: {repo_id}")
print(f"Target directory: {local_dir}")
print("")

try:
    # Try to download the model
    snapshot_download(
        repo_id=repo_id,
        local_dir=local_dir,
        local_dir_use_symlinks=False,
        resume_download=True
    )
    print("")
    print("✓ Model downloaded successfully!")
    
except Exception as e:
    print("")
    print("=" * 60)
    print("DOWNLOAD FAILED - This is expected if the model is not yet public")
    print("=" * 60)
    print("")
    print(f"Error: {e}")
    print("")
    print("Next steps:")
    print("1. Check if the model repository exists at:")
    print(f"   https://huggingface.co/{repo_id}")
    print("")
    print("2. If the model requires access:")
    print("   - Request access on the model page")
    print("   - Login with: huggingface-cli login")
    print("   - Run this script again")
    print("")
    print("3. If the repository name is different:")
    print("   - Edit this script and update REPO_NAME")
    print("   - Or manually download with:")
    print(f"     huggingface-cli download {repo_id} --local-dir {local_dir}")
    print("")
    print("4. For manual download:")
    print(f"   - Place model files in: {local_dir}")
    print("")
    sys.exit(1)

PYEOF

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "===================================="
    echo "Model downloaded successfully!"
    echo "===================================="
    echo ""
    echo "Model location: ${MODEL_DIR}/persona-plex"
    echo ""
    echo "Next steps:"
    echo "1. Verify model files: ls -lh ${MODEL_DIR}/persona-plex"
    echo "2. Start the service: systemctl start persona-plex"
    echo ""
else
    echo ""
    echo "===================================="
    echo "Download encountered an issue"
    echo "===================================="
    echo ""
    echo "Please follow the instructions above to complete the download."
    echo ""
    echo "Alternative: Download manually using Hugging Face CLI"
    echo "Command: huggingface-cli download nvidia/Persona-Plex --local-dir ${MODEL_DIR}/persona-plex"
    echo ""
    exit 1
fi
