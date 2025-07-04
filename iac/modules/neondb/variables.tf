variable "org_id" {
  description = "NeonDB organization ID"
  type        = string
}

variable "project_name" {
  description = "Name for the NeonDB project"
  type        = string
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = number
  default     = 15
  
  validation {
    condition     = contains([14, 15, 16], var.postgres_version)
    error_message = "PostgreSQL version must be 14, 15, or 16."
  }
}

variable "region" {
  description = "NeonDB region (e.g., aws-us-east-1, aws-eu-west-1)"
  type        = string
  default     = "aws-eu-central-1"
  
  validation {
    condition = can(regex("^(aws|gcp|azure)-[a-z0-9-]+$", var.region))
    error_message = "Neon region must be in format 'cloud-region' (e.g., aws-us-east-1)."
  }
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "n8n"
}

variable "database_user" {
  description = "Name of the database user"
  type        = string
  default     = "n8n_user"
}

# Compute configuration
variable "compute_min" {
  description = "Minimum compute units (0.25, 0.5, 1, 2, 4, 8)"
  type        = number
  default     = 0.25
  
  validation {
    condition     = contains([0.25, 0.5, 1, 2, 4, 8], var.compute_min)
    error_message = "Minimum compute units must be one of: 0.25, 0.5, 1, 2, 4, 8."
  }
}

variable "compute_max" {
  description = "Maximum compute units (0.25, 0.5, 1, 2, 4, 8)"
  type        = number
  default     = 1
  
  validation {
    condition     = contains([0.25, 0.5, 1, 2, 4, 8], var.compute_max)
    error_message = "Maximum compute units must be one of: 0.25, 0.5, 1, 2, 4, 8."
  }
}

variable "suspend_timeout" {
  description = "Time in seconds before suspending compute when idle"
  type        = number
  default     = 300
  
  validation {
    condition     = var.suspend_timeout >= 60 && var.suspend_timeout <= 3600
    error_message = "Suspend timeout must be between 60 seconds (1 minute) and 3600 seconds (1 hour)."
  }
}

# Quota configuration
variable "quota_active_time" {
  description = "Monthly quota for active time in seconds"
  type        = number
  default     = 3600  # 1 hour
}

variable "quota_compute_time" {
  description = "Monthly quota for compute time in seconds"
  type        = number
  default     = 7200  # 2 hours
}

variable "quota_data_size" {
  description = "Monthly quota for written data in bytes"
  type        = number
  default     = 1073741824  # 1 GB
}

variable "quota_data_transfer" {
  description = "Monthly quota for data transfer in bytes"
  type        = number
  default     = 1073741824  # 1 GB
}

# Branch protection
variable "enable_branch_protection" {
  description = "Enable branch protection (requires paid plan)"
  type        = bool
  default     = false
}

variable "branch_size_limit" {
  description = "Branch logical size limit in bytes"
  type        = number
  default     = 1073741824  # 1 GB
} 