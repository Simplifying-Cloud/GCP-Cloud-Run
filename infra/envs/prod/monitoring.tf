# Notification channel
resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "Ops Email"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }
}

# Log-based metric:  count of 5xx responses per service
resource "google_logging_metric" "cloud_run_5xx" {
  project = var.project_id
  name    = "cloud_run_5xx"

  filter = <<-EOT
    resource.type="cloud_run_revision"
    httpRequest.status >= 500
    httpRequest.status < 600
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"

    labels {
      key         = "service_name"
      value_type  = "STRING"
      description = "Cloud Run service emitting the 5xx."
    }
  }

  label_extractors = {
    "service_name" = "EXTRACT(resource.labels.service_name)"
  }
}

# Alert:  5xx rate elevated for 5 minutes
resource "google_monitoring_alert_policy" "cloud_run_5xx" {
  project      = var.project_id
  display_name = "Cloud Run 5xx elevated"
  combiner     = "OR"

  notification_channels = [google_monitoring_notification_channel.email.id]

  conditions {
    display_name = "5xx rate > 0.05/s for 5min"

    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"logging.googleapis.com/user/${google_logging_metric.cloud_run_5xx.name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.05

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["metric.label.service_name"]
      }

      trigger {
        count = 1
      }
    }
  }

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "Cloud Run service is returning 5xx responses above the threshold.  Check recent revisions and roll back if needed:  gcloud run services update-traffic <svc> --to-revisions=<prev>=100"
    mime_type = "text/markdown"
  }
}

# Uptime checks (one per service)
resource "google_monitoring_uptime_check_config" "api" {
  project      = var.project_id
  display_name = "api uptime"
  timeout      = "10s"
  period       = "60s" // this is the minimum period allowed by GCP, but it can be set higher if desired

  http_check {
    path           = "/"
    port           = 443
    use_ssl        = true
    validate_ssl   = true
    request_method = "GET"
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = replace(replace(module.api.service_url, "https://", ""), "/", "")
    }
  }
}

resource "google_monitoring_uptime_check_config" "api-ai" {
  project      = var.project_id
  display_name = "api-ai uptime"
  timeout      = "10s"
  period       = "60s" // this is the minimum period allowed by GCP, but it can be set higher if desired

  http_check {
    path           = "/"
    port           = 443
    use_ssl        = true
    validate_ssl   = true
    request_method = "GET"
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = replace(replace(module.api-ai.service_url, "https://", ""), "/", "")
    }
  }
}

# SLO:  api 99.9% availability based on uptime check, 99.9% availability over 28d rolling
resource "google_monitoring_custom_service" "api" {
  project      = var.project_id
  service_id   = "api"
  display_name = "API"
}

resource "google_monitoring_slo" "api_availability" {
  project      = var.project_id
  service      = google_monitoring_custom_service.api.service_id
  slo_id       = "availability-99-9"
  display_name = "api 99.9% availability (28d rolling)"

  goal                = 0.999
  rolling_period_days = 28

  request_based_sli {
    good_total_ratio {
      good_service_filter  = <<-EOT
        resource.type="cloud_run_revision"
        resource.labels.service_name="api"
        metric.type="run.googleapis.com/request_count"
        metric.labels.response_code_class!="5xx"
      EOT
      total_service_filter = <<-EOT
        resource.type="cloud_run_revision"
        resource.labels.service_name="api"
        metric.type="run.googleapis.com/request_count"
      EOT
    }
  }
}

# SLO:  api-ai 99.9% availability based on uptime check, 99.9% availability over 28d rolling
resource "google_monitoring_custom_service" "api-ai" {
  project      = var.project_id
  service_id   = "api-ai"
  display_name = "API-AI"
}

resource "google_monitoring_slo" "api-ai_availability" {
  project      = var.project_id
  service      = google_monitoring_custom_service.api-ai.service_id
  slo_id       = "availability-99-9"
  display_name = "api-ai 99.9% availability (28d rolling)"

  goal                = 0.999
  rolling_period_days = 28

  request_based_sli {
    good_total_ratio {
      good_service_filter  = <<-EOT
        resource.type="cloud_run_revision"
        resource.labels.service_name="api-ai"
        metric.type="run.googleapis.com/request_count"
        metric.labels.response_code_class!="5xx"
      EOT
      total_service_filter = <<-EOT
        resource.type="cloud_run_revision"
        resource.labels.service_name="api-ai"
        metric.type="run.googleapis.com/request_count"
      EOT
    }
  }
}
