# Required variables
variable "project_id" {
  description = "The project ID to deploy the Cloud Run service to."
  type        = string
}

variable "region" {
  description = "The region to deploy the Cloud Run service to."
  type        = string
}

variable "name" {
  description = "Service name.  Becomes part of the *.run.app URL.  Lowercase, hyphens allowed."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.name)) && length(var.name) <= 49
    error_message = "Service name must be lowercase, start with a letter, contain only letters/digits/hyphens, and be 49 chars or fewer."
  }
}

variable "image" {
  description = "Container image URL with immutable tag (never ':latest').  Example: 'us-central1-docker.pkg.dev/PROJECT/REPO/IMAGE:TAG' or 'gcr.io/cloudrun/hello'."
  type        = string
}


# Compute sizing (defaults included)
variable "cpu" {
  description = "CPU allocation per instance.  Common values: '1', '2', '4'.  Sub-CPU ('0.5', '0.25') allowed only when min_instances=0."
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory allocation per instance.  Format: '<N>Mi' or '<N>Gi'.  Min depends on CPU allocation.  Common values: '512Mi', '1Gi', '2Gi'."
  type        = string
  default     = "512Mi"
}

variable "min_instances" {
  description = "Minimum warm instances.  0 = scale-to-zero (free when idle).  Set >0 only if cold start hurts SLO; costs money 24/7."
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Hard cap on instances. Cost guardrail."
  type        = number
  default     = 4
}

variable "concurrency" {
  description = "Number of concurrent requests per instance.  Lower for CPU bound workloads.  Common values: 80 (Cloud Run default), 1 (no concurrency)."
  type        = number
  default     = 80
}

variable "timeout_seconds" {
  description = "Timeout for requests to the Cloud Run service.  Default is 30 seconds.  Max 3600 seconds (1 hour)."
  type        = number
  default     = 30
}

variable "cpu_boost" {
  description = "Allocate extra CPU during cold start to reduce startup latency."
  type        = bool
  default     = true
}

# Networking & access
variable "container_port" {
  description = "Port the container listens on. Cloud Run terminates TLS on 443 and forwards traffic to this port; the value is injected into the container as PORT."
  type        = number
  default     = 8080
}
variable "ingress" {
  description = "What traffic can reach the service.  INGRESS_TRAFFIC_ALL (public), INGRESS_TRAFFIC_INTERNAL_ONLY, or INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER (when fronted by an LB)."
  type        = string
  default     = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  validation {
    condition = contains([
      "INGRESS_TRAFFIC_ALL",
      "INGRESS_TRAFFIC_INTERNAL_ONLY",
      "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER",
    ], var.ingress)
    error_message = "Invalid ingress value"
  }
}

variable "allow_unauthenticated" {
  description = "When true, grants roles/run.invoker to allUsers (public API).  When false, callers must provide a valid ID token."
  type        = bool
  default     = false
}

# Application config
variable "env_vars" {
  description = "Map of environment variable key-value pairs to set in the container."
  type        = map(string)
  default     = {}
}

variable "secret_env_vars" {
  description = "Environment variables sourced from Secret Manager.  Map of env var name to { secret_id = string, version = string }. Example: { DB_PASS = { secret_id = \"db-pass\", version = \"latest\" } }."
  type = map(object({
    secret_id = string
    version   = optional(string, "latest")
  }))
  default = {}
}

# Probes (optional)
variable "startup_probe" {
  description = "Optional startup probe.  Set to null to skip.  Runs until success, then liveness takes over."
  type = object({
    path                  = string
    initial_delay_seconds = optional(number, 0)
    timeout_seconds       = optional(number, 1)
    period_seconds        = optional(number, 10)
    failure_threshold     = optional(number, 3)
  })
  default = null
}

variable "liveness_probe" {
  description = "Optional liveness probe.  Failed liveness restarts the instances"
  type = object({
    path              = string
    timeout_seconds   = optional(number, 1)
    period_seconds    = optional(number, 10)
    failure_threshold = optional(number, 3)
  })
  default = null
}

# Domain mapping (optional)
variable "domain" {
  description = "Optional custom domain (FQDN, must not be apex).  Set to null to skip.  Creates a Cloud Run domain mapping; consumer must add the retruned DNS records."
  type        = string
  default     = null
}

# Labels (optional)
variable "labels" {
  description = "Optional map of labels to apply to the service and all child resources.  Merged with module defaults.  Keys must be lowercase"
  type        = map(string)
  default     = {}
}
