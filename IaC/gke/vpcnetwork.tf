variable "project_id" {
  description = "project id"
}

variable "primary_zone" {
  description = "Primary cluster zone"
} 

provider "google" {
  project = var.project_id
  zone  = var.primary_zone
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-subnet"
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.60.0.0/24"

}

output "zone" {
  value       = var.primary_zone
  description = "Zone"
}