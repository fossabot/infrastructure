# Handles in app purchase data from apple
# This topic is filled in by apple's server to server Webhook
# Any data placed in the topic is sent to bugquery

resource "google_pubsub_topic" "iap-apple-topic" {
  name = "iap-apple-topic"
}

resource "google_pubsub_subscription" "iap-apple-sub" {
  name                       = "iap-apple-sub"
  topic                      = google_pubsub_topic.iap-apple-topic.name
  message_retention_duration = "604800s"
  retain_acked_messages      = true
  ack_deadline_seconds       = 60
}

resource "google_pubsub_subscription" "iap-apple-dataflow-sub" {
  name                       = "iap-apple-dataflow-sub"
  topic                      = google_pubsub_topic.iap-apple-topic.name
  message_retention_duration = "60s"
  retain_acked_messages      = false
  ack_deadline_seconds       = 20
}

resource "google_bigquery_dataset" "iap-apple" {
  dataset_id    = "iap-apple"
  friendly_name = "iap-apple"
  description   = "In App Puchase Webhook Data from Apple"
  # location                    = "EU"
  default_table_expiration_ms = 3600000
}

resource "google_bigquery_table" "iap-apple-table" {
  dataset_id = google_bigquery_dataset.iap-apple.dataset_id
  table_id   = "iap-apple"

  time_partitioning {
    type = "DAY"
  }
}

resource "google_storage_bucket" "image-store" {
  name = "${var.project_id}-tmp"
}


resource "google_dataflow_job" "iap-bigquery" {
  name              = "iap-bigquery"
  template_gcs_path = "gs://dataflow-templates/2019-07-10-00/PubSub_to_BigQuery"
  temp_gcs_location = "gs://${var.project_id}-tmp/iap-bigquery"
  parameters = {
    inputTopic      = google_pubsub_topic.iap-apple-topic.name,
    outputTableSpec = google_bigquery_table.iap-apple-table.table_id
  }
}
