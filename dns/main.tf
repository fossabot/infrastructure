terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "vpn"
    workspaces {
      prefix = "dns-"
    }
  }
}

variable "project_id" {
  type        = string
  description = "Google Project ID"
}
variable "domain_name" {}
variable "google_credentials" {
  description = "Needs access to: DNS Administrator"
}

provider "google" {
  credentials = var.google_credentials
  project     = var.project_id
  version     = "~> 3.0.0"
}

resource "google_dns_managed_zone" "prod" {
  project  = var.project_id
  name     = "public-zone"
  dns_name = "${var.domain_name}."

  lifecycle {
    ignore_changes = [dnssec_config]
  }
}

# TODO: Move this to google cloud static pages some time
# https://help.github.com/en/github/working-with-github-pages/about-github-pages
# https://cloud.google.com/storage/docs/hosting-static-website
resource "google_dns_record_set" "github-site-a" {
  project = var.project_id
  name    = google_dns_managed_zone.prod.dns_name
  type    = "A"
  ttl     = 300

  managed_zone = google_dns_managed_zone.prod.name

  rrdatas = ["185.199.108.153", "185.199.109.153", "185.199.110.153", "185.199.111.153"]
}


resource "google_dns_record_set" "github-site-cname" {
  project = var.project_id
  name    = "www.${google_dns_managed_zone.prod.dns_name}"
  type    = "CNAME"
  ttl     = 300

  managed_zone = google_dns_managed_zone.prod.name

  rrdatas = ["securenomad.github.io."]
}

resource "google_dns_record_set" "cloud-func" {
  project = var.project_id
  name    = "api.${google_dns_managed_zone.prod.dns_name}"
  type    = "CNAME"
  ttl     = 300

  managed_zone = google_dns_managed_zone.prod.name

  rrdatas = ["us-central1-vpn-service-264313.cloudfunctions.net."]
}

resource "google_dns_record_set" "webmaster-central" {
  project      = var.project_id
  name         = google_dns_managed_zone.prod.dns_name
  type         = "TXT"
  ttl          = 300
  managed_zone = google_dns_managed_zone.prod.name

  rrdatas = ["google-site-verification=q8lcEd-N4My_7XFdmKQP5iVMoaNzPXiCC6oNuM2a4hk"]
}

resource "google_dns_record_set" "github-verify" {
  project      = var.project_id
  name         = "_github-challenge-SecureNomad.securenomad.com."
  type         = "TXT"
  ttl          = 300
  managed_zone = google_dns_managed_zone.prod.name

  rrdatas = ["3ae5542f73"]
}
