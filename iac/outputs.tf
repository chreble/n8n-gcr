# Main service access URL
output "n8n_url" {
  description = "URL to access your n8n instance through IAP (requires authentication)"
  value       = module.iap.iap_url
}

# Load balancer information
output "load_balancer_ip" {
  description = "Static IP address of the load balancer"
  value       = module.iap.load_balancer_ip
}

# Cloud Run service information
output "cloud_run_service_url" {
  description = "Direct Cloud Run service URL (not accessible due to IAP protection)"
  value       = module.compute.service_url
}

output "cloud_run_service_name" {
  description = "Name of the Cloud Run service"
  value       = module.compute.service_name
}

# Database information
output "database_type" {
  description = "Type of database being used"
  value       = var.database_type
}

output "database_instance_name" {
  description = "Name of the Cloud SQL instance (if using Cloud SQL)"
  value       = var.database_type == "cloud_sql" ? module.cloud_sql[0].instance_name : "N/A (using NeonDB)"
}

output "database_connection_name" {
  description = "Connection name for the Cloud SQL instance (if using Cloud SQL)"
  value       = var.database_type == "cloud_sql" ? module.cloud_sql[0].instance_connection_name : "N/A (using NeonDB)"
}

output "database_host" {
  description = "Database host"
  value       = var.database_type == "cloud_sql" ? "Cloud SQL (via Unix socket)" : (var.database_type == "neon" ? module.neondb[0].host : "N/A")
  # Mark host as sensitive to avoid showing in plaintext outputs
  sensitive   = true
}

output "neondb_project_id" {
  description = "NeonDB project ID (if using NeonDB)"
  value       = var.database_type == "neon" ? module.neondb[0].project_id : "N/A (using Cloud SQL)"
}

output "neondb_dashboard_url" {
  description = "NeonDB dashboard URL (if using NeonDB)"
  value       = var.database_type == "neon" ? module.neondb[0].dashboard_url : "N/A (using Cloud SQL)"
}

# Container registry information
output "container_repository_url" {
  description = "URL of the Artifact Registry repository"
  value       = module.container.repository_url
}

# Service account information
output "service_account_email" {
  description = "Email of the Cloud Run service account"
  value       = module.compute.service_account_email
}

# IAP configuration
output "iap_client_id" {
  description = "IAP OAuth2 client ID (sensitive)"
  value       = module.iap.iap_client_id
  sensitive   = true
}

# SSL certificate (if using custom domain)
output "ssl_certificate_name" {
  description = "Name of the SSL certificate (if using custom domain)"
  value       = module.iap.ssl_certificate_name
}

# Setup instructions
output "setup_instructions" {
  description = "Next steps to complete your n8n setup"
  value = <<-EOT
    
    🎉 Your n8n instance has been deployed successfully!
    
    📝 Next Steps:
    1. Access your n8n instance at: ${module.iap.iap_url}
    2. You'll be prompted to authenticate with Google (IAP)
    3. Only users in this list can access: ${join(", ", var.iap_authorized_users)}
    
    🔧 To add more authorized users:
    - Update the 'iap_authorized_users' variable in terraform.tfvars
    - Run 'tofu apply' to update IAP permissions
    
    ${var.domain_name != "" ? "🌐 Custom Domain Setup:" : "🌐 Optional: Custom Domain Setup:"}
    ${var.domain_name != "" ? "- Your custom domain ${var.domain_name} is configured" : "- Set 'domain_name' variable to use a custom domain"}
    ${var.domain_name != "" ? "- Point your DNS A record to: ${module.iap.load_balancer_ip}" : "- Point your DNS A record to the load balancer IP"}
    ${var.domain_name != "" ? "- SSL certificate will auto-provision once DNS is configured" : ""}
    
    📦 Container Management:
    - Repository: ${module.container.repository_url}
    - To update n8n: rebuild and push your container, then run 'tofu apply'
    
    🗄️ Database Configuration:
    - Type: ${var.database_type == "cloud_sql" ? "Google Cloud SQL" : "NeonDB"}
    ${var.database_type == "cloud_sql" ? "- Instance: ${module.cloud_sql[0].instance_name}" : "- Host: ${module.neondb[0].host}"}
    - Database: ${var.db_name}
    
    🔒 Security Features Enabled:
    ✅ Identity Aware Proxy (IAP) protection
    ✅ Secret Manager for credentials
    ✅ HTTPS-only access
    ✅ Cloud Run private ingress
    ${var.database_type == "neon" ? "✅ NeonDB SSL encryption" : "✅ Cloud SQL private networking"}
    
  EOT
} 