variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The GCP region."
  type        = string
  default     = "us-central1"
}

variable "artifact_registry_name" {
  description = "Name for the Artifact Registry repo holding service images"
  type        = string
  default     = "services"
}

variable "image_api" {
  description = "Conatiner image for api.  Initially the upstream dummy; replace with AR copy."
  type        = string
  default     = "gcr.io/cloudrun/hello"
}

variable "image_api_ai" {
  description = "Conatiner image for api-ai.  Initially the upstream dummy; replace with AR copy."
  type        = string
  default     = "gcr.io/cloudrun/hello"
}

variable "domain_api" {
  description = "Custom domain for api.  Must be mapped to Cloud Run service and verified in GCP."
  type        = string
  default     = null
}

variable "domain_api_ai" {
  description = "Custom domain for api-ai.  Must be mapped to Cloud Run service and verified in GCP."
  type        = string
  default     = null
}

variable "alert_email" {
  description = "Email address that receives monitoring alerts.  Required when monitoring is enabled."
  type        = string

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.alert_email))
    error_message = "Must be a vaolid email address"
  }
}
