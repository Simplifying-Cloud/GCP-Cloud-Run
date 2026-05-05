## Project bootstrap

#### Create project:
```bash
gcloud projects create <PROJECT_ID> --name="<NAME>"
```

#### Link billing account:
```bash
gcloud billing projects link <PROJECT_ID> --billing-account=<BILLING_ACCOUNT_ID>
```

#### Set as active project for gcloud:
```bash
gcloud config set project <PROJECT_ID>
```
#### Authenticate ADC as yourself:
```bash
gcloud auth application-default login
```
#### Set quota project:
```bash
gcloud auth application-default set-quota-project <PROJECT_ID>
```

#### Verify
```bash
gcloud projects describe <PROJECT_ID>
```

#### Deploy bootstrap resources (state storage bucket)
```bash
cd infra/bootstrap
terraform init
terraform plan -var-file=variables.tfvars #review this
terraform apply -var-file=variables.tfvars
```

#### Update TF code to manage resources using newly created bucket
The prior step produced output that contained `state_bucket_name`, record this, you'll use this to update `infra\bootstrap\providers.tf`.

#### Migrate TF state to the newly created GCP bucket
```bash
terraform init -migrate-state
```

#### Get current project context for docker image management
```bash
export PROJECT_ID=$(terraform output -raw artifact_registry_url | cut -d/ -f2)
export REGION=us-central1
export AR_URL=$(terraform output -raw artifact_registry_url)

echo "Project: $PROJECT_ID"
echo "Region:  $REGION"
echo "AR URL:  $AR_URL"
```

#### Configure Docker auth for AR
```bash
gcloud auth configure-docker ${REGION}-docker.pkg.dev
```

#### Tag image for AR
```bash
docker tag <URL>/<image> ${AR_URL}/<IMAGE>:<TAG>
# docker tag gcr.io/cloudrun/hello ${AR_URL}/hello:v1
```

#### Push image to AR
```bash
docker push ${AR_URL}/<IMAGE>:<TAG>
#docker push ${AR_URL}/hello:v1
```

#### Verify image in GCP AR
```bash
gcloud artifacts docker iamges list ${AR_URL} --include-tags
```
