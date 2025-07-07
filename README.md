# n8n on Google Cloud Run

This directory contains a modular OpenTofu architecture for deploying n8n (workflow automation platform) on Google Cloud Run with Identity Aware Proxy (IAP) protection.

## 🏗️ Architecture Overview

The deployment is organized into focused, reusable modules:

```
├── modules/
│   ├── secrets/     # Secret Manager resources and IAM policies
│   ├── database/    # Cloud SQL PostgreSQL or external database support
│   ├── container/   # Artifact Registry for Docker images
│   ├── compute/     # Cloud Run service and service account
│   └── iap/         # Load balancer, IAP, and SSL certificates

├── main.tf          # Root module orchestration
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── locals.tf        # Local values and naming conventions
└── versions.tf      # Provider requirements
```

## 🚀 Quick Start

### 1. Prerequisites

- [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) installed and authenticated
- [OpenTofu](https://opentofu.org/docs/intro/install/) >= 1.6 installed
- [Docker](https://docs.docker.com/get-docker/) installed
- A Google Cloud project with billing enabled

> **Note**: This configuration is compatible with both OpenTofu and Terraform. We recommend OpenTofu as it's the open-source fork that maintains full compatibility while being truly community-driven.

### 2. Basic Deployment

```bash
# Copy and customize the configuration
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values

# Initialize and deploy
tofu init
tofu plan
tofu apply
```

### 3. Container Image Setup

Before the first deployment, build and push your n8n container:

```bash
# Build the custom n8n image
docker build --platform linux/amd64 -t REGION-docker.pkg.dev/PROJECT_ID/REPO_NAME/n8n:latest .

# Configure Docker authentication
gcloud auth configure-docker REGION-docker.pkg.dev

# Push the image
docker push REGION-docker.pkg.dev/PROJECT_ID/REPO_NAME/n8n:latest
```

### 4. Automatic n8n Version Upgrades

Want n8n to update itself whenever a new upstream release appears?  Cloud Build
supports **scheduled triggers** (no external GitHub Actions required).

1.  Create a new build config at `.cloudbuild/cloudbuild-upgrade.yaml`:

```yaml
# cloudbuild-upgrade.yaml – nightly check & build the latest n8n
options:
  logging: CLOUD_LOGGING_ONLY
substitutions:
  _REGION: europe-west1
  _REPO_NAME: n8n-repo
steps:
# --- Detect latest upstream version ---------------------------------
- name: ubuntu
  id: fetch-version
  entrypoint: /bin/bash
  args:
    - -c
    - |
      set -e
      LATEST=$(curl -s https://api.github.com/repos/n8n-io/n8n/releases/latest | jq -r '.tag_name' | sed 's/^n8n@//')
      echo "LATEST=$LATEST" >> $BUILD_ENV/substitutions.env

# --- Build & push image (skipped if already present) ----------------
- name: gcr.io/cloud-builders/docker
  id: build-push
  entrypoint: /bin/bash
  args:
    - -c
    - |
      source $BUILD_ENV/substitutions.env
      IMAGE="$_REGION-docker.pkg.dev/$PROJECT_ID/$_REPO_NAME/n8n:$LATEST"
      if gcloud artifacts docker images describe "$IMAGE" >/dev/null 2>&1; then
        echo "Image $IMAGE already exists – nothing to do." && exit 0
      fi
      docker build -t "$IMAGE" --build-arg N8N_VERSION="$LATEST" --platform linux/amd64 .
      docker push "$IMAGE"

# --- Terraform apply ------------------------------------------------
- name: hashicorp/terraform:1.10.2
  id: deploy
  dir: infrastructure
  entrypoint: /bin/sh
  args:
    - -c
    - |
      source $BUILD_ENV/substitutions.env
      tofu init && tofu apply -auto-approve -var "container_image=$_REGION-docker.pkg.dev/$PROJECT_ID/$_REPO_NAME/n8n:$LATEST"
```

2.  Create a scheduled trigger that runs every morning:

```bash
gcloud builds triggers create schedule \
  --name="n8n-nightly-upgrade" \
  --schedule="0 6 * * *" \
  --build-config=.cloudbuild/cloudbuild-upgrade.yaml \
  --substitutions=_REGION="europe-west1",_REPO_NAME="n8n-repo"
```

The trigger:
• Pulls the latest release version from GitHub
• Skips the build if the exact tag already exists in Artifact Registry
• Otherwise builds the new image, pushes it, and runs `tofu apply` so Cloud Run
  is updated – fully automated!

## 🔄 Continuous Deployment with Cloud Build

Google Cloud Build can automatically build, push, and **apply your IaC** every
time you push to your repository (Cloud Source Repositories, GitHub, or
Bitbucket).  The basic flow is:

1. A commit is pushed to the main branch.
2. Cloud Build builds the Docker image and pushes it to Artifact Registry.
3. Cloud Build runs `tofu apply` so the new image is rolled out via your
   Terraform/OpenTofu code (keeps all changes in IaC).

### 1. Enable the API & grant permissions

```bash
# Enable Cloud Build and Artifact Registry APIs
gcloud services enable cloudbuild.googleapis.com artifactregistry.googleapis.com

# Allow Cloud Build to deploy to Cloud Run & read secrets
PROJECT_ID=$(gcloud config get-value project)
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member=serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
  --role=roles/run.admin

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member=serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
  --role=roles/iam.serviceAccountUser
```

### 2. `cloudbuild.yaml`

Place the following file at the root of the repo (or in
`.cloudbuild/cloudbuild.yaml`).  It:

1. Builds an n8n image tagged with the commit SHA
2. Pushes the image to Artifact Registry
3. Runs `tofu init` & `tofu apply` to roll the Cloud Run service to the new
   image (and apply any other infra changes)

```yaml
# cloudbuild.yaml
substitutions:
  _REGION: europe-west1        # ↳ override in the trigger if needed
  _REPO_NAME: n8n-repo         # ↳ must match modules/container repository
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: ['build','-t','$_REGION-docker.pkg.dev/$PROJECT_ID/$_REPO_NAME/n8n:$SHORT_SHA','--platform','linux/amd64','.']

- name: 'gcr.io/cloud-builders/docker'
  args: ['push','$_REGION-docker.pkg.dev/$PROJECT_ID/$_REPO_NAME/n8n:$SHORT_SHA']

# === IaC deployment ===
- name: 'hashicorp/terraform:1.10.2'
  entrypoint: /bin/sh
  dir: 'infrastructure'   # ↳ path containing your *.tf files
  args:
    - '-c'
    - |
      tofu init && \
      tofu apply -auto-approve -var "container_image=$_REGION-docker.pkg.dev/$PROJECT_ID/$_REPO_NAME/n8n:$SHORT_SHA"
images:
- '$_REGION-docker.pkg.dev/$PROJECT_ID/$_REPO_NAME/n8n:$SHORT_SHA'
```

### 3. Create the trigger

Create a Cloud Build trigger that fires on a commit to your
`main` (or whichever) branch.  Example for **Cloud Source Repositories**:

```bash
gcloud builds triggers create cloud-source-repos \
  --repo=n8n-gcr \
  --branch-pattern="^main$" \
  --build-config=cloudbuild.yaml \
  --substitutions=_REGION="europe-west1",_REPO_NAME="n8n-repo"
```

If you host code on GitHub or Bitbucket, choose the corresponding trigger type
in the Cloud Build UI – the `cloudbuild.yaml` stays the same.

Every push now builds the image **and** applies infrastructure changes in a
single pipeline – no separate GitHub Actions required.

## 📋 Configuration

### Required Variables

```hcl
# terraform.tfvars
gcp_project_id = "your-project-id"
iap_authorized_users = ["your-email@example.com"]
```

### Key Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `gcp_project_id` | Google Cloud project ID | - | ✅ |
| `iap_authorized_users` | Authorized user emails | - | ✅ |
| `database_type` | Database type: `cloud_sql` or `neon` | `"cloud_sql"` | ❌ |
| `neon_host` | NeonDB host (if using NeonDB) | `""` | ❌ |
| `environment` | Environment name | `"dev"` | ❌ |
| `gcp_region` | Google Cloud region | `"us-west2"` | ❌ |
| `domain_name` | Custom domain (optional) | `""` | ❌ |
| `cloud_run_cpu` | CPU allocation | `"2"` | ❌ |
| `cloud_run_memory` | Memory allocation | `"2Gi"` | ❌ |

## 🔒 Security Features

### Always-On Security

- **Identity Aware Proxy (IAP)**: Google authentication required for all access
- **Secret Manager**: Secure storage for database passwords and encryption keys
- **HTTPS-only**: Automatic HTTP to HTTPS redirect
- **Private Cloud Run**: Service only accessible through load balancer
- **Least privilege IAM**: Service accounts with minimal required permissions

### IAP Configuration

IAP provides enterprise-grade access control:

```hcl
iap_authorized_users = [
  "admin@company.com",
  "team@company.com"
]
```

Users must authenticate with Google and be on the authorized list to access n8n.

## 🏗️ Module Documentation

### Secrets Module (`modules/secrets/`)

Manages Secret Manager resources and IAM policies for secure credential storage.

**Resources**:
- Secret Manager secrets for database password and n8n encryption key
- IAM bindings for service account access

### Database Module (`modules/database/`)

Manages Cloud SQL PostgreSQL instance optimized for n8n workloads. Alternatively, supports external databases like NeonDB.

**Features**:
- Configurable instance tiers (cost vs performance)
- Environment-based backup policies
- Connection logging for troubleshooting
- Automatic deletion protection in production
- Support for external PostgreSQL providers (NeonDB, etc.)

### Container Module (`modules/container/`)

Manages Artifact Registry for storing custom n8n Docker images.

**Features**:
- Docker format repository
- Regional storage for performance
- Integrated with Cloud Run deployment

### Compute Module (`modules/compute/`)

Manages Cloud Run service, service account, and container configuration.

**Features**:
- Serverless scaling (0-N instances)
- Cloud SQL proxy integration
- Comprehensive environment variable management
- Health checks and startup probes

### IAP Module (`modules/iap/`)

Manages load balancer, IAP configuration, and SSL certificates.

**Features**:
- Global HTTPS load balancer
- OAuth2 client and brand configuration
- Google-managed SSL certificates
- HTTP to HTTPS redirect
- Network Endpoint Group for Cloud Run

## 🎯 Database Options

Choose between two database providers by setting the `database_type` variable:

### Cloud SQL (Google Cloud)
- **Use case**: Production workloads, enterprise environments
- **Cost**: ~$15-100/month (depending on tier)
- **Features**: Managed PostgreSQL, automatic backups, monitoring
- **Configuration**: Set `database_type = "cloud_sql"`

### NeonDB (Serverless PostgreSQL)
- **Use case**: Cost optimization, development, serverless-first
- **Cost**: ~$1-5/month (auto-scaling)
- **Features**: Serverless database, automatic provisioning, global replication
- **Configuration**: Set `database_type = "neon"` and provide `neon_api_key`

## 🔧 Customization

### Environment-Specific Configuration

The `environment` variable affects resource configuration:

- **dev**: Minimal resources, no backups, no deletion protection
- **prod**: Enhanced resources, backups enabled, deletion protection

### Custom Domain Setup

1. Set `domain_name` variable
2. Deploy infrastructure
3. Configure DNS A record to point to the load balancer IP
4. SSL certificate auto-provisions once DNS propagates

### Resource Scaling

Adjust resources based on your workload:

```hcl
# For heavy workloads
cloud_run_cpu = "4"
cloud_run_memory = "8Gi"
cloud_run_max_instances = 10
db_tier = "db-n1-standard-2"
```

## 📊 Monitoring and Troubleshooting

### Useful Commands

```bash
# Check deployment status
tofu output

# View resource state
tofu state list

# Debug IAP issues
gcloud compute backend-services get-health BACKEND_NAME --global

# Check Cloud Run logs
gcloud run services logs read n8n --region=REGION
```

### Common Issues

1. **"Container not found"**: Build and push the n8n container first
2. **"IAP access denied"**: Verify user email in `authorized_users` list
3. **"SSL certificate pending"**: Check DNS configuration and propagation
4. **"Database connection failed"**: Verify Cloud SQL proxy settings

## 💰 Cost Optimization

### Development
- Use `db-f1-micro` instance
- Set `min_instances = 0` for Cloud Run
- Single region deployment

### Production
- Consider `db-n1-standard-1` for better performance
- Set appropriate `max_instances` based on usage
- Enable monitoring for cost tracking

## 🔄 Updates and Maintenance

### Updating n8n

1. Build new container image with updated n8n version
2. Push to Artifact Registry
3. Run `tofu apply` to deploy

### Adding Users

1. Update `iap_authorized_users` in terraform.tfvars
2. Run `tofu apply`
3. Users can immediately access after Google authentication

### Backup and Recovery

- **Development**: No automatic backups (cost optimization)
- **Production**: Automatic backups enabled
- Manual backups can be triggered via Google Cloud Console

## 📚 Additional Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Identity Aware Proxy Documentation](https://cloud.google.com/iap/docs)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

## 🤝 Contributing

To contribute improvements:

1. Test changes with minimal configurations first
2. Ensure backward compatibility
3. Update documentation for any new variables or features
4. Follow OpenTofu/Terraform best practices for module design

**You're ready!**
This workflow ensures a clean, repeatable, and secure setup for your infrastructure. 