variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "state_bucket_name" {
  description = "The name of the Terraform state bucket"
  type        = string
}

variable "enable_wif" {
  description = "Whether to enable WIF"
  type        = bool
  default     = false
}

variable "github_repo" {
  description = "The GitHub repository name"
  type        = string
  default     = null

  validation {
    condition     = !var.enable_wif || (var.github_repo != null && var.github_repo != "")
    error_message = "github_repo must be set when enable_wif is enabled"
  }
}
