resource "google_artifact_registry_repository" "this" {
  project       = var.project_id
  location      = var.region
  repository_id = var.name
  format        = "DOCKER"
  description   = "Container images for ${var.name}"

  cleanup_policy_dry_run = false

  cleanup_policies {
    id     = "delete-untagged-after-7d"
    action = "DELETE"

    condition {
      tag_state  = "UNTAGGED"
      older_than = "604800s" # 7 days in seconds
    }
  }

  cleanup_policies {
    id     = "keep-last-10-tagged"
    action = "KEEP"

    most_recent_versions {
      keep_count = 10
    }
  }
}
