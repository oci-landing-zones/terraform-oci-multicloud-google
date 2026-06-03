# Cluster

Use this example for a VM Cluster consumer stack:

* **Network team (Stack 1)** — owns the ODB Network and ODB Subnets, typically managed in a dedicated networking stack such as `../../../odb-networking/examples/basic`.
* **Exadata infrastructure stack** — owns the Cloud Exadata Infrastructure, either through `modules/exadb` or another approved workflow.
* **VM Cluster stack** — owns the Cloud VM Cluster, consuming the networking and Exadata Infrastructure outputs from upstream stacks.

The consumer passes upstream outputs into `gcp_odb_networks_dependency`, `gcp_odb_subnets_dependency`, and `gcp_cloud_exadata_infrastructures_dependency`. The VM Cluster then references those resources by logical keys (`NETWORK`, `INFRA`, `CLIENT`, `BACKUP`) instead of hardcoded resource names.

Pass dependencies as inline maps injected from Terragrunt `dependency` blocks, `terraform_remote_state` outputs, HCP Terraform workspace outputs, or CI/CD pipeline variables. Only `id` is required for networks and Exadata infrastructure; subnets also require `purpose`.

The module itself does not read remote state or object storage. How dependencies are transported between stacks stays outside the module so it remains backend-agnostic.

## Prerequisites

Before running it, confirm that:

* The networking stack has already created the ODB Network and ODB Subnets.
* Dependency values (resource IDs) are available from the upstream stack.
* The existing Cloud Exadata Infrastructure is in the target region.
* Google provider authentication is configured (e.g., Application Default Credentials via `gcloud auth application-default login`).
* The caller has permissions to create Oracle Database@Google Cloud VM clusters.
* DB server OCIDs have been selected from the existing Cloud Exadata Infrastructure, with one OCID per VM node.

## Usage

1. Copy `input.auto.tfvars.template` to a name of your choice, following the pattern `<project-name>.auto.tfvars`.
2. Edit the copied file to provide GCP connectivity variables and adjust input variables — replace all `<REPLACE-BY-*>` placeholders with actual values.
3. The template uses inline maps as the primary pattern. Replace the placeholder values with the actual resource names from the upstream stack — injected from Terragrunt `dependency` blocks, `terraform_remote_state` outputs, or CI/CD pipeline variables:

```hcl
gcp_odb_networks_dependency = {
  NETWORK = { id = "<ODB-NETWORK-RESOURCE-NAME>" }
}
gcp_odb_subnets_dependency = {
  CLIENT = { id = "<CLIENT-SUBNET-RESOURCE-NAME>", purpose = "CLIENT_SUBNET" }
  BACKUP = { id = "<BACKUP-SUBNET-RESOURCE-NAME>", purpose = "BACKUP_SUBNET" }
}
gcp_cloud_exadata_infrastructures_dependency = {
  INFRA = { id = "<EXADATA-INFRASTRUCTURE-RESOURCE-NAME>" }
}
```

4. Set `db_server_ocids` to one validated DB server OCID per VM node. The provider schema allows `db_server_ocids = null`, but real VM Cluster creation can fail at API time without explicit placement, so keep `null` only for environments where server-side placement has already been validated.

5. Run the standard Terraform commands:

```sh
terraform init
terraform plan -out plan.out
terraform apply plan.out
```

Review the plan carefully before applying.

## Multiple VM Clusters

To deploy more than one VM Cluster on the same Exadata Infrastructure and network, add additional entries to `gcp_cloud_vm_clusters_configuration`. Each entry is independent — use distinct `cloud_vm_cluster_id`, `cluster_name`, and `hostname_prefix` values:

```hcl
gcp_cloud_vm_clusters_configuration = {
  PROD = {
    cloud_vm_cluster_id        = "my-prod-vm-cluster"
    display_name               = "Production VM Cluster"
    exadata_infrastructure     = "INFRA"
    odb_network                = "NETWORK"
    odb_subnet                 = "CLIENT"
    backup_odb_subnet          = "BACKUP"
    properties = {
      cluster_name    = "prod"
      hostname_prefix = "prod"
      # ...
    }
  }
  NONPROD = {
    cloud_vm_cluster_id        = "my-nonprod-vm-cluster"
    display_name               = "Non-Production VM Cluster"
    exadata_infrastructure     = "INFRA"
    odb_network                = "NETWORK"
    odb_subnet                 = "CLIENT"
    backup_odb_subnet          = "BACKUP"
    properties = {
      cluster_name    = "nonprod"
      hostname_prefix = "nprd"
      # ...
    }
  }
}
```

Both clusters share the same Exadata Infrastructure and ODB network. Each has its own CPU, memory, and storage allocation drawn from the shared infrastructure capacity.

See the module [README](../../README.md) for full attribute documentation.
