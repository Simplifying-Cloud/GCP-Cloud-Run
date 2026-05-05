// create the bucket used for tf state storage
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

resource "google_storage_bucket" "tf_state" {
  name                        = local.tf_state_bucket
  location                    = local.region
  force_destroy               = true
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  versioning {
    enabled = true
  }
  lifecycle_rule {
    condition {
      days_since_noncurrent_time = 90
    }
    action {
      type = "Delete"
    }
  }
}
