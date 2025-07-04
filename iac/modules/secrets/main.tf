terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
  }
}

# Enable Secret Manager API
resource "google_project_service" "secretmanager" {
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# Database password secret
resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.name_prefix}-db-password"
  project   = var.project_id
  
  labels = var.labels

  replication {
    auto {}
  }
  
  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.db_password
}

# Generate random encryption key if not provided
resource "random_password" "n8n_encryption_key" {
  count   = var.n8n_encryption_key == "" ? 1 : 0
  length  = 32
  special = true
}

# n8n encryption key secret
resource "google_secret_manager_secret" "n8n_encryption_key" {
  secret_id = "${var.name_prefix}-encryption-key"
  project   = var.project_id
  
  labels = var.labels

  replication {
    auto {}
  }
  
  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "n8n_encryption_key" {
  secret      = google_secret_manager_secret.n8n_encryption_key.id
  secret_data = var.n8n_encryption_key != "" ? var.n8n_encryption_key : random_password.n8n_encryption_key[0].result
} 