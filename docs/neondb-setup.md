# NeonDB Automatic Provisioning Setup

This guide explains how to use the [Neon Terraform provider](https://neon.com/docs/reference/terraform) for automatic database provisioning with your n8n deployment.

## 🌟 Benefits of Automatic Provisioning

- **🔄 Fully automated**: Database creation, user management, and configuration
- **💰 Cost optimized**: Scale-to-zero when idle, pay only for usage
- **🔒 Secure**: Auto-generated credentials and SSL encryption
- **📊 Monitored**: Built-in dashboard and usage tracking
- **🚀 Fast deployment**: Complete infrastructure in minutes
- **🔧 Reproducible**: Infrastructure as Code with version control

## 📋 Prerequisites

1. **NeonDB Account**: Sign up at [neon.tech](https://neon.tech)
2. **NeonDB API Key**: Generate from [console.neon.tech/app/settings/api-keys](https://console.neon.tech/app/settings/api-keys)
3. **Google Cloud Project**: With billing enabled
4. **OpenTofu/Terraform**: Version >= 1.6

## 🚀 Quick Start

### 1. Get Your NeonDB API Key

```bash
# Navigate to NeonDB Console
open https://console.neon.tech/app/settings/api-keys

# Create a new API key:
# 1. Click "Create API Key"
# 2. Name it "terraform-automation" 
# 3. Copy the generated key (starts with "neon_...")
```

### 2. Configure Your Deployment

```bash
# Navigate to the NeonDB example
cd iac/examples/neondb-deployment

# Copy and customize the configuration
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

### 3. Essential Configuration

```hcl
# terraform.tfvars

# Google Cloud
project_id = "your-gcp-project-id"

# n8n Security
n8n_encryption_key = "your-very-long-random-encryption-key-32-chars-minimum"
authorized_users = ["your-email@example.com"]

# NeonDB (REQUIRED)
neon_api_key = "neon_your_api_key_here"

# Optional: Customize database settings
neon_project_name = "n8n-workflows"
neon_region = "aws-us-east-1"
neon_compute_min = 0.25
neon_compute_max = 1
```

### 4. Deploy Infrastructure

```bash
# Initialize Terraform with Neon provider
tofu init

# Review the planned changes
tofu plan

# Deploy everything
tofu apply
```

### 5. Access Your Deployment

After deployment completes:

```bash
# Get your n8n URL
tofu output n8n_url

# View NeonDB dashboard
tofu output neon_project_info
```

## 🏗️ What Gets Created

### NeonDB Resources

- **🏗️ Project**: Named container for your database
- **🌿 Branch**: Main branch with PostgreSQL database
- **💾 Database**: Dedicated database for n8n (`n8n`)
- **👤 User**: Database user with auto-generated password
- **🔌 Endpoint**: Connection endpoint with SSL

### Google Cloud Resources

- **🏃 Cloud Run**: n8n service with automatic scaling
- **🔒 IAP**: Identity Aware Proxy for authentication
- **📦 Artifact Registry**: Container image storage
- **🔑 Secret Manager**: Secure credential storage
- **🌐 Load Balancer**: HTTPS endpoint with SSL certificates

## ⚙️ Configuration Options

### Compute Scaling

Control NeonDB compute resources:

```hcl
# Scale from 0.25 to 2 compute units
neon_compute_min = 0.25  # 0.25 vCPU, 1 GB RAM
neon_compute_max = 2     # 2 vCPU, 8 GB RAM

# Auto-suspend after 5 minutes of inactivity
neon_suspend_timeout = 300
```

### Cost Controls

Set monthly quotas for cost protection:

```hcl
neon_quota_active_time   = 3600        # 1 hour/month
neon_quota_compute_time  = 7200        # 2 hours/month
neon_quota_data_size     = 1073741824  # 1 GB
neon_quota_data_transfer = 1073741824  # 1 GB
```

### Regional Selection

Choose the region closest to your users:

```hcl
neon_region = "aws-us-east-1"    # US East (Virginia)
# neon_region = "aws-us-west-2"  # US West (Oregon)
# neon_region = "aws-eu-west-1"  # Europe (Ireland)
# neon_region = "aws-ap-southeast-1"  # Asia Pacific (Singapore)
```

For a complete list, see [Neon Regions](https://neon.com/docs/introduction/regions).

### PostgreSQL Version

Select your preferred PostgreSQL version:

```hcl
postgres_version = 15  # PostgreSQL 15 (recommended)
# postgres_version = 14  # PostgreSQL 14
# postgres_version = 16  # PostgreSQL 16 (latest)
```

## 📊 Monitoring and Management

### NeonDB Console

Access your database dashboard:

```bash
# Get dashboard URL
tofu output neon_project_info

# Or visit directly
open https://console.neon.tech/app/projects/YOUR_PROJECT_ID
```

**Dashboard features:**
- 📈 Real-time compute usage
- 💾 Storage usage and growth
- 🔄 Connection activity
- 📋 Query insights
- ⚡ Branch management

### Connection Details

Get database connection information:

```bash
# View full database info (sensitive)
tofu output -json neon_database_info

# View compute configuration
tofu output neon_compute_info
```

### Usage Monitoring

Track your usage against quotas:

1. **Active Time**: Time database compute is running
2. **Compute Time**: Total compute resource consumption
3. **Data Size**: Storage used by your data
4. **Data Transfer**: Network traffic to/from database

## 💡 Cost Optimization Tips

### 1. Right-Size Compute

```hcl
# Development (ultra-low cost)
neon_compute_min = 0.25
neon_compute_max = 0.5

# Production (balanced)
neon_compute_min = 0.25
neon_compute_max = 2

# High-performance (fast response)
neon_compute_min = 1
neon_compute_max = 4
```

### 2. Optimize Suspend Timeout

```hcl
# Aggressive cost savings (5 minutes)
neon_suspend_timeout = 300

# Balanced (10 minutes)
neon_suspend_timeout = 600

# Performance-focused (30 minutes)
neon_suspend_timeout = 1800
```

### 3. Monitor Quotas

Set appropriate quotas based on usage patterns:

```hcl
# Light usage (personal projects)
neon_quota_active_time = 3600      # 1 hour/month
neon_quota_compute_time = 7200     # 2 hours/month

# Medium usage (small teams)
neon_quota_active_time = 14400     # 4 hours/month
neon_quota_compute_time = 28800    # 8 hours/month

# Heavy usage (production)
neon_quota_active_time = 86400     # 24 hours/month
neon_quota_compute_time = 172800   # 48 hours/month
```

## 🔒 Security Features

### Automatic Security

- **🔐 Auto-generated passwords**: Secure, random database credentials
- **🔒 SSL/TLS encryption**: All connections encrypted in transit
- **🛡️ IAP protection**: Google SSO for n8n access
- **🔑 Secret Manager**: Encrypted credential storage
- **🌐 Private networking**: Database not publicly accessible

### Branch Protection (Paid Plans)

Enable branch protection for production:

```hcl
neon_enable_branch_protection = true
neon_branch_size_limit = 5368709120  # 5 GB limit
```

## 🚨 Troubleshooting

### Common Issues

**Authentication Error:**
```bash
Error: authentication failed
```
- Verify your `neon_api_key` is correct
- Check API key permissions in NeonDB console

**Region Not Available:**
```bash
Error: region not supported
```
- Use a valid region from [Neon Regions](https://neon.com/docs/introduction/regions)
- Format: `cloud-region` (e.g., `aws-us-east-1`)

**Quota Exceeded:**
```bash
Error: quota limit reached
```
- Check usage in NeonDB console
- Increase quotas or upgrade plan
- Optimize suspend timeout

**Compute Unit Validation:**
```bash
Error: invalid compute units
```
- Use valid values: `0.25, 0.5, 1, 2, 4, 8`
- Ensure `max >= min`

### Debug Commands

```bash
# Verify Terraform configuration
tofu validate

# Check Neon provider status
tofu providers

# View all outputs
tofu output

# Destroy for cleanup (CAUTION: destroys data)
tofu destroy
```

### Provider Updates

The [Neon Terraform provider](https://neon.com/docs/reference/terraform) is community-maintained and may lag behind Neon API updates. If you encounter issues:

1. Check the [provider repository](https://github.com/kislerdm/terraform-provider-neon) for updates
2. Review [Terraform Registry documentation](https://registry.terraform.io/providers/kislerdm/neon/latest/docs)
3. Report issues to the maintainer

## 🔄 Lifecycle Management

### Updating Configuration

```bash
# Update variables in terraform.tfvars
nano terraform.tfvars

# Apply changes
tofu apply
```

### Scaling Resources

```bash
# Increase compute limits
neon_compute_max = 4

# Apply scaling changes
tofu apply
```

### Backup and Recovery

NeonDB provides automatic:
- **Point-in-time recovery**: Restore to any point in the last 7 days
- **Continuous backup**: Real-time backup of all changes
- **Branch snapshots**: Create branches for testing/development

Access via the NeonDB console or API.

## 📈 Monitoring Integration

### GitHub Actions Integration

The automated update workflow includes NeonDB monitoring:

```yaml
# .github/workflows/n8n-auto-update.yml includes:
- name: Check NeonDB health
  run: |
    # Health checks and usage monitoring
    # Automated alerts for quota thresholds
```

### Custom Monitoring

Set up custom monitoring:

```bash
# Monitor compute usage
curl -H "Authorization: Bearer $NEON_API_KEY" \
  "https://console.neon.tech/api/v2/projects/$PROJECT_ID/operations"

# Check connection status
psql "postgresql://$USER:$PASSWORD@$HOST/$DATABASE?sslmode=require" \
  -c "SELECT version();"
```

## 🎯 Best Practices

### 1. Environment Separation

```hcl
# Development
neon_project_name = "n8n-dev"
neon_compute_max = 1

# Production  
neon_project_name = "n8n-prod"
neon_compute_max = 4
neon_enable_branch_protection = true
```

### 2. Resource Naming

```hcl
# Use consistent naming
neon_project_name = "${var.environment}-n8n-workflows"
neon_database_name = "n8n"
neon_database_owner = "n8n_user"
```

### 3. Cost Management

```hcl
# Set realistic quotas
neon_quota_active_time = 7200    # Based on expected usage
neon_suspend_timeout = 300       # Quick scale-to-zero

# Monitor and adjust based on actual usage
```

### 4. Security

```hcl
# Enable all security features
neon_enable_branch_protection = true  # If on paid plan

# Use strong encryption keys
n8n_encryption_key = "generated-64-character-random-string"
```

---

## 🎉 Ready to Deploy!

With automatic NeonDB provisioning, you get:

- ✅ **Zero-maintenance database**: Fully managed PostgreSQL
- ✅ **True serverless**: Scales to zero when idle  
- ✅ **Infrastructure as Code**: Version-controlled, reproducible
- ✅ **Cost optimized**: Pay only for what you use
- ✅ **Production ready**: Backup, monitoring, security included

Your n8n workflows will run on a world-class serverless database infrastructure that scales automatically with your needs! 🚀 