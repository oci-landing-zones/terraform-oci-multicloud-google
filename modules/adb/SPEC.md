# Oracle Autonomous Database@Google Cloud Terraform Module Specification

## Table of Contents

- [Overview](#overview)
- [Compatibility](#compatibility)
- [Module Inputs](#module-inputs)
- [Autonomous Databases](#autonomous-databases)
- [Plan-time Validations](#plan-time-validations)
- [Module Outputs](#module-outputs)

## <a name="overview">Overview</a>

This document is the technical contract for the module. Use it when you need exact input shapes, reference rules, lifecycle behavior, or output names.

The README covers deployment guidance and examples. This specification focuses on the Terraform interface: keyed resource maps, networking mode validation, lifecycle drift policy, and outputs.

## <a name="compatibility">Compatibility</a>

This module requires Terraform `>= 1.4.0` and HashiCorp Google provider `>= 7.35.0, < 8.0.0`.

Google Cloud project enablement, Oracle Database@Google Cloud entitlement, IAM permissions, and provider authentication are external prerequisites.

Autonomous Databases intentionally use ODB Network mode only. The Google provider's VPC/CIDR inputs (`network` and `cidr`) are outside this module's public contract.

Out of scope for this module: VPC/CIDR mode, Autonomous Database clones, refreshable clones, and cross-region clones (the provider's `source_config` block on `google_oracle_database_autonomous_database` is not exposed). Use the Google provider directly or extend this module if these capabilities are required.

## <a name="module-inputs">Module Inputs</a>

The module accepts these input variables.

### General

* `module_name`: The module name. Defaults to `oracle-autonomous-database-at-gcp`. It must be compatible with Google Cloud label value syntax because it is included in the module label.
* `enable_output`: Whether Terraform should enable module resource outputs. Defaults to `true`.
* `default_project_id`: Default Google Cloud project ID used by resources when `project_id` is not set on the resource. If set, it must be non-empty and contain no whitespace.
* `default_location`: Default Google Cloud region used by resources when `location` is not set on the resource. If set, it must be non-empty and contain no whitespace.
* `default_labels`: Default labels merged into all resources. Resource-specific labels win on key collisions. Keys and values must follow Google Cloud label syntax: keys must start with a lowercase letter and contain lowercase letters, numbers, underscores, or hyphens; values may be empty and may contain lowercase letters, numbers, underscores, or hyphens.
* `default_deletion_protection`: Default deletion protection value. Defaults to `true`.
* `default_deletion_policy`: Default deletion policy for resources that support `deletion_policy`. Defaults to `PREVENT`. Must be `DELETE`, `PREVENT`, or `ABANDON`.
* `gcp_odb_networks_dependency`: Externally managed ODB Networks this module may consume by key. Accepts a direct map keyed by logical name.
* `gcp_odb_subnets_dependency`: Externally managed ODB Subnets this module may consume by key. Accepts a direct map keyed by logical name.
* `gcp_autonomous_databases_admin_passwords`: Admin passwords for Autonomous Databases, keyed by the same keys as `gcp_autonomous_databases_configuration`. Sensitive. Do not store in committed files — use `TF_VAR_gcp_autonomous_databases_admin_passwords` instead. Each configured database must use either a matching password entry or `properties.secret_id`, but not both, and unknown password keys are rejected when databases are configured. Values must be 12–30 characters, include at least one uppercase letter, one lowercase letter, and one number, and must not contain double quotes or `admin` in any casing.

### Dependency Inputs

`gcp_odb_networks_dependency` and `gcp_odb_subnets_dependency` implement the OCI Landing Zones state-handoff pattern. A consumer stack passes direct dependency maps from Terragrunt `dependency` blocks, `terraform_remote_state` outputs, HCP Terraform workspace outputs, or CI/CD pipeline variables into these inputs. Remote-state, GCS, GitHub, Terraform Cloud, RMS, or other transport concerns belong outside this reusable module.

`gcp_odb_networks_dependency` entries:

* `id`: Required. Full resource name in `projects/{project}/locations/{location}/odbNetworks/{odb_network}` format.

`gcp_odb_subnets_dependency` entries:

* `id`: Required. Full resource name in `projects/{project}/locations/{location}/odbNetworks/{odb_network}/odbSubnets/{odb_subnet}` format.
* `purpose`: Required. `CLIENT_SUBNET` or `BACKUP_SUBNET`. The module validates this field is set on every dependency entry and additionally rejects subnets that resolve to a non-`CLIENT_SUBNET` purpose when the selected subnet resource name is known from `gcp_odb_subnets_dependency`. This applies to dependency-key references and to full ODB Subnet resource names that match an entry in the dependency map. Full ODB Subnet resource names that are not present in the dependency map are passed through and cannot be purpose-checked by Terraform. The same map produced by `modules/odb-networking` already emits this field, so the handoff works without modification.

## <a name="autonomous-databases">Autonomous Databases</a>

* `gcp_autonomous_databases_configuration`: Map of Autonomous Databases to create.

Each map value has these attributes:

* `autonomous_database_id`: Required. The Autonomous Database ID. Must start with a lowercase letter, end with a lowercase letter or number, contain only lowercase letters, numbers, and hyphens, and be 1–63 characters long.
* `database`: Optional. Database name. If set, it must begin with a letter, contain only alphanumeric characters, and be at most 30 characters long. Provider/API uniqueness rules still apply at create time.
* `display_name`: Optional. Human-readable display name. Defaults to `autonomous_database_id` when omitted.
* `location`: Optional. The Google Cloud region. Overrides `default_location`. If set, it must be non-empty and contain no whitespace.
* `project_id`: Optional. The Google Cloud project ID. Overrides `default_project_id`. If set, it must be non-empty and contain no whitespace.
* `labels`: Optional. Labels for the database. Keys and values must follow the same Google Cloud label syntax as `default_labels`.
* `deletion_protection`: Optional. Whether deletion protection is enabled. Overrides `default_deletion_protection`.
* `deletion_policy`: Optional. Overrides `default_deletion_policy`. Must be `DELETE`, `PREVENT`, or `ABANDON`.
* `timeouts`: Optional. Provider timeout overrides for `create`, `update`, and `delete`.

**Networking — ODB Network mode:**

* `odb_network`: Required. ODB Network reference. Accepts either a full resource name in `projects/{project}/locations/{location}/odbNetworks/{odb_network}` format or a key from `gcp_odb_networks_dependency`.
* `odb_subnet`: Required. ODB Subnet reference. Accepts either a full resource name in `projects/{project}/locations/{location}/odbNetworks/{odb_network}/odbSubnets/{odb_subnet}` format or a key from `gcp_odb_subnets_dependency`.

Each Autonomous Database must set `odb_network` and `odb_subnet`. Values that start with `projects/` must match the full resource-name shape and are passed directly; other values are resolved as dependency keys. Bare cloud resource ID segments are not accepted as external resource references; a short value is valid only when it matches a key in the corresponding dependency map. To reference an external ODB Network or ODB Subnet that is not present in a dependency map, pass the full Google resource name. Logical keys are case-sensitive and should follow the OCI Landing Zones convention: uppercase semantic keys for local/dependency map entries, with Google resource ID segments kept in lowercase provider syntax.

The `properties` object is required in practice because the Google provider schema requires `db_workload` and `license_type` whenever an Autonomous Database is planned. The Terraform input type remains flexible enough for the module to return an actionable plan-time error when the object or either required field is omitted.

The `properties` object has these attributes:

* `db_workload`: Required. `DB_WORKLOAD_UNSPECIFIED`, `OLTP`, `DW`, `AJD`, or `APEX`.
* `license_type`: Required. `LICENSE_TYPE_UNSPECIFIED`, `LICENSE_INCLUDED`, or `BRING_YOUR_OWN_LICENSE`.
* `compute_count`: Optional. Number of compute servers.
* `cpu_core_count`: Optional. Number of CPU cores.
* `data_storage_size_tb`: Optional. Storage size in terabytes. Mutually exclusive with `data_storage_size_gb`.
* `data_storage_size_gb`: Optional. Storage size in gigabytes. Mutually exclusive with `data_storage_size_tb`.
* `db_version`: Optional. Oracle Database version, for example `19c` or `23ai`. If set, it must be non-empty.
* `db_edition`: Optional. `DATABASE_EDITION_UNSPECIFIED`, `STANDARD_EDITION`, or `ENTERPRISE_EDITION`.
* `character_set`: Optional. Character set. Default: `AL32UTF8`. If set, it must be non-empty.
* `n_character_set`: Optional. National character set. Default: `AL16UTF16`. If set, it must be non-empty.
* `private_endpoint_ip`: Optional. Private endpoint IPv4 address without CIDR suffix.
* `private_endpoint_label`: Optional. Private endpoint label. If set, it must be non-empty.
* `is_auto_scaling_enabled`: Optional. Enable CPU auto-scaling.
* `is_storage_auto_scaling_enabled`: Optional. Enable storage auto-scaling.
* `backup_retention_period_days`: Optional. Backup retention days, 1–60.
* `maintenance_schedule_type`: Optional. `MAINTENANCE_SCHEDULE_TYPE_UNSPECIFIED`, `EARLY`, or `REGULAR`.
* `mtls_connection_required`: Optional. Whether mTLS is required.
* `secret_id`: Optional. OCI vault secret ID for the admin password. If set, it must be non-empty.
* `vault_id`: Optional. OCI vault ID. If set, it must be non-empty.
* `customer_contacts`: Optional. List of `{ email = string }` objects for Oracle support notifications. Email values are validated with a simple plan-time email format check.

`operations_insights_state` is service-managed. It is not accepted as a configurable module input and is returned only as an observed output after the Google provider reports it.

The module intentionally ignores Terraform drift for selected Autonomous Database fields. These values can change after Oracle-managed maintenance or after operations performed through the OCI control plane.

Ignored Autonomous Database fields:

* `labels`
* `admin_password`
* `properties[0].compute_count`
* `properties[0].cpu_core_count`
* `properties[0].data_storage_size_tb`
* `properties[0].data_storage_size_gb`
* `properties[0].db_version`
* `properties[0].db_edition`
* `properties[0].is_auto_scaling_enabled`
* `properties[0].is_storage_auto_scaling_enabled`
* `properties[0].backup_retention_period_days`

The policy follows Oracle's published guidance for the dual control-plane model (see [Modify an Autonomous Database](https://docs.oracle.com/en-us/iaas/Content/database-at-gcp/gcpmd-modify-autonomous-ai-database.html)), which recommends ignoring capacity, storage, version, edition, auto-scaling flags, and backup retention fields that change when Day-2 operations are performed through the OCI control plane. Labels are also ignored after creation because the current Google provider plans replacement for label-only changes. Treat Autonomous Database labels as creation-time metadata. All other attributes remain visible to Terraform.

Provider resource: `google_oracle_database_autonomous_database`.

## <a name="plan-time-validations">Plan-time Validations</a>

The module enforces these checks at `terraform plan`, not at apply, to avoid late provider failures:

* **Reference requirement** — each entry must set `odb_network` and `odb_subnet`.
* **Logical key convention** — map keys are case-sensitive; use uppercase semantic keys so dependency-key references stay distinct from lowercase Google resource ID segments.
* **Geographic coherence** — `odb_subnet` (literal or resolved through a dependency key) must belong to the selected `odb_network` and share the same project, location, and parent ODB Network segment. The Autonomous Database location must match the selected ODB Network/Subnet location. The database project may differ from the ODB Network project when the network and subnet references are otherwise coherent.
* **Subnet purpose** — when the selected `odb_subnet` resource name is known from `gcp_odb_subnets_dependency`, every known dependency entry for that same subnet ID must have `purpose = "CLIENT_SUBNET"`. Backup subnets and duplicate dependency entries with conflicting purposes are rejected. Full ODB Subnet resource names that are not present in the dependency map are passed through and cannot be purpose-checked by Terraform.
* **Admin password policy** — each configured database must use exactly one password source: a matching entry in `gcp_autonomous_databases_admin_passwords` or `properties.secret_id`. Password keys that do not match configured database keys are rejected. Each supplied admin password must satisfy the Oracle Autonomous Database password policy enforced by the module: length 12–30, at least one uppercase letter, one lowercase letter, one number, no double quotes, and no `admin` substring in any casing.
* **Database name format** — `database`, when set, must match the Google provider rule: starts with a letter, contains only alphanumeric characters, and is at most 30 characters long. Duplicate resource or database names are left to the Google provider/API, matching the OCI module style.
* **Google label syntax** — `default_labels` and per-resource `labels` are validated for Google Cloud label-compatible keys and values before planning resources. Label keys must start with a lowercase letter. Label values may be empty and may contain lowercase letters, numbers, underscores, or hyphens.
* **Project and location hygiene** — `default_project_id`, `default_location`, per-resource `project_id`, and per-resource `location` can be omitted, but cannot be whitespace-only strings and cannot contain leading, trailing, or internal whitespace.
* **Deletion policy enum** — `default_deletion_policy` and per-resource `deletion_policy` must be `DELETE`, `PREVENT`, or `ABANDON`.
* **Storage size exclusivity** — `data_storage_size_tb` and `data_storage_size_gb` cannot both be set on the same database.
* **Service-managed fields** — `operations_insights_state` cannot be configured as an input.
* **Private endpoint IP format** — `private_endpoint_ip` must be a plain IPv4 address, not a CIDR range.
* **Customer contact email format** — every `customer_contacts.email` value must look like an email address.
* **Non-empty optional strings** — exposed optional string fields that are passed directly to the provider (`character_set`, `n_character_set`, `db_version`, `private_endpoint_label`, `secret_id`, and `vault_id`) cannot be whitespace-only strings.

These checks fail with actionable error messages before any Google Cloud API call is made. They complement the variable-level format validations (resource name regex, enum values, numeric ranges) which run earlier as part of input parsing.

## <a name="module-outputs">Module Outputs</a>

The module returns these outputs:

* `module_name`: The module instance name.
* `gcp_autonomous_databases`: Created Autonomous Databases, keyed by input key.

Each database output includes:

* Google identifiers and configured topology: `id`, `name`, `database`, `display_name`, `location`, `project`, `odb_network`, and `odb_subnet`.
* OCI identifiers: `ocid`, `oci_url`, `oci_region`, `oci_tenant`, and `oci_compartment_id`.
* Connectivity details: `connection_strings`, `connection_urls`, `private_endpoint`, `private_endpoint_ip`, `private_endpoint_label`, and `sql_web_developer_url`.
* Lifecycle and peer metadata: `state`, `operations_insights_state`, `role`, `peer_autonomous_databases`, `peer_db_ids`, `permission_level`, `is_local_data_guard_enabled`, `local_disaster_recovery_type`, `local_standby_db`, and `disaster_recovery_supported_locations`.

If `enable_output` is `false`, `gcp_autonomous_databases` returns `null`; `module_name` remains available.
