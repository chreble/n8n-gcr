# NeonDB Module Outputs

output "project_id" {
  description = "NeonDB project ID"
  value       = neon_project.main.id
}

output "project_name" {
  description = "NeonDB project name"
  value       = neon_project.main.name
}

output "host" {
  description = "Database host endpoint"
  value       = neon_endpoint.main.host
}

output "database_name" {
  description = "Database name"
  value       = neon_database.main.name
}

output "database_user" {
  description = "Database username"
  value       = neon_role.main.name
}

output "database_password" {
  description = "Database password (auto-generated)"
  value       = neon_role.main.password
  sensitive   = true
}

output "connection_uri" {
  description = "Full PostgreSQL connection URI"
  value       = "postgresql://${neon_role.main.name}:${neon_role.main.password}@${neon_endpoint.main.host}/${neon_database.main.name}?sslmode=require"
  sensitive   = true
}

output "dashboard_url" {
  description = "NeonDB dashboard URL"
  value       = "https://console.neon.tech/app/projects/${neon_project.main.id}"
}

output "endpoint_id" {
  description = "Endpoint ID"
  value       = neon_endpoint.main.id
}

output "region" {
  description = "NeonDB region"
  value       = neon_project.main.region_id
}

output "postgres_version" {
  description = "PostgreSQL version"
  value       = neon_project.main.pg_version
} 