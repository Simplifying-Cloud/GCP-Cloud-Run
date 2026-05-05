locals {
  default_labels = {
    managed-by = "terraform"
    service    = var.name
  }
  labels = merge(local.default_labels, var.labels)
}

# Per-service runtime service account
resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = "cr-${var.name}"
  display_name = "Cloud Run runtime SA for ${var.name}"
  description  = "Identity used by the ${var.name} Cloud Run service.  Grant downstream resource access to this SA, not to the default compute SA."
}

# The service
resource "google_cloud_run_v2_service" "this" {
  project  = var.project_id
  location = var.region
  name     = var.name

  ingress = var.ingress
  labels  = local.labels

  template {
    service_account                  = google_service_account.runtime.email
    timeout                          = "${var.timeout_seconds}s"
    max_instance_request_concurrency = var.concurrency
    execution_environment            = "EXECUTION_ENVIRONMENT_GEN2"

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image = var.image

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
        startup_cpu_boost = var.cpu_boost
        cpu_idle          = true # CPU only allocated during request processing
      }

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.secret_env_vars
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret_id
              version = env.value.version
            }
          }
        }
      }

      dynamic "startup_probe" {
        for_each = var.startup_probe == null ? [] : [var.startup_probe]
        content {
          initial_delay_seconds = startup_probe.value.initial_delay_seconds
          timeout_seconds       = startup_probe.value.timeout_seconds
          period_seconds        = startup_probe.value.period_seconds
          failure_threshold     = startup_probe.value.failure_threshold
          http_get {
            path = startup_probe.value.path
          }
        }
      }

      dynamic "liveness_probe" {
        for_each = var.liveness_probe == null ? [] : [var.liveness_probe]
        content {
          timeout_seconds   = liveness_probe.value.timeout_seconds
          period_seconds    = liveness_probe.value.period_seconds
          failure_threshold = liveness_probe.value.failure_threshold
          http_get {
            path = liveness_probe.value.path
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      # Allows manual gcloud traffic splitting (canary/rollback) without TF reverting it.
      # Remove this if you want TF to be the single soruce of truth for traffic.
      client,
      client_version,
    ]
  }
}
