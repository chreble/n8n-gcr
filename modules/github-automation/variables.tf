# GitHub Automation Module Variables

# Required Variables
variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
}

variable "gcp_project_id" {
  description = "Google Cloud project ID"
  type        = string
}

variable "gcp_service_account_key" {
  description = "Google Cloud service account key (JSON)"
  type        = string
  sensitive   = true
}

# Optional GCP Variables
variable "gcp_region" {
  description = "Google Cloud region"
  type        = string
  default     = "us-west2"
}

variable "cloud_run_service_name" {
  description = "Cloud Run service name"
  type        = string
  default     = "n8n"
}

variable "gcp_project_id_prod" {
  description = "Google Cloud project ID for production (optional)"
  type        = string
  default     = ""
}

# NeonDB Variables
variable "neon_api_key" {
  description = "NeonDB API key (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

# Automation Settings
variable "auto_deploy_dev" {
  description = "Enable automatic deployment to development environment"
  type        = bool
  default     = false
}

variable "auto_deploy_prod" {
  description = "Enable automatic deployment to production environment"
  type        = bool
  default     = false
}

# Notification Settings
variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "discord_webhook_url" {
  description = "Discord webhook URL for notifications (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "deployment_webhook_url" {
  description = "External webhook URL for deployment notifications (optional)"
  type        = string
  default     = ""
}

variable "deployment_webhook_secret" {
  description = "Secret for deployment webhook (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

# Repository Management
variable "manage_repository_settings" {
  description = "Whether to manage repository settings via Terraform"
  type        = bool
  default     = false
}

variable "repository_description" {
  description = "Repository description"
  type        = string
  default     = "n8n on Google Cloud Run with automated deployment"
}

variable "repository_visibility" {
  description = "Repository visibility (public, private, internal)"
  type        = string
  default     = "private"
  
  validation {
    condition     = contains(["public", "private", "internal"], var.repository_visibility)
    error_message = "Repository visibility must be public, private, or internal."
  }
}

variable "default_branch" {
  description = "Default branch name"
  type        = string
  default     = "main"
}

# Repository Features
variable "repository_features" {
  description = "Repository feature settings"
  type = object({
    has_issues             = bool
    has_projects           = bool
    has_wiki               = bool
    has_downloads          = bool
    has_discussions        = bool
    delete_branch_on_merge = bool
    vulnerability_alerts   = bool
  })
  default = {
    has_issues             = true
    has_projects           = true
    has_wiki               = false
    has_downloads          = false
    has_discussions        = true
    delete_branch_on_merge = true
    vulnerability_alerts   = true
  }
}

# Merge Settings
variable "merge_settings" {
  description = "Repository merge settings"
  type = object({
    allow_merge_commit = bool
    allow_squash_merge = bool
    allow_rebase_merge = bool
    allow_auto_merge   = bool
  })
  default = {
    allow_merge_commit = false
    allow_squash_merge = true
    allow_rebase_merge = false
    allow_auto_merge   = true
  }
}

# Branch Protection
variable "enable_branch_protection" {
  description = "Enable branch protection for main branch"
  type        = bool
  default     = true
}

variable "protected_branch" {
  description = "Branch pattern to protect"
  type        = string
  default     = "main"
}

variable "branch_protection_rules" {
  description = "Branch protection rules"
  type = object({
    required_approving_review_count = number
    dismiss_stale_reviews          = bool
    require_code_owner_reviews     = bool
    required_status_checks         = list(string)
    strict_status_checks           = bool
    enforce_admins                 = bool
    allows_deletions               = bool
    allows_force_pushes            = bool
    require_signed_commits         = bool
  })
  default = {
    required_approving_review_count = 1
    dismiss_stale_reviews          = true
    require_code_owner_reviews     = true
    required_status_checks         = ["build", "test"]
    strict_status_checks           = true
    enforce_admins                 = false
    allows_deletions               = false
    allows_force_pushes            = false
    require_signed_commits         = false
  }
}

# Environment Protection
variable "enable_environment_protection" {
  description = "Enable GitHub environment protection"
  type        = bool
  default     = true
}

variable "environment_protection_rules" {
  description = "Environment protection rules"
  type = object({
    development = object({
      reviewers = list(string)
      wait_timer = number
      deployment_branch_policy = object({
        protected_branches     = bool
        custom_branch_policies = bool
      })
    })
    production = object({
      reviewers = list(string)
      wait_timer = number
      deployment_branch_policy = object({
        protected_branches     = bool
        custom_branch_policies = bool
      })
    })
  })
  default = {
    development = {
      reviewers = []
      wait_timer = 0
      deployment_branch_policy = {
        protected_branches     = false
        custom_branch_policies = false
      }
    }
    production = {
      reviewers = []
      wait_timer = 300  # 5 minutes
      deployment_branch_policy = {
        protected_branches     = true
        custom_branch_policies = false
      }
    }
  }
}

# Code Owners
variable "enable_codeowners" {
  description = "Create CODEOWNERS file for review assignments"
  type        = bool
  default     = true
}

variable "code_owners" {
  description = "List of code owners (GitHub usernames or team names)"
  type        = list(string)
  default     = []
}

# Issue Templates
variable "enable_issue_templates" {
  description = "Create issue templates"
  type        = bool
  default     = true
}

# Commit Settings
variable "commit_author_name" {
  description = "Name for automated commits"
  type        = string
  default     = "terraform-automation"
}

variable "commit_author_email" {
  description = "Email for automated commits"
  type        = string
  default     = "automation@example.com"
} 