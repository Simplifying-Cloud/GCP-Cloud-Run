locals {
  apis = [
    "artifactregistry.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudtrace.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com"
  ]
  enable_wif      = true
  project_id      = var.project_id
  region          = var.region
  tf_state_bucket = "${local.project_id}-terraform-state-${random_id.bucket_suffix.hex}"
}
