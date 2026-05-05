#_iam_policy — authoritative; replaces the entire policy. Dangerous; can lock you out.
#_iam_binding — authoritative for one role; replaces all members for that role.
#_iam_member — additive; adds one member to one role. Won't fight other tooling.
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  count = var.allow_unauthenticated ? 1 : 0

  project  = google_cloud_run_v2_service.this.project
  location = google_cloud_run_v2_service.this.location
  name     = google_cloud_run_v2_service.this.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
