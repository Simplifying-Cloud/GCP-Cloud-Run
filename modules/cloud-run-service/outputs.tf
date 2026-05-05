output "service_name" {
  description = "Cloud Run service name."
  value       = google_cloud_run_v2_service.this.name
}

output "service_url" {
  description = "Default *.run.app URL for the service."
  value       = google_cloud_run_v2_service.this.uri
}

output "latest_ready_revision" {
  description = "Name of the most recent revision that successfully started."
  value       = google_cloud_run_v2_service.this.latest_ready_revision
}

output "runtime_service_account_email" {
  description = "Email of the SA the service runs as. Grant downstream resource access to this SA."
  value       = google_service_account.runtime.email
}

output "runtime_service_account_id" {
  description = "Fully-qualified SA resource name. Used for IAM bindings."
  value       = google_service_account.runtime.name
}

output "domain_mapping_records" {
  description = "DNS records to add at your DNS provider. null when var.domain is unset. List of objects: [{ type, rrdata }]. For a subdomain you typically get one CNAME pointing at ghs.googlehosted.com."
  value       = var.domain == null ? null : try(google_cloud_run_domain_mapping.this[0].status[0].resource_records, null)
}

output "domain_mapping_status" {
  description = "Current state of the domain mapping (cert provisioning, DNS verification, etc.). null when unset."
  value       = var.domain == null ? null : try(google_cloud_run_domain_mapping.this[0].status[0].conditions, null)
}
