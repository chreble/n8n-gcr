# Enable required APIs
resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iap" {
  service            = "iap.googleapis.com"
  disable_on_destroy = false
}

# OAuth brand for IAP – requires explicit support email
resource "google_iap_brand" "main" {
  support_email     = var.oauth_support_email
  application_title = var.oauth_brand_name
  project           = var.project_id
  depends_on        = [google_project_service.iap]
}

# IAP OAuth2 client
resource "google_iap_client" "main" {
  display_name = "${var.name_prefix} IAP Client"
  brand        = google_iap_brand.main.name
}

# Global IP address for the load balancer
resource "google_compute_global_address" "main" {
  name       = "${var.name_prefix}-ip"
  ip_version = "IPV4"
  depends_on = [google_project_service.compute]
}

# Derive a reachable hostname. If user provides domain_name we use it; otherwise create a nip.io hostname that resolves automatically to the LB IP.
locals {
  lb_hostname = var.domain_name != "" ? var.domain_name : "${replace(google_compute_global_address.main.address, ".", "-")}.nip.io"
}

# SSL certificate (Google-managed, always created)
resource "google_compute_managed_ssl_certificate" "main" {
  name = "${var.name_prefix}-cert"

  managed {
    domains = [local.lb_hostname]
  }

  depends_on = [google_project_service.compute]
}

# Network Endpoint Group for Cloud Run
resource "google_compute_region_network_endpoint_group" "main" {
  name                  = "${var.name_prefix}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = var.cloud_run_service_name
  }

  depends_on = [google_project_service.compute]
}

# Backend service with IAP
resource "google_compute_backend_service" "main" {
  name                  = "${var.name_prefix}-backend"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = var.backend_timeout_sec
  enable_cdn            = false
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.main.id
  }

  iap {
    enabled              = true
    oauth2_client_id     = google_iap_client.main.client_id
    oauth2_client_secret = google_iap_client.main.secret
  }

  depends_on = [google_project_service.compute]
}

# URL map for HTTPS traffic
resource "google_compute_url_map" "main" {
  name            = "${var.name_prefix}-url-map"
  default_service = google_compute_backend_service.main.id

  depends_on = [google_project_service.compute]
}

# HTTPS proxy
resource "google_compute_target_https_proxy" "main" {
  name    = "${var.name_prefix}-https-proxy"
  url_map = google_compute_url_map.main.id

  ssl_certificates = [google_compute_managed_ssl_certificate.main.id]

  depends_on = [google_project_service.compute]
}

# Global forwarding rule for HTTPS
resource "google_compute_global_forwarding_rule" "https" {
  name                  = "${var.name_prefix}-https-rule"
  target                = google_compute_target_https_proxy.main.id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.main.address

  depends_on = [google_project_service.compute]
}

# HTTP to HTTPS redirect
resource "google_compute_url_map" "http_redirect" {
  name = "${var.name_prefix}-http-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }

  depends_on = [google_project_service.compute]
}

resource "google_compute_target_http_proxy" "http_redirect" {
  name    = "${var.name_prefix}-http-proxy"
  url_map = google_compute_url_map.http_redirect.id

  depends_on = [google_project_service.compute]
}

resource "google_compute_global_forwarding_rule" "http" {
  name                  = "${var.name_prefix}-http-rule"
  target                = google_compute_target_http_proxy.http_redirect.id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.main.address

  depends_on = [google_project_service.compute]
}

# IAM policy for authorized users
resource "google_iap_web_iam_member" "users" {
  count   = length(var.authorized_users)
  project = var.project_id
  role    = "roles/iap.httpsResourceAccessor"
  member  = "user:${var.authorized_users[count.index]}"

  depends_on = [google_compute_backend_service.main]
}

# ------------------------------------------------------------
# Ensure the Identity-Aware Proxy (IAP) service agent exists so
# we can grant it permission to invoke the private Cloud Run
# backend. Without this explicit creation step the service
# agent might not appear until *after* Terraform tries to bind
# roles/run.invoker, causing failures in protected orgs.
# ------------------------------------------------------------
resource "google_project_service_identity" "iap_sa" {
  provider = google-beta
  project = var.project_id
  service = "iap.googleapis.com"
}

# Grant Cloud Run invoker role to the IAP service agent so the
# HTTPS load balancer (IAP) can call the backend Cloud Run
# service once users are authenticated.
resource "time_sleep" "wait_for_iap_sa" {
  depends_on = [google_project_service_identity.iap_sa]
  create_duration = "30s"
}

resource "google_cloud_run_v2_service_iam_member" "iap_invoker" {
  project  = var.project_id
  location = var.region
  name     = var.cloud_run_service_name

  role   = "roles/run.invoker"
  member = "serviceAccount:${google_project_service_identity.iap_sa.email}"

  depends_on = [time_sleep.wait_for_iap_sa]
}

# Make the remainder of the IAP infrastructure wait until the
# service agent is provisioned to avoid race conditions when
# enabling the IAP API. 