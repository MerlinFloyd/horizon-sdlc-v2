# GCP Terraform Configurations Template

## Overview
This template provides Terraform configurations for GCP resources following our infrastructure standards with distributed strategy, environment-based Shared VPC, and mandatory resource tagging.

## Project Structure

```
terraform/
├── environments/
│   ├── test/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── outputs.tf
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       └── outputs.tf
├── modules/
│   ├── gke/
│   ├── vpc/
│   ├── monitoring/
│   ├── pubsub/
│   └── storage/
└── global/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

## Global Resources

### 1. Organization and Folder Structure
```hcl
# terraform/global/main.tf
terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
  cloud {
    organization = "horizon-org"
    workspaces {
      name = "horizon-global"
    }
  }
}

provider "google" {
  project = var.organization_project_id
  region  = var.default_region
}

provider "google-beta" {
  project = var.organization_project_id
  region  = var.default_region
}

# Organization-level resources
resource "google_folder" "horizon" {
  display_name = "Horizon"
  parent       = "organizations/${var.organization_id}"
}

resource "google_folder" "environments" {
  display_name = "Environments"
  parent       = google_folder.horizon.name
}

resource "google_folder" "shared_services" {
  display_name = "Shared Services"
  parent       = google_folder.horizon.name
}

# Shared VPC Host Project
resource "google_project" "shared_vpc_host" {
  name            = "horizon-shared-vpc"
  project_id      = "horizon-shared-vpc-${random_id.project_suffix.hex}"
  folder_id       = google_folder.shared_services.name
  billing_account = var.billing_account_id

  labels = {
    application = "horizon"
    environment = "shared"
    managed_by  = "terraform"
  }
}

resource "random_id" "project_suffix" {
  byte_length = 4
}

# Enable required APIs
resource "google_project_service" "shared_vpc_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ])

  project = google_project.shared_vpc_host.project_id
  service = each.value

  disable_dependent_services = true
}

# Shared VPC Network
resource "google_compute_network" "shared_vpc" {
  name                    = "horizon-shared-vpc"
  project                 = google_project.shared_vpc_host.project_id
  auto_create_subnetworks = false
  mtu                     = 1460

  depends_on = [google_project_service.shared_vpc_apis]
}

# Enable Shared VPC
resource "google_compute_shared_vpc_host_project" "host" {
  project = google_project.shared_vpc_host.project_id

  depends_on = [google_project_service.shared_vpc_apis]
}
```

### 2. Global Variables
```hcl
# terraform/global/variables.tf
variable "organization_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "organization_project_id" {
  description = "Organization project ID for global resources"
  type        = string
}

variable "billing_account_id" {
  description = "Billing account ID"
  type        = string
}

variable "default_region" {
  description = "Default GCP region"
  type        = string
  default     = "us-central1"
}

variable "default_zone" {
  description = "Default GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    application = "horizon"
    managed_by  = "terraform"
  }
}
```

## VPC Module

### 1. VPC Module Configuration
```hcl
# terraform/modules/vpc/main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Subnet for GKE clusters
resource "google_compute_subnetwork" "gke_subnet" {
  name          = "${var.environment}-gke-subnet"
  project       = var.shared_vpc_project_id
  network       = var.shared_vpc_network
  region        = var.region
  ip_cidr_range = var.gke_subnet_cidr

  secondary_ip_range {
    range_name    = "${var.environment}-gke-pods"
    ip_cidr_range = var.gke_pods_cidr
  }

  secondary_ip_range {
    range_name    = "${var.environment}-gke-services"
    ip_cidr_range = var.gke_services_cidr
  }

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Subnet for Cloud SQL and other services
resource "google_compute_subnetwork" "services_subnet" {
  name          = "${var.environment}-services-subnet"
  project       = var.shared_vpc_project_id
  network       = var.shared_vpc_network
  region        = var.region
  ip_cidr_range = var.services_subnet_cidr

  private_ip_google_access = true
}

# Cloud Router for NAT
resource "google_compute_router" "router" {
  name    = "${var.environment}-router"
  project = var.shared_vpc_project_id
  region  = var.region
  network = var.shared_vpc_network
}

# Cloud NAT for outbound internet access
resource "google_compute_router_nat" "nat" {
  name                               = "${var.environment}-nat"
  project                           = var.shared_vpc_project_id
  router                            = google_compute_router.router.name
  region                            = var.region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall rules
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.environment}-allow-internal"
  project = var.shared_vpc_project_id
  network = var.shared_vpc_network

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.gke_subnet_cidr,
    var.gke_pods_cidr,
    var.gke_services_cidr,
    var.services_subnet_cidr,
  ]

  target_tags = ["${var.environment}-internal"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.environment}-allow-ssh"
  project = var.shared_vpc_project_id
  network = var.shared_vpc_network

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # Google Cloud IAP range
  target_tags   = ["${var.environment}-ssh"]
}
```

### 2. VPC Module Variables
```hcl
# terraform/modules/vpc/variables.tf
variable "environment" {
  description = "Environment name (test/prod)"
  type        = string
}

variable "shared_vpc_project_id" {
  description = "Shared VPC host project ID"
  type        = string
}

variable "shared_vpc_network" {
  description = "Shared VPC network name"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "gke_subnet_cidr" {
  description = "CIDR range for GKE subnet"
  type        = string
}

variable "gke_pods_cidr" {
  description = "CIDR range for GKE pods"
  type        = string
}

variable "gke_services_cidr" {
  description = "CIDR range for GKE services"
  type        = string
}

variable "services_subnet_cidr" {
  description = "CIDR range for services subnet"
  type        = string
}
```

## GKE Module

### 1. GKE Cluster Configuration
```hcl
# terraform/modules/gke/main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

# Service Account for GKE nodes
resource "google_service_account" "gke_nodes" {
  account_id   = "${var.cluster_name}-nodes"
  project      = var.project_id
  display_name = "GKE Nodes Service Account"
}

resource "google_project_iam_member" "gke_nodes_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/storage.objectViewer",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  project  = var.project_id
  location = var.region

  # Network configuration
  network    = var.network
  subnetwork = var.subnetwork

  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  # IP allocation policy for VPC-native cluster
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  # Network policy
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  # Addons configuration
  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    network_policy_config {
      disabled = false
    }

    istio_config {
      disabled = false
      auth     = "AUTH_MUTUAL_TLS"
    }
  }

  # Master auth configuration
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # Master authorized networks
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Maintenance policy
  maintenance_policy {
    recurring_window {
      start_time = "2023-01-01T02:00:00Z"
      end_time   = "2023-01-01T06:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA"
    }
  }

  # Resource labels
  resource_labels = merge(var.labels, {
    cluster_name = var.cluster_name
    environment  = var.environment
  })

  lifecycle {
    ignore_changes = [
      initial_node_count,
    ]
  }
}

# Node pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-nodes"
  project    = var.project_id
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  # Node configuration
  node_config {
    preemptible  = var.preemptible_nodes
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = "pd-ssd"

    # Service account
    service_account = google_service_account.gke_nodes.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Shielded instance configuration
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Labels and tags
    labels = merge(var.labels, {
      node_pool   = "${var.cluster_name}-nodes"
      environment = var.environment
    })

    tags = ["${var.environment}-gke-nodes"]
  }

  # Autoscaling
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  # Node management
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}
```

### 2. GKE Module Variables
```hcl
# terraform/modules/gke/variables.tf
variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "network" {
  description = "VPC network name"
  type        = string
}

variable "subnetwork" {
  description = "VPC subnetwork name"
  type        = string
}

variable "pods_range_name" {
  description = "Secondary range name for pods"
  type        = string
}

variable "services_range_name" {
  description = "Secondary range name for services"
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for GKE master"
  type        = string
  default     = "172.16.0.0/28"
}

variable "authorized_networks" {
  description = "List of authorized networks for GKE master"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "node_count" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 3
}

variable "min_node_count" {
  description = "Minimum number of nodes in the node pool"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes in the node pool"
  type        = number
  default     = 10
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-standard-4"
}

variable "disk_size_gb" {
  description = "Disk size for GKE nodes"
  type        = number
  default     = 100
}

variable "preemptible_nodes" {
  description = "Use preemptible nodes"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
```

## Environment Configuration

### 1. Test Environment
```hcl
# terraform/environments/test/main.tf
terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
  cloud {
    organization = "horizon-org"
    workspaces {
      name = "horizon-test"
    }
  }
}

# Data sources for global resources
data "terraform_remote_state" "global" {
  backend = "remote"
  config = {
    organization = "horizon-org"
    workspaces = {
      name = "horizon-global"
    }
  }
}

provider "google" {
  project = google_project.test.project_id
  region  = var.region
}

provider "google-beta" {
  project = google_project.test.project_id
  region  = var.region
}

# Test environment project
resource "google_project" "test" {
  name            = "horizon-test"
  project_id      = "horizon-test-${random_id.project_suffix.hex}"
  folder_id       = data.terraform_remote_state.global.outputs.environments_folder_id
  billing_account = var.billing_account_id

  labels = merge(var.common_labels, {
    environment = "test"
  })
}

resource "random_id" "project_suffix" {
  byte_length = 4
}

# Enable required APIs
resource "google_project_service" "test_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "pubsub.googleapis.com",
    "storage.googleapis.com",
    "cloudsql.googleapis.com",
    "redis.googleapis.com",
  ])

  project = google_project.test.project_id
  service = each.value

  disable_dependent_services = true
}

# Attach to Shared VPC
resource "google_compute_shared_vpc_service_project" "test" {
  host_project    = data.terraform_remote_state.global.outputs.shared_vpc_project_id
  service_project = google_project.test.project_id

  depends_on = [google_project_service.test_apis]
}

# VPC configuration
module "vpc" {
  source = "../../modules/vpc"

  environment           = "test"
  shared_vpc_project_id = data.terraform_remote_state.global.outputs.shared_vpc_project_id
  shared_vpc_network    = data.terraform_remote_state.global.outputs.shared_vpc_network
  region                = var.region

  gke_subnet_cidr     = "10.1.0.0/24"
  gke_pods_cidr       = "10.1.1.0/24"
  gke_services_cidr   = "10.1.2.0/24"
  services_subnet_cidr = "10.1.3.0/24"
}

# GKE cluster
module "gke" {
  source = "../../modules/gke"

  cluster_name         = "horizon-test-gke"
  project_id          = google_project.test.project_id
  region              = var.region
  network             = data.terraform_remote_state.global.outputs.shared_vpc_network
  subnetwork          = module.vpc.gke_subnet_name
  pods_range_name     = module.vpc.gke_pods_range_name
  services_range_name = module.vpc.gke_services_range_name
  environment         = "test"

  node_count       = 2
  min_node_count   = 1
  max_node_count   = 5
  machine_type     = "e2-standard-2"
  preemptible_nodes = true

  labels = merge(var.common_labels, {
    environment = "test"
  })

  depends_on = [
    google_compute_shared_vpc_service_project.test,
    module.vpc
  ]
}
```

### 2. Test Environment Variables
```hcl
# terraform/environments/test/variables.tf
variable "billing_account_id" {
  description = "Billing account ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    application = "horizon"
    environment = "test"
    managed_by  = "terraform"
  }
}
```

### 3. Test Environment Terraform Variables
```hcl
# terraform/environments/test/terraform.tfvars
billing_account_id = "012345-678901-234567"
region            = "us-central1"

common_labels = {
  application = "horizon"
  environment = "test"
  managed_by  = "terraform"
  team        = "platform"
}
```

## Resource Tagging Standards

### 1. Mandatory Labels
```hcl
# Standard labels applied to all resources
locals {
  mandatory_labels = {
    application = var.application_name
    environment = var.environment
    managed_by  = "terraform"
    team        = var.team_name
    cost_center = var.cost_center
  }

  # Merge with custom labels
  resource_labels = merge(local.mandatory_labels, var.custom_labels)
}

# Example usage in resource
resource "google_compute_instance" "example" {
  name         = "example-instance"
  machine_type = "e2-micro"
  zone         = var.zone

  labels = local.resource_labels

  # ... other configuration
}
```

This template provides comprehensive GCP Terraform configurations following our infrastructure standards with proper organization, security, and resource management.
