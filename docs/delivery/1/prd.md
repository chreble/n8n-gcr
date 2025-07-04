# PBI-1: Terraform Deployment for n8n on Google Cloud Run

## Overview
This PBI covers automating the deployment of n8n on Google Cloud using Terraform so that the entire infrastructure can be provisioned, updated, and destroyed in a reproducible way.

## Problem Statement
The current guide relies on manual gcloud commands that are error-prone and time-consuming. A Terraform configuration is partially present but needs to achieve full feature parity with the manual setup and be documented as an official deployment method.

## User Stories
* **As an ops engineer**, I want to provision the full n8n stack with a single `terraform apply` so that I can deploy reliably and repeatably.
* **As a developer**, I want to destroy all resources with `terraform destroy` so that I avoid cloud cost leakage.

## Technical Approach
1. Review the manual deployment steps and existing Terraform code under `contrib/self-host-n8n-on-gcr/terraform`.
2. Ensure all Google Cloud services, IAM roles, secrets, Cloud SQL, Artifact Registry, and Cloud Run resources match the manual guide.
3. Implement any missing resources or variables.
4. Provide sensible defaults and documentation for overrides.
5. Output the Cloud Run service URL.

## UX/UI Considerations
CLI-based interaction only. Ensure variable names are intuitive and example `terraform.tfvars` is clear.

## Acceptance Criteria
- Executing `terraform apply` in the module provisions a functioning n8n instance accessible via HTTPS.
- Executing `terraform destroy` removes all provisioned resources without residual billing items.
- README is updated to reference Terraform deployment steps.

## Dependencies
- Google Cloud project with billing enabled.
- Terraform v1.4+ and Google provider v4+.

## Open Questions
- Should we split the configuration into reusable modules?
- Do we enforce specific n8n versions or allow override?

## Related Tasks
Will be tracked in `tasks.md` within the same directory.

[Back to backlog](../backlog.md#user-content-1) 