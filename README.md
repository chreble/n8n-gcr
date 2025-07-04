![n8n on Google Cloud Run Architecture](public/images/header.png)

# n8n on Google Cloud Run

A complete Infrastructure as Code solution for deploying n8n (workflow automation platform) on Google Cloud Run with enterprise-grade security and cost optimization.

## ✨ Features

- **🚀 Serverless deployment** on Google Cloud Run with automatic scaling
- **🔒 Identity Aware Proxy (IAP)** protection with Google authentication  
- **💾 Flexible database options** - Cloud SQL or NeonDB PostgreSQL
- **🔑 Secure secret management** with Google Secret Manager
- **💰 Cost-efficient** with pay-per-use pricing and scale-to-zero capability
- **🔧 Modular architecture** with reusable OpenTofu/Terraform modules
- **🌐 HTTPS load balancer** with automatic SSL certificate management
- **⚡ Multiple deployment scenarios** for different use cases and budgets

## 🏗️ Architecture

This repository provides a **modular OpenTofu/Terraform architecture** with three pre-configured deployment scenarios:

| Scenario | Use Case | Monthly Cost | Database | Resources |
|----------|----------|--------------|----------|-----------|
| **Basic** | Personal projects, development | ~$3-10 | Cloud SQL (minimal) | 1 CPU, 1Gi RAM |
| **Production** | Business automation, teams | ~$50-150 | Cloud SQL (enhanced) | 2 CPU, 2Gi RAM |
| **NeonDB** | Cost optimization, serverless-first | ~$1-5 | NeonDB (serverless) | 1 CPU, 1Gi RAM |

## 🚀 Quick Start

### 1. Prerequisites

- Google Cloud account with billing enabled
- [OpenTofu](https://opentofu.org/docs/intro/install/) >= 1.10 or [Terraform](https://terraform.io/downloads) >= 1.4
- [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) installed and authenticated
- [Docker](https://docs.docker.com/get-docker/) installed

### 2. GCP project preparation (run **once**)

```bash
# Pick or create a dedicated project
gcloud projects create n8n-on-gcr --name="n8n on Cloud Run"   # ⇠ skip if the project already exists

# Set it as the default for your shell
gcloud config set project n8n-on-gcr

# Enable all services OpenTofu will need
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com \
  cloudbuild.googleapis.com \
  compute.googleapis.com \
  iam.googleapis.com

# Give YOUR user rights to deploy & build (Owner works too)
gcloud projects add-iam-policy-binding n8n-on-gcr \
  --member="user:YOUR_EMAIL@example.com" \
  --role="roles/editor"

# Allow Cloud Build to push the Docker image
PROJECT_NUM=$(gcloud projects describe n8n-on-gcr --format='value(projectNumber)')
gcloud projects add-iam-policy-binding n8n-on-gcr \
  --member="serviceAccount:${PROJECT_NUM}@cloudbuild.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# (Optional) If you plan to use IAP you must move the project under an Organisation first.
```

You are now ready to let OpenTofu create infrastructure in **n8n-on-gcr**.

### 3. Deploy Infrastructure

```bash
# Clone the repository
git clone <repository-url>
cd n8n-gcr/iac

# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values and choose database type
nano terraform.tfvars

# Deploy
tofu init
tofu apply
```

💡 **First-time tip:** set `container_image = "placeholder"` (or any dummy tag) in `terraform.tfvars`. OpenTofu just needs a valid string; the real image will be built and deployed by the GitHub Action in the next step.

### 4. Build and Deploy Container

```bash
# Configure Docker authentication
gcloud auth configure-docker $(tofu output -raw container_repository_url)

# Build and push the n8n image
IMAGE_NAME="$(tofu output -raw container_repository_url)/n8n:latest"
docker build --platform linux/amd64 -t $IMAGE_NAME .
docker push $IMAGE_NAME

# Update Cloud Run with the new image
tofu apply
```

> **Artifact Registry permissions**  
> The principal that performs the `gcloud builds submit` or `docker push` **must** have  
> `roles/artifactregistry.writer` on the project (and `roles/logging.logWriter` if you use Cloud Build).  
> • Local push → grant the role to your user ( `user:you@example.com` ).  
> • GitHub Actions → grant it to the Cloud Build service-account:  
> `PROJECT_NUM=$(gcloud projects describe n8n-on-gcr --format='value(projectNumber)')`  
> `gcloud projects add-iam-policy-binding n8n-on-gcr --member="serviceAccount:${PROJECT_NUM}@cloudbuild.gserviceaccount.com" --role="roles/artifactregistry.writer"`

### 4. Access Your n8n Instance

Your n8n instance will be available at the URL shown in the `n8n_url` output, protected by Google Identity Aware Proxy authentication.

## 📋 Configuration

### Required Configuration

```hcl
# terraform.tfvars
gcp_project_id = "your-project-id"
db_password = "secure-database-password"  
n8n_encryption_key = "your-very-long-random-encryption-key-32-chars-minimum"
iap_authorized_users = ["your-email@example.com"]
```

### Database Options

**Cloud SQL** (Managed PostgreSQL):
- Consistent performance
- Integrated backups and monitoring
- Best for production workloads

**NeonDB** (Serverless PostgreSQL):
- True serverless, scales to zero
- Pay-per-use pricing
- Global replication
- **Automatic provisioning** with OpenTofu/Terraform
- Best for cost optimization

## 🔒 Security

Your n8n instance is automatically secured with:

- **Identity Aware Proxy (IAP)**: Google SSO authentication required
- **Authorized users only**: Email-based access control
- **HTTPS-only**: Automatic SSL certificates and HTTP redirect
- **Secret Manager**: Encrypted storage for sensitive data
- **Private networking**: Service only accessible through load balancer

### Managing Access

To grant access to additional users:

1. Add email addresses to `iap_authorized_users` in `terraform.tfvars`
2. Run `tofu apply` to update IAM policies

## 📁 Repository Structure

```
n8n-gcr/
├── iac/                    # OpenTofu/Terraform infrastructure
│   ├── modules/           # Reusable infrastructure modules  
│   └── README.md         # Detailed technical documentation
├── contrib/               # Community contributions
└── docs/                 # Project documentation and delivery tracking
```

## 📚 Documentation

- **[Infrastructure Documentation](iac/README.md)** - Detailed technical documentation for the modular architecture
- **[NeonDB Setup Guide](docs/neondb-setup.md)** - Automatic database provisioning with OpenTofu
- **[Automation Setup](docs/automation-setup.md)** - GitHub Actions for automated n8n updates

## 🔧 Advanced Usage

### Custom Domain

```hcl
domain_name = "n8n.yourdomain.com"
```

After deployment, create a DNS A record pointing to the `load_balancer_ip` output.

### Google OAuth Integration

For connecting n8n with Google services (Sheets, Drive, etc.):

1. Enable required APIs in Google Cloud Console
2. Configure OAuth consent screen
3. Create OAuth client ID with your n8n URL
4. Use client credentials in n8n Google service configurations

### Updating n8n

#### Automated Updates (Recommended)

Set up GitHub Actions for automatic n8n updates:

```bash
# See detailed setup guide
open docs/automation-setup.md
```

**Features:**
- 🔄 Daily monitoring of n8n releases
- 🚀 Automatic Docker builds and pushes
- 📦 GitHub releases with version tracking
- 🎯 Optional auto-deployment to development

#### GitHub Variables & Secrets

> Configure these in **Repository → Settings → Secrets and variables → Actions** so the `n8n-auto-update` workflow can build images and (optionally) deploy them.

**Repository secrets**

| Name | Purpose |
|------|---------|
| `GCP_SA_KEY` | JSON key for the Google Cloud service account that can push to Artifact Registry and deploy to Cloud Run |

**Repository variables**

| Name | Example | Purpose |
|------|---------|---------|
| `GCP_PROJECT_ID` | `my-gcp-project` | Primary Google Cloud project that hosts Artifact Registry and Cloud Run |
| `GCP_REGION` | `europe-west1` | (Optional) Default region for builds and deployments (defaults to `europe-west1` when omitted) |
| `CLOUD_RUN_SERVICE_NAME` | `n8n` | (Optional) Cloud Run service name to update after each build |
| `AUTO_DEPLOY_DEV` | `false` | `true` to automatically deploy the image to the dev environment after a successful build |
| `GCP_PROJECT_ID_PROD` | `my-prod-project` | (Optional) Additional project ID to include in the build matrix for production |
| `AUTO_DEPLOY_PROD` | `false` | (Optional) Flag to auto-deploy to production project if enabled |

For a step-by-step walk-through, see the [Automation Setup](docs/automation-setup.md) guide.

#### Manual Updates

```bash
# Pull latest n8n image and rebuild
docker pull docker.n8n.io/n8nio/n8n:latest
IMAGE_NAME="$(tofu output -raw container_repository_url)/n8n:latest"
docker build --platform linux/amd64 -t $IMAGE_NAME .
docker push $IMAGE_NAME

# Deploy update
tofu apply
```

## 💡 Cost Optimization Tips

1. **Choose the right scenario**: Use Basic or NeonDB for development, Production for business use
2. **Scale to zero**: Keep `min_instances = 0` to avoid idle costs
3. **Monitor usage**: Set up billing alerts in Google Cloud Console
4. **Database sizing**: Start with minimal tiers and scale up as needed
5. **Regional deployment**: Choose regions close to your users

## 🤝 Contributing

We welcome contributions! See the [contributing guide](CONTRIBUTING.md) for details on:

- Adding new deployment scenarios
- Improving the modular architecture  
- Documentation improvements
- Community examples and use cases

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: Report bugs and request features via GitHub Issues
- **Discussions**: Join the community discussion for questions and tips
- **Documentation**: Comprehensive guides available in the [iac/README.md](iac/README.md)

## 🛠️ Troubleshooting

### IAP shows "Error: Forbidden"
If you reach a Google page that says "Error: Forbidden" after signing in:

1. Confirm the email you authenticated with is **exactly** one of the addresses in `iap_authorized_users` in `terraform.tfvars`.
2. Run `tofu apply` again to ensure OpenTofu created the IAM binding (`google_iap_web_iam_member`).
3. Open the URL in an Incognito/Private window, click **Use another account**, and sign-in with the authorised address.
4. If you still see the error, wait ~60 s – IAM changes can take a minute to propagate.

> Quick check
> ```bash
> gcloud iap web get-iam-policy --project $PROJECT_ID \
>   --format="table(bindings.role, bindings.members)" | grep iap.httpsResourceAccessor
> ```
> Your email must appear under `roles/iap.httpsResourceAccessor`.

---

### "service account … does not exist" during `tofu apply`
OpenTofu creates the IAP service agent **service-${PROJECT_NUMBER}@gcp-sa-iap.iam.gserviceaccount.com** and then grants it `roles/run.invoker` on Cloud Run.  In new projects this account can take a few seconds to become visible. OpenTofu now waits 30 s (`time_sleep.wait_for_iap_sa`) but if you still hit the race re-run `tofu apply`.

---

### Blank page saying **"Rate exceeded"**
This comes from NeonDB when the free-tier connection limit is exceeded.

* The stack now connects through Neon's built-in PgBouncer pooler endpoint (`-pooler.neon.tech`) and sets `DB_POSTGRESDB_POOL_SIZE=5` which is well within limits.
* If you changed `DB_POSTGRESDB_POOL_SIZE` or opened many browser tabs, close extras or lower the value and re-deploy.

---

### Neon **region not valid** error
Neon expects region codes like `aws-us-east-1` or `aws-eu-central-1` – *not* regular AWS regions.  Set an appropriate value for `neon_region` in `terraform.tfvars`, for example:

```hcl
neon_region = "aws-eu-central-1"  # Frankfurt
```

Full list: https://neon.tech/docs/introduction/regions

---

### Where is my n8n URL?
After `tofu apply` finishes, run:

```bash
tofu output n8n_url
```

If you did not set `domain_name`, the output will be a **nip.io** host that already resolves to the load-balancer IP and has a valid SSL certificate.

---

**Ready to automate your workflows?** Choose your deployment scenario and get started in minutes! 🚀 

## 👤 About the Author

<p align="center">
  <a href="https://github.com/chreble" target="_blank">
    <img src="https://github.com/chreble.png" width="100" height="100" alt="Christian Eble GitHub avatar" />
  </a>
</p>

**Christophe EBLE** ([chreble](https://github.com/chreble)) is the maintainer of this repository. If you find this project useful, feel free to ⭐ the repo and drop him a note!
