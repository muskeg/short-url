variable "project_id" {
  description = "project id"
}

variable "region" {
  description = "region"
}

provider "google" {
  credentials = file("service-account.json")
  project = var.project_id
  region  = var.region
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.60.0.0/24"

}

output "region" {
  value       = var.region
  description = "Region"
}