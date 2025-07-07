# Minimal terraform.tfvars example for n8n-gcr
# -------------------------------------------------
# Provide ONLY the variables that **must** be set for a working deployment.
# Everything else has sensible defaults or will be auto-generated.

# REQUIRED: Google Cloud project where resources will be created
gcp_project_id = "n8n-on-gcr"
oauth_support_email = "ceble@dialectron.chat"

# REQUIRED: At least one email that can access n8n via IAP
iap_authorized_users = [
  "ceble@dialectron.chat"
]

# -------------------------------------------------
# OPTIONAL: Switch to NeonDB instead of Cloud SQL
# -------------------------------------------------
database_type = "neon"
neon_api_key  = "napi_yum6n63ud3aqspp8qpz7mn8fy6n85s5szyfuq3vwx5ucmaa1o59oe3umb1ieus42"
neon_org_id   = "org-lucky-sound-33119804"

# Notes:
# • Leave db_password and n8n_encryption_key empty – secure values will be auto-generated.
# • The default region is europe-west1; override with gcp_region if needed. 