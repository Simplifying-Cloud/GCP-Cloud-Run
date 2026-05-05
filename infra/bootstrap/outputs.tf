output "state_bucket_name" {
  value       = google_storage_bucket.tf_state.name
  description = "The name of the Terraform state bucket"
}

output "wif_provider" {
  value       = var.enable_wif ? "google-beta" : "google"
  description = "The provider to use for WIF resources"
}

output "gha_deployer_sa_email" {
  value       = var.enable_wif ? google_service_account.gha_deployer[0].email : null
  description = "The email of the GitHub Actions deployer service account"
}
