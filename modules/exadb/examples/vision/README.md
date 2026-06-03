# Vision

Use this example for a complete end-to-end Oracle Database@Google Cloud deployment. It creates:

* One ODB network
* One client ODB subnet
* One backup ODB subnet
* One Cloud Exadata Infrastructure
* One Cloud VM Cluster

The example composes `modules/odb-networking` and `modules/exadb` in the same root module. ODB Network/Subnet outputs are passed directly as dependency maps, so the VM Cluster uses dependency keys (`PRIMARY`, `CLIENT`, `BACKUP`) without copying resource names. It also sets a default maintenance window and explicit timeouts for long-running operations.

## Prerequisites

Before running it, confirm that:

* The Google Cloud project is enabled for Oracle Database@Google Cloud.
* The target region has the required entitlement and capacity.
* The VPC network already exists. In production, this is usually supplied by the Google Cloud landing zone or platform networking stack, often as a Shared VPC.
* Google provider authentication is configured (e.g., Application Default Credentials via `gcloud auth application-default login`).
* The caller has permissions to manage Oracle Database@Google Cloud resources and reference the VPC network.

## Usage

1. Copy `input.auto.tfvars.template` to a name of your choice, following the pattern `<project-name>.auto.tfvars`.
2. Edit the copied file to provide GCP connectivity variables and adjust input variables — replace all `<REPLACE-BY-*>` placeholders with actual values.
3. Run the standard Terraform commands:

```sh
terraform init
terraform plan -out plan.out
terraform apply plan.out
```

Review the plan carefully before applying. Pay particular attention to the Cloud Exadata Infrastructure and VM Cluster properties, as those operations can take a long time and may involve service-side capacity checks.

See the module [README](../../README.md) for full attribute documentation.
