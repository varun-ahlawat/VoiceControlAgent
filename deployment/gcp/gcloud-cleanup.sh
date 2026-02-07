#!/bin/bash
# Cleanup script to destroy all GCP resources created for Persona Plex

set -e

PROJECT_ID="${1:-}"
INSTANCE_NAME="${2:-persona-plex-gpu}"
ZONE="${3:-us-central1-a}"
REGION="${4:-us-central1}"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "===================================="
echo "Persona Plex GCP Cleanup"
echo "===================================="
echo ""

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}Error: Project ID not provided${NC}"
    echo "Usage: $0 PROJECT_ID [INSTANCE_NAME] [ZONE] [REGION]"
    exit 1
fi

echo -e "${YELLOW}WARNING: This will delete all Persona Plex resources!${NC}"
echo ""
echo "Resources to be deleted:"
echo "  - Instance: ${INSTANCE_NAME}"
echo "  - Static IP: persona-plex-static-ip"
echo "  - VPC Network: persona-plex-network"
echo "  - Service Account: persona-plex-sa"
echo "  - GCS Bucket: ${PROJECT_ID}-persona-plex-models"
echo ""

read -p "Are you sure? Type 'yes' to confirm: " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cleanup cancelled"
    exit 0
fi

gcloud config set project ${PROJECT_ID}

# Delete instance
echo "Deleting instance..."
gcloud compute instances delete ${INSTANCE_NAME} --zone=${ZONE} --quiet || true

# Delete static IP
echo "Deleting static IP..."
gcloud compute addresses delete persona-plex-static-ip --region=${REGION} --quiet || true

# Delete firewall rules
echo "Deleting firewall rules..."
gcloud compute firewall-rules delete persona-plex-allow-ssh --quiet || true
gcloud compute firewall-rules delete persona-plex-allow-http --quiet || true
gcloud compute firewall-rules delete persona-plex-allow-websocket --quiet || true

# Delete subnet
echo "Deleting subnet..."
gcloud compute networks subnets delete persona-plex-subnet --region=${REGION} --quiet || true

# Delete network
echo "Deleting network..."
gcloud compute networks delete persona-plex-network --quiet || true

# Delete service account
echo "Deleting service account..."
SA_EMAIL="persona-plex-sa@${PROJECT_ID}.iam.gserviceaccount.com"
gcloud iam service-accounts delete ${SA_EMAIL} --quiet || true

# Note: Bucket deletion requires manual confirmation or --force
echo ""
echo "To delete the GCS bucket (contains model data):"
echo "  gsutil rm -r gs://${PROJECT_ID}-persona-plex-models"
echo ""
echo "Cleanup complete!"
