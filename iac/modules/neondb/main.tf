# NeonDB Module
# Manages NeonDB project, database, and user creation

terraform {
  required_providers {
    neon = {
      source  = "kislerdm/neon"
      version = ">= 0.6.0"
    }
  }
}

# Neon provider v0.9.x has changed schema; keep only required attributes
resource "neon_project" "main" {
  name       = var.project_name
  pg_version = var.postgres_version
  region_id  = var.region
  org_id     = var.org_id
}

# The provider now exposes `branch_id` as an attribute on `neon_project.main`; no data source required.

# Future enhancements: fetch branch data via resource or output once the provider supports it.

# Endpoint creation currently omitted for compatibility. n8n connects directly to project's default host.

# Create (or retrieve) a branch that we can attach our database to.
resource "neon_branch" "infra" {
  project_id = neon_project.main.id
  name       = "infra" # distinct from default `main` branch
  parent_id  = null      # use the project's default branch
}

locals {
  active_branch_id = neon_branch.infra.id
}

# Create read-write endpoint for the branch (required before roles)
resource "neon_endpoint" "main" {
  project_id = neon_project.main.id
  branch_id  = local.active_branch_id
  type       = "read_write"
}

# Create database role for n8n (requires endpoint)
resource "neon_role" "main" {
  project_id = neon_project.main.id
  branch_id  = local.active_branch_id
  name       = var.database_user

  depends_on = [neon_endpoint.main]
}

# Create database for n8n (requires role)
resource "neon_database" "main" {
  project_id = neon_project.main.id
  branch_id  = local.active_branch_id
  name       = var.database_name
  owner_name = var.database_user

  depends_on = [neon_role.main]
} 