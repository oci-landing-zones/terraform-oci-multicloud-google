# Oracle Database@Google Cloud Terraform Module

## Table of Contents

- [Overview](#overview)
- [Pre-requisites](#pre-requisites)
- [Getting Started](#getting-started)
- [Configuration Model](#configuration-model)
- [Operational Drift Policy](#operational-drift-policy)
- [Examples](#examples)
- [Module Outputs](#module-outputs)
- [License](#license)
- [Known Issues](#known-issues)

## <a name="overview">Overview</a>

This repository provides a Terraform module for Oracle Database@Google Cloud resources managed through the HashiCorp Google provider.

It supports:

* Cloud Exadata Infrastructures
* Cloud VM Clusters

The module follows the OCI Landing Zones style. Resources are declared through keyed maps, created with `for_each`, and returned with the same keys in the outputs. That keeps downstream stacks from depending on copied resource names.

Cloud VM Cluster deployments use ODB Network mode only: `odb_network` / `odb_subnet` / `backup_odb_subnet`, with values supplied as full resource names or dependency keys. The Google provider's VPC/CIDR fields are outside this module's public interface.

Use this README for deployment guidance. Use [SPEC.md](./SPEC.md) for the full input and output contract.

For the recommended Day-1 and Day-2 control plane model, which is shared across the Oracle Database@AWS, Oracle Database@Google Cloud, and Oracle Database@Azure modules, see the [oci-multicloud-control-plane-model](https://github.com/oci-clickops/oci-multicloud-control-plane-model) repository.

## <a name="pre-requisites">Pre-requisites</a>

Before running Terraform against real infrastructure, make sure these pieces are already in place:

* A Google Cloud project enabled for Oracle Database@Google Cloud.
* Google provider authentication for the Terraform caller.
* IAM permissions to manage Oracle Database@Google Cloud Exadata resources.
* Terraform `>= 1.4.0` and HashiCorp Google provider `>= 7.35.0, < 8.0.0`.
* An existing ODB Network plus client and backup ODB Subnets, created by `modules/odb-networking` or an equivalent stack.
* Oracle Database@Google Cloud entitlement and capacity in the target project and region.
* RSA SSH public keys for VM Cluster access. Ed25519 keys are rejected by the Oracle Database@Google Cloud VM Cluster API.

ODB networking is intentionally outside this module boundary. In enterprise Google Cloud environments, the VPC and ODB networking layer are usually owned by a platform or networking stack. Use [../odb-networking](../odb-networking/README.md) when Terraform should create the ODB Network and ODB Subnets.

## <a name="getting-started">Getting Started</a>

Start with [examples/vision](./examples/vision) for a complete end-to-end deployment. The example composes `modules/odb-networking` and this module: networking is produced by the shared ODB networking module, then consumed here through dependency maps.

After the vision example works in your environment, use [../odb-networking/examples/basic](../odb-networking/examples/basic) for a standalone networking state and [examples/cluster](./examples/cluster) for the ExaDB consumer state.

## <a name="configuration-model">Configuration Model</a>

### Resource References

Every cross-resource reference uses a single field. Pick the value form that fits the way the upstream resource was managed:

* **Dependency-key form** — a logical name resolved against `*_configuration` for Exadata Infrastructure or a `*_dependency` map for externally managed resources such as ODB Network/Subnet. Use distinct, meaningful keys for local configuration and dependency maps so references remain obvious.
* **Direct form** — the literal full GCP resource name, useful for one-off references to externally managed infrastructure that is not modeled in any dependency map.

Values that start with `projects/` must match the full resource-name shape and are passed directly; other values are resolved as keys. Bare cloud resource ID segments are not accepted as external resource references; a short value is valid only when it matches a local configuration key or dependency-map key. To reference external Exadata Infrastructure, ODB Network, or ODB Subnet resources that are not present in a dependency map, pass the full Google resource name.

#### Side-by-side example

Dependency-key form — recommended when the Exadata Infrastructure is created in this module call and ODB networking is imported through dependency maps:

```hcl
gcp_cloud_exadata_infrastructures_configuration = {
  SHARED_EXA = {
    cloud_exadata_infrastructure_id = "shared-exa"
    properties = { shape = "Exadata.X11M" }
  }
}

gcp_cloud_vm_clusters_configuration = {
  PROD_CLUSTER = {
    cloud_vm_cluster_id        = "prod-cluster"
    exadata_infrastructure     = "SHARED_EXA"   # resolves to the entry above
    odb_network                = "PROD_NET"     # resolves from gcp_odb_networks_dependency
    odb_subnet                 = "PROD_CLIENT"
    backup_odb_subnet          = "PROD_BACKUP"
    properties = { license_type = "BRING_YOUR_OWN_LICENSE", gi_version = "19.0.0.0", cpu_core_count = 8 }
  }
}
```

Direct form — useful when the Exadata infrastructure was created by `gcloud`, an OCI console operator, or a parallel stack:

```hcl
gcp_cloud_vm_clusters_configuration = {
  PROD_CLUSTER = {
    cloud_vm_cluster_id    = "prod-cluster"
    exadata_infrastructure = "projects/my-project/locations/us-east4/cloudExadataInfrastructures/shared-exa"
    odb_network            = "projects/my-project/locations/us-east4/odbNetworks/prod-net"
    odb_subnet             = "projects/my-project/locations/us-east4/odbNetworks/prod-net/odbSubnets/prod-client"
    backup_odb_subnet      = "projects/my-project/locations/us-east4/odbNetworks/prod-net/odbSubnets/prod-backup"
    properties = { license_type = "BRING_YOUR_OWN_LICENSE", gi_version = "19.0.0.0", cpu_core_count = 8 }
  }
}
```

Both forms accept the same surrounding configuration. Mix them across different entries in the same map when that matches the way the upstream resources are owned.

#### Cross-resource consistency

For both direct resource names and dependency keys, the module enforces that the VM Cluster, Exadata Infrastructure, and ODB Network references are in the same Google Cloud location. It also enforces that ODB subnets belong to the parent ODB network (same project, location, and network segment). When subnet references resolve through dependency keys, the client `odb_subnet` must resolve to `purpose = CLIENT_SUBNET`, and `backup_odb_subnet` must resolve to `purpose = BACKUP_SUBNET`. Full ODB Subnet resource names are also validated against purpose metadata when the same subnet `id` is present in `gcp_odb_subnets_dependency`; otherwise Terraform cannot infer the subnet purpose at plan time. These checks run at plan time as resource preconditions. The module does not require the ODB Network project to match the VM Cluster project, which preserves Shared VPC and host-project topologies.

Common defaults such as project, location, GCP Oracle zone, labels, deletion protection, and Exadata maintenance windows are handled by module-level inputs. Resource-specific values, including provider operation timeouts, override the defaults.

The module rejects project and location values with leading, trailing, or internal whitespace. GCP Oracle zone values cannot be whitespace-only. The module also validates labels on defaults, Cloud Exadata Infrastructure resources, and VM Cluster resources before the provider call.

When `display_name` is omitted, Cloud Exadata Infrastructure and Cloud VM Cluster resources use their resource ID as the display name. `module_name` is also validated so the generated module label remains compatible with Google Cloud label rules.

VM Cluster SSH public keys can be supplied directly with `properties.ssh_public_keys` or centrally with `ssh_public_keys_file_path`. When the file path is set, the module reads one RSA OpenSSH public key per non-empty line and injects the resulting list into every VM Cluster configuration.

VM Cluster `properties.gi_version` is required by the Oracle Database@Google Cloud API during creation, even though the Google provider schema marks it optional. Choose a version available in the target Google Cloud location.

### Multi-Stack Handoff

For multi-team or multi-state deployments, a consumer stack passes dependency maps — from Terragrunt `dependency` blocks, `terraform_remote_state` outputs, HCP Terraform workspace outputs, or CI/CD pipeline variables — into these dependency inputs:

* `gcp_odb_networks_dependency`
* `gcp_odb_subnets_dependency`
* `gcp_cloud_exadata_infrastructures_dependency`

The reusable module receives direct dependency maps keyed by logical name. It does not read remote state or other transport-specific sources.

`modules/exadb` acts as both a consumer and a producer in the handoff chain: it consumes ODB Network and ODB Subnet dependency maps, then produces Cloud Exadata Infrastructure and Cloud VM Cluster outputs for downstream stacks such as `examples/oci-dbhome-handoff`.

The module stays backend-agnostic. It does not read remote state. Exadata Infrastructure keys can resolve to a resource created in the same module call or to `gcp_cloud_exadata_infrastructures_dependency`; ODB Network and ODB Subnet keys resolve only to their dependency maps.

### Output Controls

The reusable module emits Terraform outputs. Use `enable_output = false` only when a caller intentionally wants the resource outputs to return `null`; `module_name` remains available.

VPC and ODB networking creation stay outside this module boundary. If a deployment needs a new VPC for a proof of concept, create it in a separate landing-zone or networking stack, then create the ODB Network/Subnets with `modules/odb-networking`.

The module intentionally does not expose the Google provider's VM Cluster VPC/CIDR inputs.

## <a name="operational-drift-policy">Operational Drift Policy</a>

Oracle Database@Google Cloud can be operated through both Google and OCI control planes. This dual control-plane model is useful operationally, but it also means some fields can drift outside Terraform. The module uses a narrow `ignore_changes` policy for fields that are expected to drift during Oracle-managed maintenance or OCI-side operations.

For Cloud Exadata Infrastructure, the policy covers capacity and storage fields that may change outside Terraform. For Cloud VM Clusters, it covers Grid Infrastructure patch level, server placement, capacity, storage, backup, disk redundancy fields, and labels.

The policy is intentionally limited. VM Cluster labels are treated as creation-time metadata because the current Google provider plans a replacement for label changes. Exadata Infrastructure labels, maintenance windows, customer contacts, networking topology, and computed-only system attributes remain visible to Terraform. ODB Network and ODB Subnet drift belongs to the networking module or the stack that owns those resources.

The exact ignored fields, rationale, and Oracle documentation references are documented in [SPEC.md](./SPEC.md).

## <a name="examples">Examples</a>

Available examples:

* [examples/vision](./examples/vision): recommended first deployment path — complete end-to-end example with a ready-to-rename `input.auto.tfvars.template`.
* [../odb-networking/examples/basic](../odb-networking/examples/basic): networking-only deployment (Network team Stack 1) — creates an ODB Network and client/backup ODB Subnets on an existing VPC, without Exadata Infrastructure or VM Clusters.
* [examples/cluster](./examples/cluster): VM Cluster deployment — receives ODB networking and Cloud Exadata Infrastructure outputs from upstream stacks via inline maps. To use an existing Exadata Infrastructure without a dependency map, pass its resource name directly in `exadata_infrastructure` instead of using a key.
* [examples/oci-dbhome-handoff](./examples/oci-dbhome-handoff): downstream OCI wrapper — receives the VM Cluster dependency map, extracts the OCI OCID, and passes it to the OCI Exadata module for DB Homes, CDBs, and PDBs. The VM Cluster output is the producer contract for OCI-side DB Home, CDB, and PDB workflows because it exposes the OCI Cloud VM Cluster OCID consumed as `vm_cluster_id`. This wrapper inherits the upstream OCI Exadata module's Terraform requirement of `>= 1.5.0`.

Each example includes an `input.auto.tfvars.template` file. Copy it to `<project-name>.auto.tfvars` and Terraform will load it automatically — no `terraform.tfvars` copy needed.

The examples deliberately do not declare a Terraform backend. For real deployments, configure a remote backend such as Google Cloud Storage, an OCI Object Storage bucket, Terraform Cloud, or any other supported backend in your own copy of the example or wrapper stack. Keep state for networking, Exadata infrastructure, and VM cluster stacks separate when adopting the multi-state handoff pattern.

## <a name="module-outputs">Module Outputs</a>

The module returns created resources with the same keys used in the input maps:

* `gcp_cloud_exadata_infrastructures`
* `gcp_cloud_vm_clusters`
* `module_name`

Each resource output includes stable identifiers and selected computed attributes exported by the Google provider. Set `enable_output = false` to return `null` from `gcp_cloud_exadata_infrastructures` and `gcp_cloud_vm_clusters`; `module_name` remains available.

The Exadata Infrastructure and VM Cluster outputs include topology fields such as GCP Oracle zone and resolved Exadata/ODB references, plus operational fields such as server versions, capacity, Grid Infrastructure version, DB server placement, SCAN details, and OCI URLs. These are intended for validation, handoff to downstream stacks, and troubleshooting after long-running create operations complete.

`default_deletion_policy` defaults to `PREVENT` for Cloud Exadata Infrastructure and VM Cluster resources. Set a per-resource `deletion_policy` only when a stack intentionally needs `DELETE` or `ABANDON` behavior.

## <a name="license">License</a>

Copyright (c) 2026, Oracle and/or its affiliates.

Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

## <a name="known-issues">Known Issues</a>

1. Oracle Database@Google Cloud resources can take a long time to provision. If a creation or update operation is interrupted, rerun Terraform from the same working directory so it can continue from the current state.
2. VM cluster creation requires valid networking inputs. When using ODB subnets, provide both client and backup subnet references through full resource names or dependency keys.
3. Use explicit `db_server_ocids` for VM Cluster placement. The Google provider schema allows omitting them, but real VM Cluster creation can fail at API time without explicit DB server placement. To discover available DB server OCIDs, run the read-only command `gcloud oracle-database cloud-exadata-infrastructures db-servers list --location=<LOCATION> --cloud-exadata-infrastructure=<NAME>`.
4. Some resource attributes are service-managed and appear only after provisioning completes. Downstream stacks should consume outputs only after the producing stack has completed successfully.
