# GitHub Automation Module
# Automates the setup of GitHub Actions workflows, secrets, and variables
# for automated n8n updates and CI/CD

terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 5.0"
    }
  }
}

# Get repository information
data "github_repository" "repo" {
  full_name = var.github_repository
}

# Create GitHub Actions secrets
resource "github_actions_secret" "gcp_service_account_key" {
  repository       = data.github_repository.repo.name
  secret_name      = "GCP_SA_KEY"
  plaintext_value  = var.gcp_service_account_key
}

resource "github_actions_secret" "neon_api_key" {
  count           = var.neon_api_key != "" ? 1 : 0
  repository      = data.github_repository.repo.name
  secret_name     = "NEON_API_KEY"
  plaintext_value = var.neon_api_key
}

# Notification secrets (optional)
resource "github_actions_secret" "slack_webhook" {
  count           = var.slack_webhook_url != "" ? 1 : 0
  repository      = data.github_repository.repo.name
  secret_name     = "SLACK_WEBHOOK"
  plaintext_value = var.slack_webhook_url
}

resource "github_actions_secret" "discord_webhook" {
  count           = var.discord_webhook_url != "" ? 1 : 0
  repository      = data.github_repository.repo.name
  secret_name     = "DISCORD_WEBHOOK"
  plaintext_value = var.discord_webhook_url
}

# Create GitHub Actions variables
resource "github_actions_variable" "gcp_project_id" {
  repository    = data.github_repository.repo.name
  variable_name = "GCP_PROJECT_ID"
  value         = var.gcp_project_id
}

resource "github_actions_variable" "gcp_region" {
  repository    = data.github_repository.repo.name
  variable_name = "GCP_REGION"
  value         = var.gcp_region
}

resource "github_actions_variable" "cloud_run_service_name" {
  repository    = data.github_repository.repo.name
  variable_name = "CLOUD_RUN_SERVICE_NAME"
  value         = var.cloud_run_service_name
}

resource "github_actions_variable" "auto_deploy_dev" {
  repository    = data.github_repository.repo.name
  variable_name = "AUTO_DEPLOY_DEV"
  value         = var.auto_deploy_dev ? "true" : "false"
}

resource "github_actions_variable" "auto_deploy_prod" {
  count         = var.gcp_project_id_prod != "" ? 1 : 0
  repository    = data.github_repository.repo.name
  variable_name = "AUTO_DEPLOY_PROD"
  value         = var.auto_deploy_prod ? "true" : "false"
}

resource "github_actions_variable" "gcp_project_id_prod" {
  count         = var.gcp_project_id_prod != "" ? 1 : 0
  repository    = data.github_repository.repo.name
  variable_name = "GCP_PROJECT_ID_PROD"
  value         = var.gcp_project_id_prod
}

# Create GitHub environments for deployment protection
resource "github_repository_environment" "development" {
  count       = var.enable_environment_protection ? 1 : 0
  environment = "development"
  repository  = data.github_repository.repo.name

  # Optional: Add deployment protection rules
  dynamic "deployment_branch_policy" {
    for_each = var.environment_protection_rules.development.deployment_branch_policy != null ? [1] : []
    content {
      protected_branches     = var.environment_protection_rules.development.deployment_branch_policy.protected_branches
      custom_branch_policies = var.environment_protection_rules.development.deployment_branch_policy.custom_branch_policies
    }
  }

  # Optional: Add required reviewers
  dynamic "reviewers" {
    for_each = length(var.environment_protection_rules.development.reviewers) > 0 ? [1] : []
    content {
      users = var.environment_protection_rules.development.reviewers
    }
  }

  # Optional: Add wait timer
  wait_timer = var.environment_protection_rules.development.wait_timer
}

resource "github_repository_environment" "production" {
  count       = var.enable_environment_protection && var.gcp_project_id_prod != "" ? 1 : 0
  environment = "production"
  repository  = data.github_repository.repo.name

  # Production should typically have stricter protection
  dynamic "deployment_branch_policy" {
    for_each = var.environment_protection_rules.production.deployment_branch_policy != null ? [1] : []
    content {
      protected_branches     = var.environment_protection_rules.production.deployment_branch_policy.protected_branches
      custom_branch_policies = var.environment_protection_rules.production.deployment_branch_policy.custom_branch_policies
    }
  }

  dynamic "reviewers" {
    for_each = length(var.environment_protection_rules.production.reviewers) > 0 ? [1] : []
    content {
      users = var.environment_protection_rules.production.reviewers
    }
  }

  wait_timer = var.environment_protection_rules.production.wait_timer
}

# Create branch protection rules (optional)
resource "github_branch_protection" "main" {
  count          = var.enable_branch_protection ? 1 : 0
  repository_id  = data.github_repository.repo.name
  pattern        = var.protected_branch

  # Require pull requests
  required_pull_request_reviews {
    required_approving_review_count = var.branch_protection_rules.required_approving_review_count
    dismiss_stale_reviews          = var.branch_protection_rules.dismiss_stale_reviews
    require_code_owner_reviews     = var.branch_protection_rules.require_code_owner_reviews
  }

  # Require status checks
  dynamic "required_status_checks" {
    for_each = length(var.branch_protection_rules.required_status_checks) > 0 ? [1] : []
    content {
      strict   = var.branch_protection_rules.strict_status_checks
      contexts = var.branch_protection_rules.required_status_checks
    }
  }

  # Other protections
  enforce_admins         = var.branch_protection_rules.enforce_admins
  allows_deletions       = var.branch_protection_rules.allows_deletions
  allows_force_pushes    = var.branch_protection_rules.allows_force_pushes
  require_signed_commits = var.branch_protection_rules.require_signed_commits
}

# Create repository webhooks for external integrations (optional)
resource "github_repository_webhook" "deployment_webhook" {
  count      = var.deployment_webhook_url != "" ? 1 : 0
  repository = data.github_repository.repo.name

  configuration {
    url          = var.deployment_webhook_url
    content_type = "json"
    insecure_ssl = false
    secret       = var.deployment_webhook_secret
  }

  active = true

  events = [
    "workflow_run",
    "deployment",
    "deployment_status"
  ]
}

# Create CODEOWNERS file to enforce review requirements
resource "github_repository_file" "codeowners" {
  count      = var.enable_codeowners && length(var.code_owners) > 0 ? 1 : 0
  repository = data.github_repository.repo.name
  branch     = var.default_branch
  file       = ".github/CODEOWNERS"
  content = templatefile("${path.module}/templates/CODEOWNERS.tpl", {
    code_owners = var.code_owners
  })
  commit_message      = "chore: Add CODEOWNERS file for automated review assignments"
  commit_author       = var.commit_author_name
  commit_email        = var.commit_author_email
  overwrite_on_create = true
}

# Create issue templates
resource "github_repository_file" "bug_report_template" {
  count      = var.enable_issue_templates ? 1 : 0
  repository = data.github_repository.repo.name
  branch     = var.default_branch
  file       = ".github/ISSUE_TEMPLATE/bug_report.yml"
  content = templatefile("${path.module}/templates/bug_report.yml.tpl", {
    repository_name = data.github_repository.repo.name
  })
  commit_message      = "chore: Add bug report issue template"
  commit_author       = var.commit_author_name
  commit_email        = var.commit_author_email
  overwrite_on_create = true
}

resource "github_repository_file" "feature_request_template" {
  count      = var.enable_issue_templates ? 1 : 0
  repository = data.github_repository.repo.name
  branch     = var.default_branch
  file       = ".github/ISSUE_TEMPLATE/feature_request.yml"
  content = templatefile("${path.module}/templates/feature_request.yml.tpl", {
    repository_name = data.github_repository.repo.name
  })
  commit_message      = "chore: Add feature request issue template"
  commit_author       = var.commit_author_name
  commit_email        = var.commit_author_email
  overwrite_on_create = true
}

# Repository settings
resource "github_repository" "settings" {
  count       = var.manage_repository_settings ? 1 : 0
  name        = data.github_repository.repo.name
  description = var.repository_description
  
  # Repository configuration
  visibility             = var.repository_visibility
  has_issues             = var.repository_features.has_issues
  has_projects           = var.repository_features.has_projects
  has_wiki               = var.repository_features.has_wiki
  has_downloads          = var.repository_features.has_downloads
  has_discussions        = var.repository_features.has_discussions
  
  # Branch settings
  default_branch         = var.default_branch
  delete_branch_on_merge = var.repository_features.delete_branch_on_merge
  
  # Merge settings
  allow_merge_commit     = var.merge_settings.allow_merge_commit
  allow_squash_merge     = var.merge_settings.allow_squash_merge
  allow_rebase_merge     = var.merge_settings.allow_rebase_merge
  allow_auto_merge       = var.merge_settings.allow_auto_merge
  
  # Security
  vulnerability_alerts   = var.repository_features.vulnerability_alerts
  
  lifecycle {
    ignore_changes = [
      # Ignore changes to these as they might be managed outside Terraform
      default_branch,
    ]
  }
} 