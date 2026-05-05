variable "project_id" {
  description = "The ID of the project in which to create the Artifact Registry repository."
  type        = string
}

variable "region" {
  description = "The region in which to create the Artifact Registry repository."
  type        = string
}

variable "name" {
  description = "The name of the Artifact Registry repository."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.name))
    error_message = "Repository name must be lowercase, start with a letter, and contain only letters, digits, and hyphens."
  }
}
