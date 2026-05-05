resource "google_cloud_run_domain_mapping" "this" {
  count = var.domain == null ? 0 : 1

  project  = var.project_id
  location = var.region
  name     = var.domain

  metadata {
    namespace = var.project_id
  }

  spec {
    route_name = google_cloud_run_v2_service.this.name
  }
}
