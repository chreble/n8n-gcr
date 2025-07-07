variable "gcp_project_id" {
  description = "Google Cloud project ID where resources will be created."
  type        = string
  # No default - must be provided by user
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Environment must be lowercase alphanumeric with hyphens only."
  }
}

variable "owner_email" {
  description = "Email address of the resource owner for tagging and OAuth defaults"
  type        = string
  default     = ""
}

variable "gcp_region" {
  description = "Google Cloud region for deployment."
  type        = string
  default     = "europe-west1"
}

variable "database_type" {
  description = "Database type to use: 'cloud_sql' or 'neon'"
  type        = string
  default     = "cloud_sql"
  validation {
    condition     = contains(["cloud_sql", "neon"], var.database_type)
    error_message = "Database type must be either 'cloud_sql' or 'neon'."
  }
}

variable "db_name" {
  description = "Name for the PostgreSQL database."
  type        = string
  default     = "n8n"
}

variable "db_user" {
  description = "Username for the Cloud SQL database user."
  type        = string
  default     = "n8n-user"
}

variable "db_password" {
  description = "Password for the database user. Leave empty to auto-generate a secure password during deployment (for both Cloud SQL and NeonDB). Stored securely in Secret Manager."
  type        = string
  default     = ""
  sensitive   = true
  validation {
    condition     = var.db_password == "" || length(var.db_password) >= 8
    error_message = "Database password must be at least 8 characters long when provided (leave empty for auto-generation)."
  }
}

# NeonDB-specific variables (for automatic provisioning)
variable "neon_org_id" {
  description = "NeonDB organization ID for automatic provisioning (only required if database_type is 'neon')"
  type        = string
  default     = ""
  sensitive   = true
}

variable "neon_api_key" {
  description = "NeonDB API key for automatic provisioning (only required if database_type is 'neon')"
  type        = string
  default     = ""
  sensitive   = true
}

variable "neon_project_name" {
  description = "Name for the NeonDB project"
  type        = string
  default     = "n8n-workflows"
}

variable "neon_postgres_version" {
  description = "PostgreSQL version for NeonDB"
  type        = number
  default     = 15
  
  validation {
    condition     = contains([14, 15, 16], var.neon_postgres_version)
    error_message = "PostgreSQL version must be 14, 15, or 16."
  }
}

variable "neon_region" {
  description = "NeonDB region (e.g., aws-us-east-1, aws-eu-west-1)"
  type        = string
  default     = "aws-us-east-1"
  
  validation {
    condition = can(regex("^(aws|gcp|azure)-[a-z0-9-]+$", var.neon_region))
    error_message = "Neon region must be in format 'cloud-region' (e.g., aws-us-east-1)."
  }
}

variable "neon_compute_min" {
  description = "Minimum compute units (0.25, 0.5, 1, 2, 4, 8)"
  type        = number
  default     = 0.25
  
  validation {
    condition     = contains([0.25, 0.5, 1, 2, 4, 8], var.neon_compute_min)
    error_message = "Minimum compute units must be one of: 0.25, 0.5, 1, 2, 4, 8."
  }
}

variable "neon_compute_max" {
  description = "Maximum compute units (0.25, 0.5, 1, 2, 4, 8)"
  type        = number
  default     = 1
  
  validation {
    condition     = contains([0.25, 0.5, 1, 2, 4, 8], var.neon_compute_max)
    error_message = "Maximum compute units must be one of: 0.25, 0.5, 1, 2, 4, 8."
  }
}

variable "neon_suspend_timeout" {
  description = "Time in seconds before suspending compute when idle"
  type        = number
  default     = 300
  
  validation {
    condition     = var.neon_suspend_timeout >= 60 && var.neon_suspend_timeout <= 3600
    error_message = "Suspend timeout must be between 60 seconds (1 minute) and 3600 seconds (1 hour)."
  }
}

variable "neon_quota_active_time" {
  description = "Monthly quota for active time in seconds"
  type        = number
  default     = 3600
}

variable "neon_quota_compute_time" {
  description = "Monthly quota for compute time in seconds"
  type        = number
  default     = 7200
}

variable "neon_quota_data_size" {
  description = "Monthly quota for written data in bytes"
  type        = number
  default     = 1073741824
}

variable "neon_quota_data_transfer" {
  description = "Monthly quota for data transfer in bytes"  
  type        = number
  default     = 1073741824
}

variable "neon_enable_branch_protection" {
  description = "Enable branch protection (requires paid plan)"
  type        = bool
  default     = false
}

variable "neon_branch_size_limit" {
  description = "Branch logical size limit in bytes"
  type        = number
  default     = 1073741824
}

variable "n8n_encryption_key" {
  description = "Encryption key for n8n credential storage. If empty, a secure 32-character key will be auto-generated. Will be stored securely in Secret Manager."
  type        = string
  default     = ""
  sensitive   = true
  validation {
    condition     = var.n8n_encryption_key == "" || length(var.n8n_encryption_key) >= 32
    error_message = "n8n encryption key must be at least 32 characters long for security (leave empty for auto-generation)."
  }
}

variable "db_tier" {
  description = "Cloud SQL instance tier. Use db-f1-micro for lowest cost."
  type        = string
  default     = "db-f1-micro"
}

variable "db_storage_size" {
  description = "Cloud SQL instance storage size in GB."
  type        = number
  default     = 10
  validation {
    condition     = var.db_storage_size >= 10
    error_message = "Database storage size must be at least 10 GB."
  }
}

variable "cloud_sql_tier" {
  description = "Cloud SQL instance tier. Use db-f1-micro for lowest cost."
  type        = string
  default     = "db-f1-micro"
}

variable "cloud_sql_storage_size" {
  description = "Cloud SQL instance storage size in GB."
  type        = number
  default     = 10
  validation {
    condition     = var.cloud_sql_storage_size >= 10
    error_message = "Cloud SQL storage size must be at least 10 GB."
  }
}

variable "artifact_repo_name" {
  description = "Name for the Artifact Registry repository to store the n8n Docker image."
  type        = string
  default     = "n8n-repo"
}

variable "cloud_run_service_name" {
  description = "Name for the Cloud Run service."
  type        = string
  default     = "n8n"
  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.cloud_run_service_name))
    error_message = "Cloud Run service name must be lowercase alphanumeric with hyphens."
  }
}

variable "service_account_name" {
  description = "Name for the IAM service account used by Cloud Run."
  type        = string
  default     = "n8n-service-account"
}

variable "cloud_run_cpu" {
  description = "CPU allocation for Cloud Run service (e.g., '1', '2')."
  type        = string
  default     = "2"
}

variable "cloud_run_memory" {
  description = "Memory allocation for Cloud Run service (e.g., '2Gi', '4Gi')."
  type        = string
  default     = "2Gi"
}

variable "cloud_run_max_instances" {
  description = "Maximum number of instances for Cloud Run service."
  type        = number
  default     = 1
  validation {
    condition     = var.cloud_run_max_instances >= 1
    error_message = "Maximum instances must be at least 1."
  }
}

variable "cloud_run_container_port" {
  description = "Internal port the n8n container listens on."
  type        = number
  default     = 5678
}

variable "generic_timezone" {
  description = "Timezone for n8n operations."
  type        = string
  default     = "UTC"
}

# --- Identity Aware Proxy Variables --- #
variable "iap_authorized_users" {
  description = "List of email addresses authorized to access n8n through IAP."
  type        = list(string)
  validation {
    condition = length(var.iap_authorized_users) > 0
    error_message = "At least one authorized user email must be provided for IAP access."
  }
}

variable "oauth_brand_name" {
  description = "Name for the OAuth brand (shown on consent screen)."
  type        = string
  default     = "n8n Workflow Automation"
}

variable "oauth_support_email" {
  description = "Support email for the OAuth consent screen."
  type        = string
  default     = ""
  validation {
    condition = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.oauth_support_email)) || var.oauth_support_email == ""
    error_message = "Support email must be a valid email address."
  }
}

variable "domain_name" {
  description = "Optional custom domain name for the load balancer. If not provided, will use the default Google-managed domain."
  type        = string
  default     = ""
} 