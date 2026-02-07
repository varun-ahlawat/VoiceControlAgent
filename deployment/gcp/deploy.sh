#!/bin/bash
# deploy.sh - One-command deployment for Persona Plex on GCP Compute Engine with T4 GPU
#
# Usage:
#   ./deploy.sh                     # Interactive: prompts for project ID
#   ./deploy.sh my-gcp-project-id   # Non-interactive: uses provided project ID
#
# Prerequisites:
#   - gcloud CLI installed and authenticated (gcloud auth login)
#   - NVIDIA T4 GPU quota in us-central1 (request at https://console.cloud.google.com/iam-admin/quotas)

set -e

# Configuration
INSTANCE_NAME="persona-plex-gpu"
ZONE="us-central1-a"
REGION="us-central1"
MACHINE_TYPE="n1-standard-4"
GPU_TYPE="nvidia-tesla-t4"
GPU_COUNT=1
DISK_SIZE=200

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Persona Plex - GCP T4 GPU Deployment   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# Get project ID
PROJECT_ID="${1:-}"
if [ -z "$PROJECT_ID" ]; then
    read -p "Enter your GCP Project ID: " PROJECT_ID
    if [ -z "$PROJECT_ID" ]; then
        echo -e "${RED}Error: Project ID is required${NC}"
        exit 1
    fi
fi

# Verify gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI not found${NC}"
    echo "Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Verify authentication
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | head -1 | grep -q '.'; then
    echo -e "${RED}Error: Not authenticated with gcloud${NC}"
    echo "Run: gcloud auth login"
    exit 1
fi

echo -e "${GREEN}Configuration:${NC}"
echo "  Project:      ${PROJECT_ID}"
echo "  Instance:     ${INSTANCE_NAME}"
echo "  Zone:         ${ZONE}"
echo "  Machine:      ${MACHINE_TYPE}"
echo "  GPU:          ${GPU_TYPE} x${GPU_COUNT}"
echo "  Disk:         ${DISK_SIZE} GB SSD"
echo "  Cost:         ~\$0.67/hour (T4 GPU)"
echo ""

read -p "Proceed with deployment? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

echo ""

# Step 1: Set project
echo -e "${YELLOW}[1/7] Setting GCP project...${NC}"
gcloud config set project ${PROJECT_ID} 2>/dev/null
echo -e "${GREEN}✓ Project set${NC}"

# Step 2: Enable required APIs
echo -e "${YELLOW}[2/7] Enabling required APIs...${NC}"
gcloud services enable compute.googleapis.com 2>/dev/null
gcloud services enable storage.googleapis.com 2>/dev/null
gcloud services enable logging.googleapis.com 2>/dev/null
echo -e "${GREEN}✓ APIs enabled${NC}"

# Step 3: Create firewall rules (using default VPC)
echo -e "${YELLOW}[3/7] Configuring firewall rules...${NC}"

if ! gcloud compute firewall-rules describe persona-plex-allow-ssh &> /dev/null; then
    gcloud compute firewall-rules create persona-plex-allow-ssh \
        --network=default \
        --allow=tcp:22 \
        --source-ranges=0.0.0.0/0 \
        --target-tags=persona-plex \
        --quiet 2>/dev/null
fi

if ! gcloud compute firewall-rules describe persona-plex-allow-http &> /dev/null; then
    gcloud compute firewall-rules create persona-plex-allow-http \
        --network=default \
        --allow=tcp:80,tcp:443,tcp:8000,tcp:8080,tcp:8998 \
        --source-ranges=0.0.0.0/0 \
        --target-tags=persona-plex \
        --quiet 2>/dev/null
fi

if ! gcloud compute firewall-rules describe persona-plex-allow-websocket &> /dev/null; then
    gcloud compute firewall-rules create persona-plex-allow-websocket \
        --network=default \
        --allow=tcp:8765,tcp:9000 \
        --source-ranges=0.0.0.0/0 \
        --target-tags=persona-plex \
        --quiet 2>/dev/null
fi

echo -e "${GREEN}✓ Firewall rules configured${NC}"

# Step 4: Create service account
echo -e "${YELLOW}[4/7] Setting up service account...${NC}"
SA_NAME="persona-plex-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

if ! gcloud iam service-accounts describe ${SA_EMAIL} &> /dev/null 2>&1; then
    gcloud iam service-accounts create ${SA_NAME} \
        --display-name="Persona Plex Service Account" \
        --quiet 2>/dev/null
fi

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/storage.objectViewer" \
    --condition=None --quiet &> /dev/null

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/logging.logWriter" \
    --condition=None --quiet &> /dev/null

echo -e "${GREEN}✓ Service account configured${NC}"

# Step 5: Reserve static IP
echo -e "${YELLOW}[5/7] Reserving static IP...${NC}"
if ! gcloud compute addresses describe persona-plex-static-ip --region=${REGION} &> /dev/null 2>&1; then
    gcloud compute addresses create persona-plex-static-ip \
        --region=${REGION} --quiet 2>/dev/null
fi

STATIC_IP=$(gcloud compute addresses describe persona-plex-static-ip --region=${REGION} --format='get(address)')
echo -e "${GREEN}✓ Static IP: ${STATIC_IP}${NC}"

# Step 6: Create GPU instance
echo -e "${YELLOW}[6/7] Creating GPU instance (this takes 3-5 minutes)...${NC}"

if gcloud compute instances describe ${INSTANCE_NAME} --zone=${ZONE} &> /dev/null 2>&1; then
    echo -e "${YELLOW}  Instance already exists, skipping creation${NC}"
else
    gcloud compute instances create ${INSTANCE_NAME} \
        --zone=${ZONE} \
        --machine-type=${MACHINE_TYPE} \
        --network-interface=network=default,address=${STATIC_IP} \
        --maintenance-policy=TERMINATE \
        --provisioning-model=STANDARD \
        --service-account=${SA_EMAIL} \
        --scopes=https://www.googleapis.com/auth/cloud-platform \
        --tags=persona-plex,gpu-instance \
        --create-disk=auto-delete=yes,boot=yes,device-name=${INSTANCE_NAME},image-family=common-cu121-debian-11-py310,image-project=ml-images,mode=rw,size=${DISK_SIZE},type=pd-ssd \
        --accelerator=type=${GPU_TYPE},count=${GPU_COUNT} \
        --metadata=enable-oslogin=TRUE \
        --labels=environment=prod,purpose=persona-plex,managed-by=deploy-sh \
        --quiet
    echo -e "${GREEN}✓ Instance created${NC}"
fi

# Step 7: Wait for instance
echo -e "${YELLOW}[7/7] Waiting for instance to be ready...${NC}"
sleep 15
STATUS=$(gcloud compute instances describe ${INSTANCE_NAME} --zone=${ZONE} --format='get(status)' 2>/dev/null)
echo -e "${GREEN}✓ Instance status: ${STATUS}${NC}"

# Done!
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║       Deployment Complete!                ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BLUE}External IP:${NC}  ${STATIC_IP}"
echo -e "  ${BLUE}Instance:${NC}     ${INSTANCE_NAME}"
echo -e "  ${BLUE}Zone:${NC}         ${ZONE}"
echo -e "  ${BLUE}GPU:${NC}          NVIDIA T4 (16GB)"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "  1. SSH into the instance:"
echo "     gcloud compute ssh ${INSTANCE_NAME} --zone=${ZONE}"
echo ""
echo "  2. Access the application:"
echo "     http://${STATIC_IP}:8998"
echo ""
echo "  3. Stop when done (save credits):"
echo "     gcloud compute instances stop ${INSTANCE_NAME} --zone=${ZONE}"
echo ""
echo "  4. Cleanup all resources:"
echo "     ./gcloud-cleanup.sh ${PROJECT_ID}"
echo ""
