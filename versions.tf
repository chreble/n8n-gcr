terraform {
  required_version = ">= 1.6.0"  # OpenTofu uses Terraform's versioning
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 6.0"
    }
    neon = {
      source  = "kislerdm/neon"
      version = ">= 0.6.0"
    }
  }

  backend "gcs" {
    # Will be filled via -backend-config
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "google-beta" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# NeonDB provider (only used when database_type = "neon")
provider "neon" {
  api_key = var.database_type == "neon" ? var.neon_api_key : null
} 