resource "google_iam_workload_identity_pool" "gha" {
  count                     = var.enable_wif ? 1 : 0
  project                   = var.project_id
  workload_identity_pool_id = "gha-pool"
  display_name              = "GitHub Actions Workload Identity Pool"
  description               = "Workload Identity Pool for GitHub Actions in Simplifying-Cloud repository"
  disabled                  = false
}

resource "google_iam_workload_identity_pool_provider" "github" {
  count                              = var.enable_wif ? 1 : 0
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.gha[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub Actions Provider"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == \"${var.github_repo}\""
  disabled            = false
}

resource "google_service_account" "gha_deployer" {
  count        = var.enable_wif ? 1 : 0
  account_id   = "gha-deployer"
  display_name = "GitHub Actions Deployer"
  project      = var.project_id
  description  = "Service account used by GitHub Actions for deployment."
}

resource "google_project_iam_member" "gha_deployer_run_admin" {
  count   = var.enable_wif ? 1 : 0
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.gha_deployer[0].email}"
}

resource "google_project_iam_member" "gha_deployer_artifactregistry_writer" {
  count   = var.enable_wif ? 1 : 0
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.gha_deployer[0].email}"
}

resource "google_project_iam_member" "gha_deployer_service_account_user" {
  count   = var.enable_wif ? 1 : 0
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.gha_deployer[0].email}"
}

resource "google_service_account_iam_member" "gha_deployer_wif" {
  count              = var.enable_wif ? 1 : 0
  service_account_id = google_service_account.gha_deployer[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${var.project_id}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.gha[0].workload_identity_pool_id}/attribute.repository/Simplifying-Cloud/${var.github_repo}"
}
