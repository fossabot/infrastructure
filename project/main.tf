terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "vpn"
    workspaces {
      name = "project"
    }
  }
}

variable "billing_id" {}
variable "organization_id" {}
variable "project_name" {}
variable "project_id" {
  type        = string
  description = "Google Project ID"
}
variable "google_credentials" {
  description = "Needs access to: Owner"
}

provider "google" {
  credentials = var.google_credentials
  project     = var.project_id
  version     = "~> 3.0.0"
}

resource "google_project" "project" {
  name            = var.project_name
  project_id      = var.project_id
  billing_account = var.billing_id
  org_id          = var.organization_id

  # skip_delete - (Optional) If true, the Terraform resource can be deleted without deleting the Project via the Google API.
  skip_delete = true
}

resource "google_project_iam_binding" "project_bind_owner" {
  project = var.project_id
  role    = "roles/owner"

  members = [
    "user:nate@natefanaro.com",
    "serviceAccount:terraform-project@vpn-service-264313.iam.gserviceaccount.com",
  ]
}

# Add new items at the end. Do not sort this list. It will cause a lot of churn.
variable "google_project_service_services" {
  type = list(string)
  default = [
    "cloudbilling.googleapis.com",
    "container.googleapis.com",
    "deploymentmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "logging.googleapis.com",
    "compute.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "storage-component.googleapis.com",
    "sqladmin.googleapis.com",
    "sql-component.googleapis.com",
    "cloudbuild.googleapis.com",
    "dns.googleapis.com",
    "sourcerepo.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudfunctions.googleapis.com",
    "storage-component.googleapis.com",
    "appengine.googleapis.com",
    "secretmanager.googleapis.com",
    "dataflow.googleapis.com"
  ]
}

resource "google_project_service" "primary" {
  count              = length(var.google_project_service_services)
  project            = google_project.project.project_id
  service            = element(var.google_project_service_services, count.index)
  disable_on_destroy = false
}
