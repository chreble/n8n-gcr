# GitHub Automation Module Outputs

output "repository_info" {
  description = "Repository information"
  value = {
    name          = data.github_repository.repo.name
    full_name     = data.github_repository.repo.full_name
    clone_url     = data.github_repository.repo.clone_url
    ssh_clone_url = data.github_repository.repo.ssh_clone_url
    html_url      = data.github_repository.repo.html_url
    default_branch = data.github_repository.repo.default_branch
  }
}

output "secrets_created" {
  description = "List of GitHub Actions secrets that were created"
  value = [
    "GCP_SA_KEY",
    var.neon_api_key != "" ? "NEON_API_KEY" : null,
    var.slack_webhook_url != "" ? "SLACK_WEBHOOK" : null,
    var.discord_webhook_url != "" ? "DISCORD_WEBHOOK" : null
  ]
}

output "variables_created" {
  description = "List of GitHub Actions variables that were created"
  value = [
    "GCP_PROJECT_ID",
    "GCP_REGION", 
    "CLOUD_RUN_SERVICE_NAME",
    "AUTO_DEPLOY_DEV",
    var.gcp_project_id_prod != "" ? "AUTO_DEPLOY_PROD" : null,
    var.gcp_project_id_prod != "" ? "GCP_PROJECT_ID_PROD" : null
  ]
}

output "environments_created" {
  description = "GitHub environments that were created"
  value = var.enable_environment_protection ? [
    "development",
    var.gcp_project_id_prod != "" ? "production" : null
  ] : []
}

output "branch_protection_enabled" {
  description = "Whether branch protection is enabled"
  value = var.enable_branch_protection
}

output "workflow_url" {
  description = "URL to view GitHub Actions workflows"
  value = "${data.github_repository.repo.html_url}/actions"
}

output "settings_url" {
  description = "URL to repository settings"
  value = "${data.github_repository.repo.html_url}/settings"
}

output "secrets_url" {
  description = "URL to GitHub Actions secrets"
  value = "${data.github_repository.repo.html_url}/settings/secrets/actions"
}

output "setup_instructions" {
  description = "Next steps and verification instructions"
  value = <<-EOT
    🎉 GitHub automation setup completed!
    
    📊 Repository: ${data.github_repository.repo.full_name}
    🔧 Actions: ${data.github_repository.repo.html_url}/actions
    ⚙️ Settings: ${data.github_repository.repo.html_url}/settings
    🔑 Secrets: ${data.github_repository.repo.html_url}/settings/secrets/actions
    
    ✅ Configured secrets:
    ${join("\n    ", [for s in [
      "GCP_SA_KEY",
      var.neon_api_key != "" ? "NEON_API_KEY" : null,
      var.slack_webhook_url != "" ? "SLACK_WEBHOOK" : null,
      var.discord_webhook_url != "" ? "DISCORD_WEBHOOK" : null
    ] : "- ${s}" if s != null])}
    
    ✅ Configured variables:
    ${join("\n    ", [for v in [
      "GCP_PROJECT_ID = ${var.gcp_project_id}",
      "GCP_REGION = ${var.gcp_region}",
      "CLOUD_RUN_SERVICE_NAME = ${var.cloud_run_service_name}",
      "AUTO_DEPLOY_DEV = ${var.auto_deploy_dev}",
      var.gcp_project_id_prod != "" ? "AUTO_DEPLOY_PROD = ${var.auto_deploy_prod}" : null,
      var.gcp_project_id_prod != "" ? "GCP_PROJECT_ID_PROD = ${var.gcp_project_id_prod}" : null
    ] : "- ${v}" if v != null])}
    
    ${var.enable_environment_protection ? "✅ Environment protection enabled" : ""}
    ${var.enable_branch_protection ? "✅ Branch protection enabled for ${var.protected_branch}" : ""}
    ${var.enable_codeowners && length(var.code_owners) > 0 ? "✅ CODEOWNERS file created" : ""}
    ${var.enable_issue_templates ? "✅ Issue templates created" : ""}
    
    🚀 Next steps:
    1. Verify the n8n-auto-update.yml workflow exists in .github/workflows/
    2. Test the workflow by going to Actions → "N8N Auto Update and Build" → "Run workflow"
    3. Monitor the first automated run
    4. Set up any additional notification integrations
    
    💡 The automated workflow will:
    - Check for n8n updates daily at 6 AM UTC
    - Build and push new container images automatically
    - ${var.auto_deploy_dev ? "Deploy to development environment automatically" : "Require manual deployment approval"}
    - Create GitHub releases with version tracking
    
    🔧 To modify settings:
    - Update terraform.tfvars and run 'tofu apply'
    - All GitHub configuration is now managed via Infrastructure as Code!
  EOT
} 