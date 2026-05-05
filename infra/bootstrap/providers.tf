terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "gcs" {
    bucket = "tutorial-495118-terraform-state-e83295c9d22067d7"
    prefix = "bootstrap"
  }
}

provider "google" {
  project = local.project_id
  region  = local.region
}
