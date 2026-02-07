#!/bin/bash
# gcloud deployment script for Persona Plex
# Alternative to Terraform for those who prefer gcloud CLI

set -e

# Configuration
PROJECT_ID="${1:-}"
INSTANCE_NAME="${2:-persona-plex-gpu}"
ZONE="${3:-us-central1-a}"
REGION="${4:-us-central1}"
MACHINE_TYPE="${5:-n1-standard-8}"
GPU_TYPE="${6:-nvidia-tesla-a100}"
GPU_COUNT="${7:-1}"
DISK_SIZE="${8:-500}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "===================================="
echo "Persona Plex GCP Deployment"
echo "Using gcloud CLI"
echo "===================================="
echo ""

# Check if project ID is provided
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}Error: Project ID not provided${NC}"
    echo ""
    echo "Usage: $0 PROJECT_ID [INSTANCE_NAME] [ZONE] [REGION] [MACHINE_TYPE] [GPU_TYPE] [GPU_COUNT] [DISK_SIZE]"
    echo ""
    echo "Example:"
    echo "  $0 my-gcp-project"
    echo "  $0 my-gcp-project persona-plex-gpu us-central1-a us-central1"
    echo ""
    exit 1
fi

# Verify gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI not found${NC}"
    echo "Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

echo "Configuration:"
echo "  Project ID:    ${PROJECT_ID}"
echo "  Instance Name: ${INSTANCE_NAME}"
echo "  Zone:          ${ZONE}"
echo "  Region:        ${REGION}"
echo "  Machine Type:  ${MACHINE_TYPE}"
echo "  GPU Type:      ${GPU_TYPE}"
echo "  GPU Count:     ${GPU_COUNT}"
echo "  Disk Size:     ${DISK_SIZE} GB"
echo ""

read -p "Proceed with deployment? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

# Set project
echo -e "${YELLOW}Setting GCP project...${NC}"
gcloud config set project ${PROJECT_ID}

# Enable required APIs
echo -e "${YELLOW}Enabling required APIs...${NC}"
gcloud services enable compute.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable logging.googleapis.com
gcloud services enable monitoring.googleapis.com

# Create VPC network
echo -e "${YELLOW}Creating VPC network...${NC}"
if ! gcloud compute networks describe persona-plex-network &> /dev/null; then
    gcloud compute networks create persona-plex-network \
        --subnet-mode=custom \
        --bgp-routing-mode=regional
    echo -e "${GREEN}✓ Network created${NC}"
else
    echo "Network already exists"
fi

# Create subnet
echo -e "${YELLOW}Creating subnet...${NC}"
if ! gcloud compute networks subnets describe persona-plex-subnet --region=${REGION} &> /dev/null; then
    gcloud compute networks subnets create persona-plex-subnet \
        --network=persona-plex-network \
        --region=${REGION} \
        --range=10.0.0.0/24 \
        --enable-flow-logs
    echo -e "${GREEN}✓ Subnet created${NC}"
else
    echo "Subnet already exists"
fi

# Create firewall rules
echo -e "${YELLOW}Creating firewall rules...${NC}"

# SSH
if ! gcloud compute firewall-rules describe persona-plex-allow-ssh &> /dev/null; then
    gcloud compute firewall-rules create persona-plex-allow-ssh \
        --network=persona-plex-network \
        --allow=tcp:22 \
        --source-ranges=0.0.0.0/0 \
        --target-tags=persona-plex
    echo -e "${GREEN}✓ SSH firewall rule created${NC}"
fi

# HTTP/HTTPS
if ! gcloud compute firewall-rules describe persona-plex-allow-http &> /dev/null; then
    gcloud compute firewall-rules create persona-plex-allow-http \
        --network=persona-plex-network \
        --allow=tcp:80,tcp:443,tcp:8000,tcp:8080 \
        --source-ranges=0.0.0.0/0 \
        --target-tags=persona-plex
    echo -e "${GREEN}✓ HTTP firewall rule created${NC}"
fi

# WebSocket/Custom
if ! gcloud compute firewall-rules describe persona-plex-allow-websocket &> /dev/null; then
    gcloud compute firewall-rules create persona-plex-allow-websocket \
        --network=persona-plex-network \
        --allow=tcp:8765,tcp:9000,tcp:9090 \
        --source-ranges=0.0.0.0/0 \
        --target-tags=persona-plex
    echo -e "${GREEN}✓ WebSocket firewall rule created${NC}"
fi

# Create service account
echo -e "${YELLOW}Creating service account...${NC}"
SA_NAME="persona-plex-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

if ! gcloud iam service-accounts describe ${SA_EMAIL} &> /dev/null; then
    gcloud iam service-accounts create ${SA_NAME} \
        --display-name="Persona Plex Service Account" \
        --description="Service account for Persona Plex GPU instance"
    echo -e "${GREEN}✓ Service account created${NC}"
else
    echo "Service account already exists"
fi

# Grant IAM roles
echo -e "${YELLOW}Granting IAM roles...${NC}"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/storage.objectViewer" \
    --condition=None &> /dev/null

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/logging.logWriter" \
    --condition=None &> /dev/null

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/monitoring.metricWriter" \
    --condition=None &> /dev/null

echo -e "${GREEN}✓ IAM roles granted${NC}"

# Reserve static IP
echo -e "${YELLOW}Reserving static IP...${NC}"
if ! gcloud compute addresses describe persona-plex-static-ip --region=${REGION} &> /dev/null; then
    gcloud compute addresses create persona-plex-static-ip \
        --region=${REGION}
    echo -e "${GREEN}✓ Static IP reserved${NC}"
else
    echo "Static IP already exists"
fi

STATIC_IP=$(gcloud compute addresses describe persona-plex-static-ip --region=${REGION} --format='get(address)')
echo "Static IP: ${STATIC_IP}"

# Create GCS bucket for models
echo -e "${YELLOW}Creating GCS bucket...${NC}"
BUCKET_NAME="${PROJECT_ID}-persona-plex-models"
if ! gsutil ls gs://${BUCKET_NAME} &> /dev/null; then
    gsutil mb -l ${REGION} gs://${BUCKET_NAME}
    gsutil versioning set on gs://${BUCKET_NAME}
    echo -e "${GREEN}✓ GCS bucket created${NC}"
else
    echo "Bucket already exists"
fi

# Grant bucket access to service account
gsutil iam ch serviceAccount:${SA_EMAIL}:objectViewer gs://${BUCKET_NAME}

# Create startup script
STARTUP_SCRIPT=$(cat << 'SCRIPT_EOF'
#!/bin/bash
set -e
echo "=== Persona Plex Instance Startup ==="
apt-get update
apt-get install -y python3-pip git curl wget build-essential
# Additional setup handled by user scripts
echo "=== Startup Complete ==="
SCRIPT_EOF
)

# Create the instance
echo -e "${YELLOW}Creating GPU instance (this may take 5-10 minutes)...${NC}"
if gcloud compute instances describe ${INSTANCE_NAME} --zone=${ZONE} &> /dev/null; then
    echo -e "${YELLOW}Instance already exists. Skipping creation.${NC}"
else
    gcloud compute instances create ${INSTANCE_NAME} \
        --zone=${ZONE} \
        --machine-type=${MACHINE_TYPE} \
        --network-interface=subnet=persona-plex-subnet,address=${STATIC_IP} \
        --maintenance-policy=TERMINATE \
        --provisioning-model=STANDARD \
        --service-account=${SA_EMAIL} \
        --scopes=https://www.googleapis.com/auth/cloud-platform \
        --tags=persona-plex,gpu-instance \
        --create-disk=auto-delete=yes,boot=yes,device-name=${INSTANCE_NAME},image-family=common-cu121-debian-11-py310,image-project=ml-images,mode=rw,size=${DISK_SIZE},type=pd-ssd \
        --accelerator=type=${GPU_TYPE},count=${GPU_COUNT} \
        --metadata=enable-oslogin=TRUE \
        --metadata-from-file=startup-script=<(echo "${STARTUP_SCRIPT}") \
        --labels=environment=prod,purpose=persona-plex,managed-by=gcloud
    
    echo -e "${GREEN}✓ Instance created successfully!${NC}"
fi

# Wait for instance to be running
echo -e "${YELLOW}Waiting for instance to be ready...${NC}"
sleep 30

# Get instance details
echo ""
echo "===================================="
echo -e "${GREEN}Deployment Complete!${NC}"
echo "===================================="
echo ""
echo "Instance Details:"
echo "  Name:        ${INSTANCE_NAME}"
echo "  Zone:        ${ZONE}"
echo "  External IP: ${STATIC_IP}"
echo "  Status:      $(gcloud compute instances describe ${INSTANCE_NAME} --zone=${ZONE} --format='get(status)')"
echo ""
echo "Next Steps:"
echo ""
echo "1. SSH into the instance:"
echo "   gcloud compute ssh ${INSTANCE_NAME} --zone=${ZONE}"
echo ""
echo "2. Run the setup script:"
echo "   sudo bash /opt/persona-plex/setup.sh"
echo ""
echo "3. Download model weights:"
echo "   sudo bash /opt/persona-plex/scripts/download_models.sh"
echo ""
echo "4. Access your application:"
echo "   http://${STATIC_IP}:8000"
echo ""
echo "To delete all resources:"
echo "   bash deployment/gcp/gcloud-cleanup.sh ${PROJECT_ID} ${INSTANCE_NAME} ${ZONE} ${REGION}"
echo ""
