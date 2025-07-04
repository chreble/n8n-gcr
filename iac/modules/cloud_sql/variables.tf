variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud region"
  type        = string
}

variable "instance_name" {
  description = "Name of the Cloud SQL instance"
  type        = string
}

variable "database_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "POSTGRES_13"
}

variable "tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "availability_type" {
  description = "Availability type for the instance"
  type        = string
  default     = "ZONAL"
}

variable "disk_type" {
  description = "Disk type for the instance"
  type        = string
  default     = "PD_HDD"
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 10

  validation {
    condition     = var.disk_size >= 10
    error_message = "Disk size must be at least 10 GB."
  }
}

variable "backup_enabled" {
  description = "Whether to enable backups"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection"
  type        = bool
  default     = false
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "n8n"
}

variable "database_user" {
  description = "Database user name"
  type        = string
  default     = "n8n-user"
}

variable "database_password" {
  description = "Database user password. Leave empty to auto-generate a secure password during deployment."
  type        = string
  default     = ""
  sensitive   = true
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
} 