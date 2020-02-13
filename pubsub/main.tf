terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "vpn"
    workspaces {
      name = "pubsub"
    }
  }
}

variable "project_id" {
  type        = string
  description = "Google Project ID"
}

variable "google_credentials" {
  description = "Needs access to: "
}

provider "google" {
  credentials = var.google_credentials
  project     = var.project_id
}
