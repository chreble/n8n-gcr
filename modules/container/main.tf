# Enable Artifact Registry API
resource "google_project_service" "artifactregistry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# Artifact Registry repository
resource "google_artifact_registry_repository" "main" {
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_name
  description   = var.description
  format        = "DOCKER"
  
  labels = var.labels
  
  depends_on = [google_project_service.artifactregistry]
}