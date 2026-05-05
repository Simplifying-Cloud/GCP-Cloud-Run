# Runbook

Operational procedures for the deployed Cloud Run services. Each section is self-contained — copy the commands as-is, replacing `<placeholders>`.

Assumes you're authenticated:

```bash
gcloud auth login
gcloud config set project <project-id>
```

---

## Roll back to a previous revision

When a bad deploy is in production. Faster than redeploying a fixed image.

**1. List recent revisions for the affected service:**

```bash
gcloud run revisions list \
  --service=<service-name> \
  --region=us-central1 \
  --limit=10
```

Output shows revision names like `api-alpha-00007-abc`, with the `ACTIVE` column marking the one serving traffic.

**2. Shift 100% of traffic to a known-good revision:**

```bash
gcloud run services update-traffic <service-name> \
  --region=us-central1 \
  --to-revisions=<good-revision-name>=100
```

Takes effect within ~30 seconds.

**3. Update Terraform afterward** so state matches reality:

```bash
cd infra/envs/prod
terraform apply
```

> Apply will reset the image variable to whatever's in `terraform.tfvars`. Either update `terraform.tfvars` to point at the good image, or accept that next apply will redeploy the bad one. **Fix the image variable before running apply unprompted.**

---

## Increase capacity for a traffic spike

Temporarily raise warm capacity. Costs accrue while elevated.

**Quick (out-of-band, reverts on next `terraform apply`):**

```bash
gcloud run services update <service-name> \
  --region=us-central1 \
  --min-instances=5 \
  --max-instances=100
```

**Persistent (preferred — survives Terraform):**

Edit `infra/envs/prod/main.tf` for the affected module:

```hcl
module "api_alpha" {
  # ...
  min_instances = 5
  max_instances = 100
}
```

```bash
cd infra/envs/prod
terraform apply
```

**After the spike:** revert. `min_instances > 0` costs ~$15/mo per always-on instance.

---

## Rotate a secret

Cloud Run reads secrets at instance start. New secret values reach running instances when new revisions deploy.

**1. Add a new version of the secret:**

```bash
echo -n "<new-secret-value>" | \
  gcloud secrets versions add <secret-id> --data-file=-
```

**2. Force new revisions on services that consume it.** If the module references the secret with `version = "latest"`, redeploy the services:

```bash
cd infra/envs/prod
terraform apply -replace='module.<service-module-name>.google_cloud_run_v2_service.this'
```

If the module pins a specific version, edit `terraform.tfvars` (or the module call) to reference the new version, then `terraform apply`.

**3. Verify the new revision is serving:**

```bash
gcloud run revisions list --service=<service-name> --region=us-central1 --limit=3
```

**4. Disable the old version** once you're confident the new one works:

```bash
gcloud secrets versions disable <old-version-number> --secret=<secret-id>
```

> Don't *destroy* the old version immediately — disabling lets you re-enable in seconds if rollback is needed.

---

## Revoke CI/CD access

When a deployer SA is compromised, when an engineer leaves and had push access, or when GitHub Actions configuration is suspect.

**Immediate (stops all CI deploys within seconds):**

```bash
# Disable the deployer service account.
gcloud iam service-accounts disable \
  gha-deployer@<project-id>.iam.gserviceaccount.com
```

CI workflows attempting to authenticate now fail immediately.

**Permanent revocation (after investigation):**

```bash
# Remove the WIF binding so the GitHub identity can no longer impersonate the SA.
gcloud iam service-accounts remove-iam-policy-binding \
  gha-deployer@<project-id>.iam.gserviceaccount.com \
  --role=roles/iam.workloadIdentityUser \
  --member='principalSet://iam.googleapis.com/projects/<project-number>/locations/global/workloadIdentityPools/github-pool/attribute.repository/Simplifying-Cloud/<repo>'
```

Or destroy the entire WIF setup via Terraform:

```bash
cd infra/bootstrap
terraform apply -var=enable_wif=false
```

**Re-enabling later** requires a fresh `terraform apply` of bootstrap with `enable_wif = true`. Workflows then need no changes — the WIF provider name and SA email stay the same.

---

## Force cert re-provisioning

When a Cloud Run domain mapping cert is stuck or behaving oddly. Heavy hammer; usually unnecessary.

**1. Confirm DNS is correct:**

```bash
dig CNAME <subdomain.yourdomain.com>
```

Expected: `<subdomain>. <ttl> IN CNAME ghs.googlehosted.com.`

If anything else is returned (or Cloudflare proxy is in the way), fix DNS first — that's the actual problem.

**2. Recreate the domain mapping:**

```bash
cd infra/envs/prod
terraform apply -replace='module.<service-module-name>.google_cloud_run_domain_mapping.this[0]'
```

This destroys and recreates the mapping. Cert provisioning restarts (15–60 min). Service downtime during the window: requests to the custom domain return cert errors; the `*.run.app` URL is unaffected.

**3. Track progress:**

```bash
terraform refresh
terraform output <service>_domain_status
```

Wait until `Ready=True` and `CertificateProvisioned=True`.

---

## Manual image push (CI bypass)

When CI is broken but you need to ship.

```bash
cd infra/envs/prod

AR_URL=$(terraform output -raw artifact_registry_url)
TAG=$(date +%Y%m%d-%H%M)-manual

# Build and push
docker build --platform=linux/amd64 -t $AR_URL/<image-name>:$TAG <build-context>
docker push $AR_URL/<image-name>:$TAG

# Update terraform.tfvars to reference the new tag, then:
terraform apply
```

> **Tag with a date and `-manual` suffix** so it's obvious in image listings that this image bypassed CI. Fix CI before the next deploy.

---

## Diagnostic commands

**Live tail of service logs:**

```bash
gcloud run services logs tail <service-name> --region=us-central1
```

**Recent errors only:**

```bash
gcloud logging read \
  'resource.type="cloud_run_revision"
   resource.labels.service_name="<service-name>"
   severity>=ERROR' \
  --limit=50 \
  --format=json
```

**Service config as currently deployed:**

```bash
gcloud run services describe <service-name> --region=us-central1
```

**Active revision and traffic split:**

```bash
gcloud run services describe <service-name> --region=us-central1 \
  --format='value(status.traffic)'
```

**All recent deploys across both services:**

```bash
for svc in api-alpha api-bravo; do
  echo "=== $svc ==="
  gcloud run revisions list --service=$svc --region=us-central1 --limit=5
done
```
