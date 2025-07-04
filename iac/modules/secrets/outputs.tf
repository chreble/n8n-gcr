output "db_password_secret_id" {
  description = "ID of the database password secret"
  value       = google_secret_manager_secret.db_password.secret_id
}

output "n8n_encryption_key_secret_id" {
  description = "ID of the n8n encryption key secret"
  value       = google_secret_manager_secret.n8n_encryption_key.secret_id
}

output "db_password_secret_name" {
  description = "Full name of the database password secret"
  value       = google_secret_manager_secret.db_password.name
}

output "n8n_encryption_key_secret_name" {
  description = "Full name of the n8n encryption key secret"
  value       = google_secret_manager_secret.n8n_encryption_key.name
}

output "encryption_key_auto_generated" {
  description = "Whether the n8n encryption key was auto-generated"
  value       = var.n8n_encryption_key == ""
} 