output "instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = google_sql_database_instance.main.name
}

output "instance_connection_name" {
  description = "Connection name of the Cloud SQL instance"
  value       = google_sql_database_instance.main.connection_name
}

output "database_name" {
  description = "Name of the created database"
  value       = google_sql_database.main.name
}

output "database_user" {
  description = "Name of the database user"
  value       = google_sql_user.main.name
}

output "instance_ip_address" {
  description = "IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.main.ip_address
}

output "instance_self_link" {
  description = "Self link of the Cloud SQL instance"
  value       = google_sql_database_instance.main.self_link
}

output "database_password" {
  description = "Password of the database user"
  value       = var.database_password != "" ? var.database_password : random_password.database_password[0].result
  sensitive   = true
} 