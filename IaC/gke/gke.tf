variable "gke_username" {
  default     = "short-url-user"
  description = "GKE username"
}

variable "gke_password" {
  default     = "short-url-password"
  description = "GKE password"
}

variable "gke_node_count" {
  default     = 1
  description = "Nodes to provision"
}

# Create the cluster and remove the default node pool to use
# a separately managed node pool defined below
resource "google_container_cluster" "primary" {
  name     = "${var.project_id}-cluster"
  location = var.region

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

# Separate node pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.primary.name}-node-pool"
  location   = var.region
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
    # With (slightly) bigger machine type
    machine_type = "n1-standard-2"
    tags         = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
  # With autoscaling capabilities
  autoscaling {
    min_node_count = 1
    max_node_count = 2 
  }
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE cluster name"
}