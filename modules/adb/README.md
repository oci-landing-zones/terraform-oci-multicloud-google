# Oracle Autonomous Database@Google Cloud Terraform Module

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

This module creates Oracle Autonomous Databases on Google Cloud using the `google_oracle_database_autonomous_database` resource.

Autonomous Database deployments use ODB Network mode only: `odb_network` / `odb_subnet`, with values supplied as full resource names or dependency keys. The Google provider's VPC/CIDR fields are outside this module's public interface.

The module follows the OCI Landing Zones style. Databases are declared through keyed maps, created with `for_each`, and returned with the same keys in the outputs.

Use this README for deployment guidance. Use [SPEC.md](./SPEC.md) for the full input and output contract.

For the recommended Day-1 and Day-2 control plane model, which is shared across the Oracle Database@AWS, Oracle Database@Google Cloud, and Oracle Database@Azure modules, see the [oci-multicloud-control-plane-model](https://github.com/oci-clickops/oci-multicloud-control-plane-model) repository.

## <a name="pre-requisites">Pre-requisites</a>

Before running Terraform against real infrastructure, make sure these pieces are already in place:

* A Google Cloud project enabled for Oracle Database@Google Cloud.
* Google provider authentication for the Terraform caller.
* IAM permissions to manage Oracle Database@Google Cloud resources.
* Terraform `>= 1.4.0` and HashiCorp Google provider `>= 7.35.0, < 8.0.0`.
* For this reusable module: an existing ODB Network and client ODB Subnet, created by `modules/odb-networking` or an equivalent stack.
* Oracle Database@Google Cloud entitlement and capacity in the target project and region.

The admin password is accepted as a separate sensitive input keyed by the same map key as the database. Each configured database must use exactly one admin password source: either a matching entry in `gcp_autonomous_databases_admin_passwords` or `properties.secret_id`. Unknown password keys are rejected when databases are configured. Do not store passwords in tfvars files committed to version control. Use the `TF_VAR_gcp_autonomous_databases_admin_passwords` environment variable instead. Passwords are validated at plan time: they must be 12–30 characters, include at least one uppercase letter, one lowercase letter, and one number, and must not contain double quotes or `admin` in any casing.

## <a name="getting-started">Getting Started</a>

Start with [examples/vision](./examples/vision) for a complete end-to-end ODB Network mode deployment. It composes `modules/odb-networking` and this module to create an ODB Network, client ODB Subnet, and Autonomous Database in one root module.

If you are using an ODB Network created by a separate networking stack, use [examples/existing-odb-network](./examples/existing-odb-network) instead for the multi-stack consumer pattern.

## <a name="configuration-model">Configuration Model</a>

Each database in `gcp_autonomous_databases_configuration` must set one ODB Network reference and one ODB Subnet reference. Each reference uses a single field that accepts either a full Google resource name or a key from the corresponding dependency map. Logical keys are case-sensitive; follow the OCI Landing Zones convention and use uppercase semantic keys such as `PROD_NET`, `PROD_CLIENT`, and `TXN`, while Google resource ID segments remain lowercase provider IDs.

Each database must also include a `properties` object with `db_workload` and `license_type`. The module keeps the Terraform type flexible enough to return an actionable module error, but the Google provider schema requires both fields whenever an Autonomous Database is planned.

Dependency-key form — recommended when the upstream ODB Network and Subnet come from dependency maps supplied by Terragrunt `dependency` blocks, `terraform_remote_state` outputs, HCP Terraform workspace outputs, or CI/CD pipeline variables:

```hcl
gcp_odb_networks_dependency = {
  PROD_NET = {
    id = "projects/my-project/locations/us-east4/odbNetworks/prod-net"
  }
}

gcp_odb_subnets_dependency = {
  PROD_CLIENT = {
    id      = "projects/my-project/locations/us-east4/odbNetworks/prod-net/odbSubnets/prod-client"
    purpose = "CLIENT_SUBNET"
  }
}

gcp_autonomous_databases_configuration = {
  TXN = {
    autonomous_database_id = "txn"
    odb_network            = "PROD_NET"     # logical key from the dependency map
    odb_subnet             = "PROD_CLIENT"
    properties             = { db_workload = "OLTP", license_type = "LICENSE_INCLUDED" }
  }
}
```

The reusable module receives direct dependency maps keyed by logical name. It does not read remote state or other transport-specific sources.

Direct form — useful when the ODB Network and Subnet were created by `gcloud`, an OCI console operator, or a separate stack:

```hcl
gcp_autonomous_databases_configuration = {
  TXN = {
    autonomous_database_id = "txn"
    odb_network            = "projects/my-project/locations/us-east4/odbNetworks/prod-net"
    odb_subnet             = "projects/my-project/locations/us-east4/odbNetworks/prod-net/odbSubnets/prod-client"
    properties             = { db_workload = "OLTP", license_type = "LICENSE_INCLUDED" }
  }
}
```

Use `odb_network` and `odb_subnet` for both forms. Values that start with `projects/` must match the full resource-name shape and are passed directly; other values are resolved as dependency keys. Bare cloud resource ID segments are not accepted as external resource references; a short value is valid only when it matches a key in the corresponding dependency map. To reference an external ODB Network or ODB Subnet that is not present in a dependency map, pass the full Google resource name. Uppercase logical keys keep local references visually and case-wise distinct from lowercase Google resource ID segments.

Common defaults such as project, location, labels, and deletion protection are handled by module-level inputs. Resource-specific values override the defaults. Project and location values must be non-empty when set and cannot contain whitespace. Google label keys must start with a lowercase letter. Label values may be empty and may contain lowercase letters, numbers, underscores, or hyphens. When `display_name` is omitted, Autonomous Database resources use `autonomous_database_id` as the display name. `module_name` is validated and the generated module label is sanitized for Google Cloud label rules.

The module performs strict validation at `terraform plan`: ODB Network and Subnet references must be geographically consistent (same project, location, and parent ODB Network segment), the Autonomous Database location must match the selected ODB Network/Subnet location, and ODB Subnet purpose must be `CLIENT_SUBNET` whenever the selected subnet resource name is known from `gcp_odb_subnets_dependency`. Full subnet resource names that are not present in the dependency map are passed through and cannot be purpose-checked by Terraform. Provider-sensitive fields such as `database`, labels, storage-size inputs, password source, customer contact email, and `private_endpoint_ip` are checked before the Google API call. The database project may differ from the ODB Network project when the network and subnet references are otherwise coherent. Duplicate resource names are left to the Google provider/API, matching the OCI module style. See [SPEC.md](./SPEC.md#plan-time-validations) for the full list.

### Output Controls

The reusable module emits Terraform outputs. Use `enable_output = false` only when a caller intentionally wants the `gcp_autonomous_databases` output to return `null`; `module_name` remains available.

## <a name="operational-drift-policy">Operational Drift Policy</a>

Oracle Autonomous Database can be operated through both Google and OCI control planes. Several properties drift during Oracle-managed maintenance or OCI-side operations. The module ignores changes to:

* `admin_password` — not rotated by Terraform after initial provisioning.
* `properties[0].compute_count` and `properties[0].cpu_core_count` — may change through auto-scaling.
* `properties[0].data_storage_size_tb` and `properties[0].data_storage_size_gb` — may change through storage auto-scaling.
* `properties[0].db_version` — may change through Oracle-managed upgrades.
* `properties[0].db_edition` — may change through OCI Day-2 operations.
* `properties[0].is_auto_scaling_enabled` and `properties[0].is_storage_auto_scaling_enabled` — may change through OCI operations.
* `properties[0].backup_retention_period_days` — may be adjusted through OCI Day-2 operations.
* `labels` — treated as creation-time metadata because the current Google provider plans replacement for label-only changes.

The policy follows Oracle's published guidance for the dual control-plane model. `operations_insights_state` is service-managed and is exposed only as an observed output. All other attributes remain visible to Terraform.

The exact ignored fields and rationale are documented in [SPEC.md](./SPEC.md).

## <a name="examples">Examples</a>

Available examples:

* [examples/vision](./examples/vision): recommended first deployment — complete end-to-end Autonomous Database deployment with ODB Network, client ODB Subnet, and a ready-to-rename `input.auto.tfvars.template`.
* [examples/existing-odb-network](./examples/existing-odb-network): multi-stack consumer deployment — creates an Autonomous Database using an existing ODB Network and ODB Subnet passed as dependency maps.

Each example includes an `input.auto.tfvars.template` file. Copy it to `<project-name>.auto.tfvars` and Terraform will load it automatically — no `terraform.tfvars` copy needed.

The examples deliberately do not declare a Terraform backend. For real deployments, configure a remote backend such as Google Cloud Storage, an OCI Object Storage bucket, Terraform Cloud, or any other supported backend in your own copy of the example.

## <a name="module-outputs">Module Outputs</a>

The module returns created resources with the same keys used in the input map:

* `gcp_autonomous_databases`
* `module_name`

Each database output includes stable identifiers, configured topology (`database`, `display_name`, `odb_network`, and `odb_subnet`), the OCI OCID, parsed OCI region, tenant, and compartment ID, OCI console URL, connection strings and URLs, private endpoint details, SQL Web Developer URL, Operations Insights state, Data Guard/peer metadata, and lifecycle state. Set `enable_output = false` to return `null` from `gcp_autonomous_databases`; `module_name` remains available.

`default_deletion_policy` defaults to `PREVENT` for Autonomous Database resources. Set a per-resource `deletion_policy` only when a stack intentionally needs `DELETE` or `ABANDON` behavior.

## <a name="license">License</a>

Copyright (c) 2026, Oracle and/or its affiliates.

Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

## <a name="known-issues">Known Issues</a>

1. Oracle Autonomous Database resources can take a long time to provision. If a creation or update operation is interrupted, rerun Terraform from the same working directory so it can continue from the current state.
2. The admin password is accepted at creation time but is not read back by the Google provider. Manage password rotation outside Terraform.
3. Some resource attributes are service-managed and appear only after provisioning completes. Downstream stacks should consume outputs only after the producing stack has completed successfully.
4. Both `odb_network` and `odb_subnet` references must exist before the Autonomous Database can be created. In multi-stack deployments, provision the networking stack first.
