variable "gke_username" {
  description = "GKE username"
}

variable "gke_password" {
  description = "GKE password"
}

variable "gke_node_count" {
  description = "Number of nodes to provision"
}

variable "scaling_min" {
  description = "Minimum node count for autoscaling"
} 

variable "scaling_max" {
  description = "Maximum node count for autoscaling"
} 

variable "primary_location" {
  description = "Primary cluster location (zone or region)"
} 

# Terraform's recommendation is to create the cluster and 
# remove the default node pool to use a separately managed
# node pool defined below. This apparently prevent issues
# such as Terraform trying to delete the cluster under some
# applies .
resource "google_container_cluster" "primary" {
  name     = "${var.project_id}-cluster"
  location = var.primary_location

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  master_auth {
    username = var.gke_username
    password = var.gke_password

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

# The separate node pool, as explained above.
resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.primary.name}-node-pool"
  location   = var.primary_location
  cluster    = google_container_cluster.primary.name
  node_count = var.gke_node_count

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.project_id
    }
    # Despite the plan described in the documentation, I'm using n1-standard-1
    # to keep my costs lower for this homework.
    machine_type = "n1-standard-1"
    tags         = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
  # With autoscaling capabilities
  autoscaling {
    min_node_count = var.scaling_min
    max_node_count = var.scaling_max
  }
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE cluster name"
}