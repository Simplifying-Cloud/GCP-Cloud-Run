# cloud-run-service

Deploys a single Cloud Run v2 service with a dedicated runtime service account, optional public access, optional domain mapping, optional probes, and optional secret-backed env vars.

## Usage — minimal

```hcl
module "api_alpha" {
  source = "../../modules/cloud-run-service"

  project_id = "my-project-id"
  region     = "us-central1"
  name       = "api-alpha"
  image      = "gcr.io/cloudrun/hello"
}
```

## Usage — with custom domain and probes

```hcl
module "api_alpha" {
  source = "../../modules/cloud-run-service"

  project_id = "my-project-id"
  region     = "us-central1"
  name       = "api-alpha"
  image      = "us-central1-docker.pkg.dev/my-project-id/services/api-alpha:v1"

  domain = "alpha.example.com"

  env_vars = {
    LOG_LEVEL = "info"
  }

  secret_env_vars = {
    DB_PASSWORD = {
      secret_id = "db-password"
      version   = "latest"
    }
  }

  startup_probe = {
    path              = "/healthz"
    period_seconds    = 5
    failure_threshold = 10
  }

  liveness_probe = {
    path = "/healthz"
  }
}
```

## Notes

- Apex domains (`example.com`) are not supported by Cloud Run domain mapping. Use subdomains.
- Setting `min_instances > 0` incurs cost 24/7. Use only when cold starts violate SLO.
- The runtime service account is owned by this module. Grant it access to downstream resources (e.g. Secret Manager, Cloud SQL) using its email.
- For secret env vars, the runtime SA needs `roles/secretmanager.secretAccessor` on the secret, granted outside this module.
- Public traffic always arrives on `443`; Cloud Run terminates TLS and forwards to `container_port` (default `8080`). Override `container_port` if your app listens on a different port. The container must bind to `0.0.0.0:$PORT`, not `127.0.0.1`.

## Inputs

| Variable | Type | Default | Validation / Notes |
|---|---|---|---|
| `project_id` | string | n/a | Required. GCP project where the service is created. |
| `region` | string | n/a | Required. Cloud Run region. |
| `name` | string | n/a | Required. Must match `^[a-z]([a-z0-9-]*[a-z0-9])?$` and be 49 characters or fewer. |
| `image` | string | n/a | Required. Must be a container image URL with an immutable tag (never `:latest`). |
| `cpu` | number | `1` | CPU allocation per instance. Example values: `1`, `2`, `4`. Sub-CPU values like `0.5` or `0.25` are only valid when `min_instances = 0`. |
| `memory` | string | `512Mi` | Memory allocation per instance. Format must be like `512Mi` or `1Gi`. |
| `min_instances` | number | `0` | Minimum warm instances. `0` enables scale-to-zero. `>0` keeps instances warm constantly and incurs cost. |
| `max_instances` | number | `4` | Hard cap on instances. Cost guardrail. |
| `concurrency` | number | `80` | Requests per instance. Lower values reduce concurrency; `80` is Cloud Run default. |
| `timeout_seconds` | number | `30` | Request timeout in seconds. Max is `3600`. |
| `cpu_boost` | bool | `true` | Enables extra CPU during cold start for lower startup latency. |
| `container_port` | number | `8080` | Port the container listens on. Cloud Run terminates TLS on 443 and forwards traffic to this port; the value is also injected into the container as the `PORT` env var. |
| `ingress` | string | `INGRESS_TRAFFIC_INTERNAL_ONLY` | Controls allowed traffic sources. Valid values: `INGRESS_TRAFFIC_ALL`, `INGRESS_TRAFFIC_INTERNAL_ONLY`, `INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER`. Default blocks public traffic; only internal traffic may reach the service. |
| `allow_unauthenticated` | bool | `false` | When `true`, grants `roles/run.invoker` to `allUsers`, allowing unauthenticated public access. Default `false` requires callers to present a valid ID token. |
| `env_vars` | map(string) | `{}` | Environment variables passed into the container. |
| `secret_env_vars` | map(object({secret_id=string, version=optional(string, "latest")})) | `{}` | Secret Manager-backed environment variables. The runtime service account needs `roles/secretmanager.secretAccessor` on referenced secrets. |
| `startup_probe` | object or `null` | `null` | Optional startup probe. Set to `null` to skip. |
| `liveness_probe` | object or `null` | `null` | Optional liveness probe. Set to `null` to skip. |
| `domain` | string or `null` | `null` | Optional custom domain. Must be a non-apex hostname. If `null`, no domain mapping is created. |
| `labels` | map(string) | `{}` | Optional labels applied to the service and related resources. Keys should be lowercase. |

### Public service configuration

The module defaults are:

- `ingress = "INGRESS_TRAFFIC_INTERNAL_ONLY"` — service is only reachable from internal traffic sources.
- `allow_unauthenticated = false` — callers must authenticate with a valid ID token.

To host a public service, set:

```hcl
ingress               = "INGRESS_TRAFFIC_ALL"
allow_unauthenticated = true
```

This combination makes the Cloud Run service reachable from the public internet and allows unauthenticated access.

## Outputs

| Name | Description |
|---|---|
| `service_name` | Service name. |
| `service_url` | Default `*.run.app` URL. |
| `latest_ready_revision` | Name of most recent ready revision. |
| `runtime_service_account_email` | Runtime SA email. Used to grant downstream access. |
| `runtime_service_account_id` | Fully-qualified SA resource name. |
| `domain_mapping_records` | DNS records to add. `null` if no domain set. |
| `domain_mapping_status` | Domain mapping conditions (cert state). `null` if no domain set. |
