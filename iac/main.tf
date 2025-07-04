# Data source to get the project number for Cloud Run URL construction
data "google_project" "project" {
  project_id = var.gcp_project_id
}

# Secrets module - manages Secret Manager secrets and IAM
module "secrets" {
  source = "./modules/secrets"

  project_id            = var.gcp_project_id
  name_prefix           = local.resource_names.cloud_run_service
  db_password           = var.database_type == "cloud_sql" ? (var.db_password != "" ? var.db_password : module.cloud_sql[0].database_password) : (var.database_type == "neon" ? module.neondb[0].database_password : var.db_password)
  n8n_encryption_key    = var.n8n_encryption_key
  labels                = local.gcp_labels
}

# Database module - manages Cloud SQL instance and database (only if using Cloud SQL)
module "cloud_sql" {
  count  = var.database_type == "cloud_sql" ? 1 : 0
  source = "./modules/cloud_sql"

  project_id          = var.gcp_project_id
  region              = var.gcp_region
  instance_name       = local.resource_names.cloud_sql_instance
  database_name       = var.db_name
  database_user       = var.db_user
  database_password   = var.db_password
  tier                = var.cloud_sql_tier
  disk_size           = var.cloud_sql_storage_size
  backup_enabled      = var.environment == "prod" ? true : false
  deletion_protection = var.environment == "prod" ? true : false
  labels              = local.gcp_labels
}

# NeonDB module - manages NeonDB project and database (only if using NeonDB)
module "neondb" {
  count  = var.database_type == "neon" ? 1 : 0
  source = "./modules/neondb"

  project_name              = var.neon_project_name
  postgres_version          = var.neon_postgres_version
  region                    = var.neon_region
  database_name             = var.db_name
  database_user             = var.db_user
  compute_min               = var.neon_compute_min
  compute_max               = var.neon_compute_max
  suspend_timeout           = var.neon_suspend_timeout
  quota_active_time         = var.neon_quota_active_time
  quota_compute_time        = var.neon_quota_compute_time
  quota_data_size           = var.neon_quota_data_size
  quota_data_transfer       = var.neon_quota_data_transfer
  enable_branch_protection  = var.neon_enable_branch_protection
  branch_size_limit         = var.neon_branch_size_limit
  org_id                    = var.neon_org_id
}

# Container module - manages Artifact Registry
module "container" {
  source = "./modules/container"

  project_id      = var.gcp_project_id
  region          = var.gcp_region
  repository_name = local.resource_names.artifact_repo
  labels          = local.gcp_labels
}

# Compute module - manages Cloud Run service and service account
module "compute" {
  source = "./modules/compute"

  project_id                     = var.gcp_project_id
  region                         = var.gcp_region
  service_name                   = local.resource_names.cloud_run_service
  service_account_name           = local.resource_names.service_account
  service_account_display_name   = "n8n Cloud Run Service Account"
  container_image                = "${module.container.repository_url}/${var.cloud_run_service_name}:latest"
  container_port                 = var.cloud_run_container_port
  cpu_limit                      = var.cloud_run_cpu
  memory_limit                   = var.cloud_run_memory
  max_instances                  = var.cloud_run_max_instances
  min_instances                  = 0
  database_connection_name       = var.database_type == "cloud_sql" ? module.cloud_sql[0].instance_connection_name : ""
  db_password_secret_id          = module.secrets.db_password_secret_id
  n8n_encryption_key_secret_id   = module.secrets.n8n_encryption_key_secret_id
  labels                         = local.gcp_labels

  environment_variables = {
    # Basic n8n configuration
    N8N_PATH      = "/"
    # Omit N8N_PORT so n8n defaults to the container port (5678)
    N8N_PROTOCOL  = "https"
    
    # Database configuration (varies by database type)
    DB_TYPE                = "postgresdb"
    DB_POSTGRESDB_DATABASE = var.db_name
    DB_POSTGRESDB_USER     = var.db_user
    DB_POSTGRESDB_HOST     = var.database_type == "cloud_sql" ? "/cloudsql/${module.cloud_sql[0].instance_connection_name}" : replace(module.neondb[0].host, ".neon.tech", "-pooler.neon.tech")
    DB_POSTGRESDB_PORT     = "5432"
    DB_POSTGRESDB_SCHEMA   = "public"
    DB_POSTGRESDB_SSL      = var.database_type == "neon" ? "true" : "disable"
    DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED = var.database_type == "neon" ? "false" : "false"
    DB_POSTGRESDB_POOL_SIZE = var.database_type == "neon" ? "5" : "10"
    
    # n8n runtime configuration
    N8N_USER_FOLDER            = "/home/node/.n8n"
    EXECUTIONS_PROCESS         = "main"
    EXECUTIONS_MODE            = "regular"
    GENERIC_TIMEZONE           = var.generic_timezone
    QUEUE_HEALTH_CHECK_ACTIVE  = "true"
    N8N_RUNNERS_ENABLED        = "true"
    
    # URL configuration – if you set a custom domain it will be picked up by n8n at runtime.
    # These are optional; leaving them blank avoids a Terraform cycle with the IAP module.
    # You can manually set them later if you need fully-qualified callback URLs.
    # N8N_HOST            = var.domain_name != "" ? var.domain_name : ""
    # N8N_WEBHOOK_URL     = ""
    # N8N_EDITOR_BASE_URL = ""
    # WEBHOOK_URL         = ""
  }

  startup_probe_initial_delay = 240
  startup_probe_timeout       = 240
  startup_probe_period        = 15
  startup_probe_failure_threshold = 10

  depends_on = [module.cloud_sql, module.neondb, module.container]
}

# IAP module - manages load balancer, IAP, and SSL certificates
module "iap" {
  source = "./modules/iap"

  project_id               = var.gcp_project_id
  region                   = var.gcp_region
  name_prefix              = local.resource_names.cloud_run_service
  cloud_run_service_name   = module.compute.service_name
  authorized_users         = var.iap_authorized_users
  oauth_brand_name         = var.oauth_brand_name
  oauth_support_email      = var.oauth_support_email
  domain_name              = var.domain_name

  depends_on = [module.compute]
} 