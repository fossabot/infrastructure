terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "vpn"
    workspaces {
      name = "kubernetes"
    }
  }
}

variable "project_id" {
  type        = string
  description = "Google Project ID"
}
variable "google_credentials" {
  description = "Needs access to: Compute Instance Admin (v1), Kubernetes Engine Admin, Service Account User"
}
variable "node_initial_count" {
  default = 1
}

variable "node_machine_type" {
  # https://cloud.google.com/compute/all-pricing
  # n1-standard-1 $24 1cpu 3.75GB
  # n1-standard-2 $48 2cpu 7.5GB
  # e2-standard-2 $48 2cpu 8GB
  default = "n1-standard-1"
}

provider "google-beta" {
  credentials = var.google_credentials
  project     = var.project_id
  version     = "~> 3.0.0"
}

# Get a full list of regions from
# gcloud container subnets list-usable | awk '{ print $2 }'
variable "google_compute_zones" {
  type = list(string)

  default = [
    "us-east1-b",
  ]
}

# https://www.terraform.io/docs/providers/google/r/container_cluster.html
resource "google_container_cluster" "primary" {
  count = length(var.google_compute_zones)

  project  = var.project_id
  name     = "cluster-${element(var.google_compute_zones, count.index)}"
  network  = "projects/${var.project_id}/global/networks/default"
  location = element(var.google_compute_zones, count.index)

  initial_node_count = var.node_initial_count

  # needed for cluster_autoscaling
  provider = google-beta

  # This makes default-pool no matter what
  # Not letting it spin up any nodes, just setting a default and deleting it
  remove_default_node_pool = false

  # This worked once
  # min_master_version = "1.15.8"

  # Disables basic auth
  master_auth {
    username = ""
    password = ""
    client_certificate_config {
      issue_client_certificate = true
    }
  }
  lifecycle {
    ignore_changes = [
      node_pool,
      region,
      master_auth,
      min_master_version,
    ]
  }

  # Enable the new Stackdriver Kubernetes Monitoring/Logging features
  #monitoring_service = "monitoring.googleapis.com/kubernetes"
  #logging_service    = "logging.googleapis.com/kubernetes"
  addons_config {
    horizontal_pod_autoscaling {
      disabled = true # enable later
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  cluster_autoscaling {
    enabled = true
    resource_limits {
      resource_type = "cpu"
      minimum       = 1
      maximum       = 3
    }
    resource_limits {
      resource_type = "memory"
      minimum       = 2
      maximum       = 5
    }
  }

  node_config {
    machine_type = var.node_machine_type
    metadata = {
      disable-legacy-endpoints = "true"
    }
    oauth_scopes = [
      "compute-rw",
      "storage-ro",
      "sql-admin",
      "logging-write",
      "monitoring",
    ]
  }
}
