# artifact-registry

Creates a regional Artifact Registry Docker repository with a cleanup policy.

## Cleanup policy

- Untagged images deleted after 7 days
- Keeps most recent 10 tagged images per package

## Usage

```hcl
module "container_registry" {
  source = "../../modules/artifact-registry"

  project_id = "my-project-id"
  region     = "us-central1"
  name       = "services"
}

output "registry_url" {
  value = module.container_registry.repository_url
}
```

## Inputs

| Name | Type | Required | Description |
|---|---|---|---|
| `project_id` | string | yes | GCP project ID. |
| `region` | string | yes | Region for the repo. Match Cloud Run region. |
| `name` | string | yes | Repo name. Lowercase, hyphens allowed. |

## Outputs

| Name | Description |
|---|---|
| `repository_id` | Short repo name. |
| `repository_url` | Full Docker push/pull URL. |
| `repository_name` | Fully-qualified resource name (for IAM). |
