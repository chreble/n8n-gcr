# Automated n8n Updates Setup Guide

This guide explains how to set up automated n8n updates using GitHub Actions that will monitor for new n8n releases and automatically build/deploy updated container images.

## 🚀 Features

- **Daily monitoring** of n8n releases from the official repository
- **Automatic Docker builds** with multi-architecture support (amd64, arm64)
- **Version tagging** and GitHub releases for tracking
- **Optional auto-deployment** to development environments
- **Manual trigger** options for specific versions or forced builds
- **Dependency updates** via Dependabot for GitHub Actions and Terraform

## 📋 Prerequisites

Before setting up automation, ensure you have:

1. A GitHub repository with this n8n-gcr project
2. Google Cloud Project with necessary APIs enabled
3. Artifact Registry repository created
4. Service account with appropriate permissions

### Password and Key Auto-Generation

**For NeonDB users:** Both database passwords and n8n encryption keys are automatically generated during deployment and stored securely. You can omit both `db_password` and `n8n_encryption_key` in your terraform.tfvars for fully automated CI/CD workflows when using `database_type = "neon"`.

**For Cloud SQL users:** Database passwords **can now also be auto-generated**. If you leave `db_password` empty, the system will generate a secure password and store it in Secret Manager automatically. n8n encryption keys can likewise be left empty for auto-generation.

## 🔧 Setup Instructions

### 1. Create Google Cloud Service Account

Create a service account for GitHub Actions with these roles:

```bash
# Create service account
gcloud iam service-accounts create github-actions \
  --display-name="GitHub Actions" \
  --description="Service account for GitHub Actions automation"

# Grant necessary roles
PROJECT_ID="your-project-id"
SA_EMAIL="github-actions@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/run.developer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.serviceAccountUser"

# Create and download key
gcloud iam service-accounts keys create github-actions-key.json \
  --iam-account="${SA_EMAIL}"
```

### 2. Configure GitHub Repository

#### A. Add Repository Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these **Repository Secrets**:

| Secret Name | Value | Description |
|-------------|--------|-------------|
| `GCP_SA_KEY` | Contents of `github-actions-key.json` | Google Cloud service account key |

#### B. Add Repository Variables

Add these **Repository Variables**:

| Variable Name | Value | Description |
|---------------|--------|-------------|
| `GCP_PROJECT_ID` | `your-project-id` | Primary Google Cloud project ID |
| `GCP_REGION` | `us-west2` | Google Cloud region (optional) |
| `CLOUD_RUN_SERVICE_NAME` | `n8n` | Cloud Run service name (optional) |
| `AUTO_DEPLOY_DEV` | `false` | Enable auto-deployment to dev (optional) |

#### C. Optional: Multiple Environments

For multiple environments, add additional variables:

| Variable Name | Value | Description |
|---------------|--------|-------------|
| `GCP_PROJECT_ID_PROD` | `your-prod-project-id` | Production project ID |
| `AUTO_DEPLOY_PROD` | `false` | Enable auto-deployment to prod |

### 3. Configure Dependabot (Optional)

Update `.github/dependabot.yml` to replace `@me` with your GitHub username:

```yaml
reviewers:
  - "yourusername"  # Replace with your actual GitHub username
```

### 4. Test the Workflow

#### Manual Testing

1. Go to your GitHub repository
2. Navigate to Actions → "N8N Auto Update and Build"
3. Click "Run workflow"
4. Choose options:
   - ☑️ Force build even if no new version
   - Leave n8n version empty for latest
5. Click "Run workflow"

#### Verify Setup

Check that the workflow:
- ✅ Detects n8n versions correctly
- ✅ Builds Docker images successfully
- ✅ Pushes to Artifact Registry
- ✅ Creates GitHub releases and tags

## 🔄 How It Works

### Automated Schedule

The workflow runs **daily at 6 AM UTC** and:

1. **Checks** the latest n8n release from GitHub API
2. **Compares** with the last built version (git tags)
3. **Builds** new Docker image if version differs
4. **Pushes** to your Artifact Registry
5. **Creates** GitHub release with version details
6. **Optionally deploys** to development environment

### Version Tracking

- **Git Tags**: `v1.2.3` format for tracking built versions
- **GitHub Releases**: Automatic release notes with changelog links
- **Container Tags**: Both versioned (`1.2.3`) and `latest` tags

### Build Process

The workflow:
- Uses **Docker Buildx** for multi-architecture builds
- Updates **Dockerfile** to specific n8n version
- Builds for **linux/amd64** and **linux/arm64**
- Pushes to your **Artifact Registry**

## 🎯 Usage Scenarios

### Scenario 1: Fully Automated (Recommended for Dev)

```yaml
# Repository Variables
AUTO_DEPLOY_DEV: "true"
```

- Daily checks for updates
- Automatic builds and deployments to dev environment
- GitHub releases for tracking

### Scenario 2: Build Only (Recommended for Production)

```yaml
# Repository Variables  
AUTO_DEPLOY_DEV: "false"
```

- Daily checks and builds
- Manual deployment approval required
- Use GitHub releases to track available versions

### Scenario 3: Manual Control

- Disable scheduled runs by commenting out the `schedule` trigger
- Use manual workflow triggers when needed
- Full control over timing and versions

## 🚨 Troubleshooting

### Common Issues

**Build Failures:**
- Check service account permissions
- Verify Artifact Registry exists
- Ensure Docker buildx is working

**Authentication Issues:**
- Verify `GCP_SA_KEY` secret is correctly formatted JSON
- Check service account has necessary roles
- Ensure project ID is correct

**Version Detection Issues:**
- Check if n8n API is accessible
- Verify git tags are in correct format (`v1.2.3`)
- Look at workflow logs for API responses

### Debug Commands

```bash
# Test local Docker build
cd iac
docker build --platform linux/amd64 -t test-n8n .

# Check Artifact Registry
gcloud artifacts repositories list

# Verify service account permissions
gcloud projects get-iam-policy YOUR_PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:github-actions@*"
```

## 🔒 Security Considerations

1. **Service Account**: Uses minimal required permissions
2. **Secrets Management**: GitHub Secrets are encrypted at rest
3. **Registry Access**: Limited to specific Artifact Registry
4. **Branch Protection**: Only main branch can trigger production deployments

## 📈 Monitoring

### GitHub Actions

- View workflow runs in the **Actions** tab
- Check **build logs** for detailed information
- Monitor **success/failure** rates over time

### Notifications

Add notification integrations by modifying the `notify` job:

```yaml
- name: Slack notification
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## 🔄 Maintenance

### Regular Tasks

1. **Review dependency updates** from Dependabot weekly
2. **Monitor workflow success** rates monthly  
3. **Update service account keys** annually
4. **Review and optimize** build times quarterly

### Customization

Edit `.github/workflows/n8n-auto-update.yml` to:
- Change schedule frequency
- Add additional environments
- Modify notification preferences
- Adjust build configurations

---

## 🎉 You're All Set!

Your n8n deployment will now automatically stay up-to-date with the latest releases. The workflow provides a balance of automation and control, ensuring your workflows are always running the latest stable version of n8n.

For questions or issues, check the GitHub Actions logs or create an issue in this repository. 