# Vision

Use this example for a complete end-to-end Oracle Autonomous Database@Google Cloud deployment in ODB Network mode. It creates:

* One ODB network
* One client ODB subnet
* One Autonomous Database

The example composes `modules/odb-networking` and `modules/adb` in the same root module. ODB Network/Subnet outputs are passed directly as dependency maps, so the Autonomous Database uses dependency keys (`PRIMARY`, `CLIENT`) without copying resource names.

## Prerequisites

Before running it, confirm that:

* The Google Cloud project is enabled for Oracle Database@Google Cloud.
* The target region has the required entitlement and capacity.
* The target VPC network already exists. In production, this is usually supplied by the Google Cloud landing zone or platform networking stack, often as a Shared VPC.
* Google provider authentication is configured, for example Application Default Credentials via `gcloud auth application-default login`.
* The caller has permissions to manage Oracle Database@Google Cloud resources and reference the VPC network.

## Usage

1. Copy `input.auto.tfvars.template` to a name of your choice, following the pattern `<project-name>.auto.tfvars`.
2. Edit the copied file to provide GCP connectivity variables and adjust input variables — replace all placeholder values with actual values.
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

Review the plan carefully before applying. Autonomous Database provisioning can take up to 40 minutes.

See the module [README](../../README.md) for full attribute documentation.
