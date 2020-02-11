terraform {

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "vpn"
    workspaces {
      name = "database"
    }
  }
}

variable "project_id" {
  type        = string
  description = "Google Project ID"
}
variable "google_credentials" {
  description = "Needs access to: Cloud SQL Admin, Compute Network Admin, Secret Manager Admin"
}
variable "mysql_enabled" {}
variable "region" {}
variable "mysql_username" {}
variable "mysql_database" {}

resource "random_pet" "password" {
  length = 5
}

provider "google-beta" {
  credentials = var.google_credentials
  project     = var.project_id
  version     = "~> 3.8.0"
}

resource "google_compute_network" "private_network" {
  provider = google-beta
  name     = "private-network"
  project  = var.project_id
}

resource "google_compute_global_address" "private_ip_address" {
  provider = google-beta

  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.private_network.self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google-beta
  network                 = google_compute_network.private_network.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "instance" {
  provider = google-beta
  project  = var.project_id
  count    = var.mysql_enabled

  # random? gcloud has an issue with downing and recreating a sql instance with the same name
  name   = "${var.project_id}-${random_id.db_name_suffix.hex}"
  region = var.region

  depends_on = [google_service_networking_connection.private_vpc_connection]

  # MYSQL_5_6 was working. hopefully 5.7 does too
  database_version = "MYSQL_5_7"

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.private_network.self_link
    }
    backup_configuration {
      enabled = false
    }
  }

  lifecycle {
    # Was running in to an issue with this changing often
    # ignore_changes = ["settings.0.maintenance_window"]
  }

}

resource "google_sql_database" "service" {
  count     = var.mysql_enabled
  provider  = google-beta
  project   = var.project_id
  name      = var.mysql_database
  instance  = google_sql_database_instance.instance[0].name
  charset   = "utf8"
  collation = "utf8_general_ci"
}

resource "google_sql_user" "service" {
  count    = var.mysql_enabled
  provider = google-beta
  project  = var.project_id
  name     = var.mysql_username
  instance = google_sql_database_instance.instance[0].name
  host     = "cloudsqlproxy~%"
  password = random_pet.password.id
}

# Storing secrets
resource "google_secret_manager_secret" "mysql_username" {
  provider  = google-beta
  secret_id = "mysql_username"
  labels = {
    label = "database"
  }
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "mysql_username" {
  provider    = google-beta
  secret      = google_secret_manager_secret.mysql_username.name
  secret_data = var.mysql_username
}

resource "google_secret_manager_secret" "mysql_password" {
  provider  = google-beta
  secret_id = "mysql_password"
  labels = {
    label = "database"
  }
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "mysql_password" {
  provider    = google-beta
  secret      = google_secret_manager_secret.mysql_password.name
  secret_data = random_pet.password.id
}

resource "google_secret_manager_secret" "mysql_connection_name" {
  provider  = google-beta
  secret_id = "mysql_connection_name"
  labels = {
    label = "database"
  }
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "mysql_connection_name" {
  provider    = google-beta
  secret      = google_secret_manager_secret.mysql_connection_name.name
  secret_data = google_sql_database_instance.instance[0].connection_name
}

resource "google_secret_manager_secret" "mysql_database" {
  provider  = google-beta
  secret_id = "mysql_database"
  labels = {
    label = "database"
  }
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "mysql_database" {
  provider    = google-beta
  secret      = google_secret_manager_secret.connection_name.name
  secret_data = var.mysql_database
}
