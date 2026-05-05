// Cycle through the list of APIs and enable them for the project
resource "google_project_service" "api" {
  for_each = toset(local.apis)
  service  = each.key

  disable_on_destroy = false
}
