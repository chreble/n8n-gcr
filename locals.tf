locals {
  # Common naming prefix
  name_prefix = var.cloud_run_service_name

  # Environment-specific naming
  environment = var.environment

  # Common resource tags
  common_tags = {
    Environment   = var.environment
    Project       = "n8n-workflow-automation"
    ManagedBy     = "terraform"
    Application   = "n8n"
    Owner         = var.owner_email != "" ? var.owner_email : "unknown"
    CreatedDate   = formatdate("YYYY-MM-DD", timestamp())
  }

  # Resource naming conventions
  resource_names = {
    cloud_sql_instance = "${local.name_prefix}-${local.environment}-db"
    cloud_run_service  = "${local.name_prefix}-${local.environment}"
    artifact_repo      = "${local.name_prefix}-${local.environment}-repo"
    service_account    = "${local.name_prefix}-${local.environment}-sa"
    load_balancer_ip   = "${local.name_prefix}-${local.environment}-ip"
  }

  # Common labels for Google Cloud resources
  gcp_labels = {
    environment = local.environment
    application = "n8n"
    managed_by  = "terraform"
    owner       = replace(lower(var.owner_email != "" ? var.owner_email : "unknown"), "@", "-at-")
  }
} 