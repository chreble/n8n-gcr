output "load_balancer_ip" {
  description = "IP address of the load balancer"
  value       = google_compute_global_address.main.address
}

output "iap_url" {
  description = "Public URL to access the service through IAP"
  value       = "https://${local.lb_hostname}"
}

output "ssl_certificate_name" {
  description = "Name of the SSL certificate (if using custom domain)"
  value       = var.domain_name != "" ? google_compute_managed_ssl_certificate.main.name : null
}

output "backend_service_name" {
  description = "Name of the backend service"
  value       = google_compute_backend_service.main.name
}

output "oauth_brand_name" {
  description = "Name of the OAuth brand"
  value       = google_iap_brand.main.name
}

output "iap_client_id" {
  description = "IAP OAuth client ID"
  value       = google_iap_client.main.client_id
  sensitive   = true
} 