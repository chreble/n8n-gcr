variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud region"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "cloud_run_service_name" {
  description = "Name of the Cloud Run service to protect"
  type        = string
}

variable "authorized_users" {
  description = "List of email addresses authorized to access through IAP"
  type        = list(string)
  validation {
    condition     = length(var.authorized_users) > 0
    error_message = "At least one authorized user email must be provided."
  }
}

variable "oauth_brand_name" {
  description = "Name for the OAuth brand (shown on consent screen)"
  type        = string
  default     = "n8n Workflow Automation"
}

variable "oauth_support_email" {
  description = "Support email for the OAuth consent screen (required)"
  type        = string
  validation {
    condition     = length(var.oauth_support_email) > 0
    error_message = "oauth_support_email must be provided (cannot be empty)"
  }
}

variable "domain_name" {
  description = "Optional custom domain name for the load balancer"
  type        = string
  default     = ""
}

variable "backend_timeout_sec" {
  description = "Backend service timeout in seconds"
  type        = number
  default     = 30
} 