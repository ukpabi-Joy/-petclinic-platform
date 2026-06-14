# Jira Backlog — Petclinic Platform

## Epic 1 — Foundation & Remote State

### PetclinicPlatform1 — Terraform Directory Structure
Create the standard Terraform directory layout for this project.
**Acceptance Criteria:**
- terraform/bootstrap/ exists
- terraform/modules/ exists
- terraform/environments/dev/ exists
- terraform/environments/prod/ exists

### PetclinicPlatform2 — S3 State Bucket + DynamoDB Lock Table
**Acceptance Criteria:**
- S3 bucket: petclinic-tfstate-506261418156 in eu-central-1
- Versioning enabled
- AES256 encryption enabled
- All public access blocked
- DynamoDB table: petclinic-tfstate-lock
- Billing: PAY_PER_REQUEST
- Hash key: LockID (String)
- Bootstrap uses local state

### PetclinicPlatform3 — Backend Config for Dev
**Acceptance Criteria:**
- terraform/environments/dev/backend.hcl exists
- Points to petclinic-tfstate-506261418156
- Key: dev/terraform.tfstate
- Region: eu-central-1
- DynamoDB table: petclinic-tfstate-lock

### PetclinicPlatform4 — Backend Config for Prod
**Acceptance Criteria:**
- terraform/environments/prod/backend.hcl exists
- Key: prod/terraform.tfstate
- All other values same as dev

### PetclinicPlatform5 — AWS Provider and versions.tf
**Acceptance Criteria:**
- terraform/environments/dev/versions.tf exists
- terraform/environments/prod/versions.tf exists
- AWS provider ~> 5.0, region eu-central-1
- Terraform required version >= 1.6
- Default tags: Project=petclinic, ManagedBy=terraform, Environment=dev/prod
