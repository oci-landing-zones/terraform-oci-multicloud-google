# Existing ODB Network

Use this example for a multi-stack Oracle Autonomous Database@Google Cloud deployment using an existing ODB Network and ODB Subnet. It creates:

* One Autonomous Database attached to an existing ODB Network and subnet

This is the recommended pattern when the networking stack is managed separately — for example, when the ODB Network was created by `modules/odb-networking` in a different Terraform state.

Pass dependencies as inline maps injected from Terragrunt `dependency` blocks, `terraform_remote_state` outputs, HCP Terraform workspace outputs, or CI/CD pipeline variables. The reusable module receives direct maps keyed by logical name.

## Prerequisites

Before running it, confirm that:

* The Google Cloud project is enabled for Oracle Database@Google Cloud.
* The target region has the required entitlement and capacity.
* An existing ODB Network and ODB Subnet are available. The dependency maps must include their full resource names.
* Google provider authentication is configured, for example Application Default Credentials via `gcloud auth application-default login`.
* The caller has permissions to manage Oracle Database@Google Cloud resources.

## Usage

1. Copy `input.auto.tfvars.template` to a name of your choice, following the pattern `<project-name>.auto.tfvars`.
2. Edit the copied file — replace all `<REPLACE-BY-*>` placeholders in the dependency maps with the full resource names of the existing ODB Network and ODB Subnet.
3. Set the admin password via environment variable to avoid storing credentials in files:

```sh
export TF_VAR_gcp_autonomous_databases_admin_passwords='{"PRIMARY":"<your-password>"}'
```

4. Run the standard Terraform commands:

```sh
terraform init
terraform plan -out plan.out
terraform apply plan.out
```

See the module [README](../../README.md) for full attribute documentation.
