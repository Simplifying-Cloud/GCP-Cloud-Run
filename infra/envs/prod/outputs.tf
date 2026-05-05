output "artifact_registry_url" {
  description = "Push images here.  Format: <registry-url>/<image-name>:<tag>"
  value       = module.artifact_registry.repository_url
}

output "api_url" {
  description = "Default *.run.app URL for api"
  value       = module.api.service_url
}

output "api_ai_url" {
  description = "Default *.run.app URL for api-ai"
  value       = module.api-ai.service_url
}

output "api_runtime_sa" {
  description = "Runtime service account eamil for api.  Grant downstream access to this SA."
  value       = module.api.runtime_service_account_email
}

output "api_ai_runtime_sa" {
  description = "Runtime service account eamil for api-ai.  Grant downstream access to this SA."
  value       = module.api-ai.runtime_service_account_email
}

output "api_dns_records" {
  description = "DNS records to add at your DNS provider for api.  null when domain not set."
  value       = module.api.domain_mapping_records
}

output "api_ai_dns_records" {
  description = "DNS records to add at your DNS provider for api.  null when domain not set."
  value       = module.api-ai.domain_mapping_records
}

output "api_domain_status" {
  description = "Domain mapping conditions for api (cert provisioning state).  Null when domain not set."
  value       = module.api.domain_mapping_status
}

output "api_ai_domain_status" {
  description = "Domain mapping conditions for api (cert provisioning state).  Null when domain not set."
  value       = module.api-ai.domain_mapping_status
}
