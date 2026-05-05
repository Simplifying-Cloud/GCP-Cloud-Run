# Container registry
module "artifact_registry" {
  source = "../../../modules/artifact-registry"

  project_id = var.project_id
  region     = var.region
  name       = var.artifact_registry_name
}

# api
module "api" {
  source = "../../../modules/cloud-run-service"

  project_id = var.project_id
  region     = var.region
  name       = "api"
  image      = var.image_api
  domain     = var.domain_api

  allow_unauthenticated = true
  ingress               = "INGRESS_TRAFFIC_ALL"
}

# api-ai
module "api-ai" {
  source = "../../../modules/cloud-run-service"

  project_id = var.project_id
  region     = var.region
  name       = "api-ai"
  image      = var.image_api_ai
  domain     = var.domain_api_ai

  allow_unauthenticated = true
  ingress               = "INGRESS_TRAFFIC_ALL"
}
