output "repository_id" {
  description = "Short repository name (e.g., 'my-repo')."
  value       = google_artifact_registry_repository.this.repository_id
}

output "repository_url" {
  description = "Full Docker push/pull URL (e.g., 'us-central1-docker.pkg.dev/PROJECT/REPO').  Append ':TAG' or '/IMAGE:TAG' to use."
  value       = "${google_artifact_registry_repository.this.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.this.repository_id}"
}

output "repository_name" {
  description = "Fully-qualified resource name.  Used by IAM bindings and other resources that reference the repo."
  value       = google_artifact_registry_repository.this.name
}
