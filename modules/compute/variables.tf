variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud region"
  type        = string
}

variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string
}

variable "service_account_name" {
  description = "Name of the service account"
  type        = string
}

variable "service_account_display_name" {
  description = "Display name of the service account"
  type        = string
  default     = "Cloud Run Service Account"
}

variable "container_image" {
  description = "Container image to deploy"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 5678
}

variable "cpu_limit" {
  description = "CPU limit for the container"
  type        = string
  default     = "2"
}

variable "memory_limit" {
  description = "Memory limit for the container"
  type        = string
  default     = "2Gi"
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 1
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "database_connection_name" {
  description = "Cloud SQL connection name (empty string if not using Cloud SQL)"
  type        = string
  default     = ""
}

variable "db_password_secret_id" {
  description = "Secret Manager secret ID for database password"
  type        = string
}

variable "n8n_encryption_key_secret_id" {
  description = "Secret Manager secret ID for n8n encryption key"
  type        = string
}

variable "startup_probe_initial_delay" {
  description = "Initial delay for startup probe in seconds"
  type        = number
  default     = 120
}

variable "startup_probe_timeout" {
  description = "Timeout for startup probe in seconds"
  type        = number
  default     = 240
}

variable "startup_probe_period" {
  description = "Period for startup probe in seconds"
  type        = number
  default     = 10
}

variable "startup_probe_failure_threshold" {
  description = "Failure threshold for startup probe"
  type        = number
  default     = 3
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
} 