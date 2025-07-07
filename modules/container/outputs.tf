output "repository_id" {
  description = "ID of the Artifact Registry repository"
  value       = google_artifact_registry_repository.main.repository_id
}

output "repository_url" {
  description = "URL of the Artifact Registry repository"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main.repository_id}"
}

output "repository_name" {
  description = "Full name of the Artifact Registry repository"
  value       = google_artifact_registry_repository.main.name
} 