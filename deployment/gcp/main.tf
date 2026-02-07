# Terraform configuration for Persona Plex deployment on GCP
# This creates an optimized instance with NVIDIA A100 GPU

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Variables
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "instance_name" {
  description = "Name of the compute instance"
  type        = string
  default     = "persona-plex-gpu"
}

variable "machine_type" {
  description = "Machine type for the instance"
  type        = string
  default     = "n1-standard-8"
}

variable "gpu_type" {
  description = "GPU type (nvidia-tesla-a100 or nvidia-tesla-t4)"
  type        = string
  default     = "nvidia-tesla-a100"
}

variable "gpu_count" {
  description = "Number of GPUs"
  type        = number
  default     = 1
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 500
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}

# Provider configuration
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Service account for the instance
resource "google_service_account" "persona_plex_sa" {
  account_id   = "persona-plex-sa"
  display_name = "Persona Plex Service Account"
  description  = "Service account for Persona Plex GPU instance"
}

# IAM roles for the service account
resource "google_project_iam_member" "storage_access" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.persona_plex_sa.email}"
}

resource "google_project_iam_member" "logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.persona_plex_sa.email}"
}

resource "google_project_iam_member" "monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.persona_plex_sa.email}"
}

# VPC Network (use default or create custom)
resource "google_compute_network" "persona_plex_network" {
  name                    = "persona-plex-network"
  auto_create_subnetworks = false
  description             = "Custom network for Persona Plex deployment"
}

resource "google_compute_subnetwork" "persona_plex_subnet" {
  name          = "persona-plex-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.persona_plex_network.id
  
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Firewall rules
resource "google_compute_firewall" "persona_plex_ssh" {
  name    = "persona-plex-allow-ssh"
  network = google_compute_network.persona_plex_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"] # Restrict this in production
  target_tags   = ["persona-plex"]
}

resource "google_compute_firewall" "persona_plex_http" {
  name    = "persona-plex-allow-http"
  network = google_compute_network.persona_plex_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8000", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["persona-plex"]
}

resource "google_compute_firewall" "persona_plex_websocket" {
  name    = "persona-plex-allow-websocket"
  network = google_compute_network.persona_plex_network.name

  allow {
    protocol = "tcp"
    ports    = ["8765", "9000", "9090"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["persona-plex"]
}

# Static external IP
resource "google_compute_address" "persona_plex_ip" {
  name         = "persona-plex-static-ip"
  region       = var.region
  address_type = "EXTERNAL"
  description  = "Static IP for Persona Plex instance"
}

# Compute instance with GPU
resource "google_compute_instance" "persona_plex_gpu" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["persona-plex", "gpu-instance", var.environment]

  boot_disk {
    initialize_params {
      image = "projects/ml-images/global/images/family/common-cu121-debian-11-py310"
      size  = var.disk_size_gb
      type  = "pd-ssd"
    }
  }

  # Additional data disk for models and datasets
  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.persona_plex_subnet.id
    
    access_config {
      nat_ip = google_compute_address.persona_plex_ip.address
    }
  }

  guest_accelerator {
    type  = var.gpu_type
    count = var.gpu_count
  }

  scheduling {
    on_host_maintenance = "TERMINATE" # Required for GPU instances
    automatic_restart   = true
    preemptible        = false # Set to true for cost savings in dev
  }

  service_account {
    email  = google_service_account.persona_plex_sa.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/devstorage.read_only"
    ]
  }

  metadata = {
    enable-oslogin = "TRUE"
    startup-script = file("${path.module}/startup-script.sh")
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e
    
    echo "=== Persona Plex GPU Instance Initialization ==="
    echo "Starting at: $(date)"
    
    # Install NVIDIA drivers if not present
    if ! command -v nvidia-smi &> /dev/null; then
      echo "Installing NVIDIA drivers..."
      curl -fsSL https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
      distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
      curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
        sudo tee /etc/apt/sources.list.d/nvidia-docker.list
      
      apt-get update
      apt-get install -y nvidia-driver-525 nvidia-utils-525
    fi
    
    # Verify GPU
    nvidia-smi
    
    echo "GPU instance initialization complete at: $(date)"
  EOF

  labels = {
    environment = var.environment
    purpose     = "persona-plex"
    managed_by  = "terraform"
  }

  lifecycle {
    ignore_changes = [
      metadata_startup_script,
    ]
  }
}

# Cloud Storage bucket for models
resource "google_storage_bucket" "persona_plex_models" {
  name          = "${var.project_id}-persona-plex-models"
  location      = var.region
  force_destroy = false
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = var.environment
    purpose     = "model-storage"
  }
}

# IAM for bucket access
resource "google_storage_bucket_iam_member" "persona_plex_bucket_access" {
  bucket = google_storage_bucket.persona_plex_models.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.persona_plex_sa.email}"
}

# Outputs
output "instance_name" {
  description = "Name of the created instance"
  value       = google_compute_instance.persona_plex_gpu.name
}

output "instance_id" {
  description = "ID of the created instance"
  value       = google_compute_instance.persona_plex_gpu.instance_id
}

output "external_ip" {
  description = "External IP address of the instance"
  value       = google_compute_address.persona_plex_ip.address
}

output "internal_ip" {
  description = "Internal IP address of the instance"
  value       = google_compute_instance.persona_plex_gpu.network_interface[0].network_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "gcloud compute ssh ${google_compute_instance.persona_plex_gpu.name} --zone=${var.zone}"
}

output "model_bucket" {
  description = "GCS bucket for storing models"
  value       = google_storage_bucket.persona_plex_models.url
}

output "service_account_email" {
  description = "Service account email"
  value       = google_service_account.persona_plex_sa.email
}
