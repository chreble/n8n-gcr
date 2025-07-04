variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "db_password" {
  description = "Database password to store in Secret Manager"
  type        = string
  sensitive   = true
}

variable "n8n_encryption_key" {
  description = "n8n encryption key to store in Secret Manager. If empty, a secure 32-character key will be auto-generated."
  type        = string
  default     = ""
  sensitive   = true
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
} 