# Oracle Database@Google Cloud Terraform Module Specification

## Table of Contents

- [Overview](#overview)
- [Compatibility](#compatibility)
- [Module Inputs](#module-inputs)
- [Cloud Exadata Infrastructures](#cloud-exadata-infrastructures)
- [Cloud VM Clusters](#cloud-vm-clusters)
- [Module Outputs](#module-outputs)

## <a name="overview">Overview</a>

This document is the technical contract for the module. Use it when you need exact input shapes, reference rules, lifecycle behavior, or output names.

The README covers deployment guidance and examples. This specification focuses on the Terraform interface: keyed resource maps, module-key references, input validation behavior, lifecycle drift policy, and outputs.

## <a name="compatibility">Compatibility</a>

This module requires Terraform `>= 1.4.0` and HashiCorp Google provider `>= 7.13.0, < 8.0.0`.

Google Cloud project enablement, Oracle Database@Google Cloud entitlement, IAM permissions, provider authentication, and ODB networking are external prerequisites. The module validates the Terraform-side input contract, but it cannot validate service entitlement or regional capacity before the provider calls the Google API.

The module intentionally does not create Google Cloud VPC networks, ODB Networks, or ODB Subnets. Use `modules/odb-networking` or an equivalent platform stack to create the ODB networking layer, then pass its outputs to this module through dependency maps.

Cloud VM Clusters intentionally use ODB Network mode only. The Google provider's VM Cluster VPC/CIDR inputs (`network`, `cidr`, and `backup_subnet_cidr`) are outside this module's public contract.

## <a name="module-inputs">Module Inputs</a>

The module accepts these input variables.

### General

* `module_name`: The module name. Defaults to `oracle-database-at-gcp`. It must be compatible with Google Cloud label value syntax because it is included in the module label.
* `enable_output`: Whether Terraform should enable module resource outputs. Defaults to `true`.
* `ssh_public_keys_file_path`: Optional path to a file containing RSA OpenSSH public keys for VM Cluster access. The file must contain one public key per non-empty line. When set, it replaces `properties.ssh_public_keys` for every VM Cluster in the module call.
* `default_project_id`: Default Google Cloud project ID used by resources when `project_id` is not set on the resource. Must be `null` or non-empty with no whitespace.
* `default_location`: Default Google Cloud region used by resources when `location` is not set on the resource. Must be `null` or non-empty with no whitespace.
* `default_gcp_oracle_zone`: Default GCP Oracle zone used by resources that support it. Must be `null` or non-empty.
* `default_labels`: Default labels merged into all resources. Resource-specific labels win on key collisions. Keys and values must satisfy the module label validation.
* `default_deletion_protection`: Default deletion protection value for resources that support `deletion_protection`. Defaults to `true`.
* `default_cloud_exadata_maintenance_window`: Default Cloud Exadata Infrastructure maintenance window used when a resource does not set `properties.maintenance_window`. Values must use the same enum values and ranges documented for resource-level maintenance windows.
* `gcp_odb_networks_dependency`: Externally managed ODB Networks that this module may consume by key. Accepts a direct map keyed by logical name.
* `gcp_odb_subnets_dependency`: Externally managed ODB Subnets that this module may consume by key. Accepts a direct map keyed by logical name.
* `gcp_cloud_exadata_infrastructures_dependency`: Externally managed Cloud Exadata Infrastructures that this module may consume by key. Accepts a direct map keyed by logical name.

### Dependency Inputs

Dependency inputs implement the OCI Landing Zones state-handoff pattern for Google resources. A consumer stack passes direct dependency maps from Terragrunt `dependency` blocks, `terraform_remote_state` outputs, HCP Terraform workspace outputs, or CI/CD pipeline variables into these inputs. Remote-state, GCS, GitHub, Terraform Cloud, RMS, or other transport concerns belong outside this reusable module.

The module resolves non-resource-name Exadata Infrastructure references against resources created in the same module call and against `gcp_cloud_exadata_infrastructures_dependency`. Non-resource-name ODB Network and ODB Subnet references resolve only against `gcp_odb_networks_dependency` and `gcp_odb_subnets_dependency`.

`gcp_odb_networks_dependency` is a map keyed by logical name. Each value has these attributes:

* `id`: Required. ODB Network full resource name in `projects/{project}/locations/{location}/odbNetworks/{odb_network}` format. The ODB Network ID segment is always derived from `id`.

Output maps produced by `modules/odb-networking` also include informational fields (`name`, `odb_network_id`, `location`, `project`, `state`, `entitlement_id`) for debugging and downstream consumers. These are ignored by this module and need not be supplied when constructing the map manually.

`gcp_odb_subnets_dependency` is a map keyed by logical name. Each value has these attributes:

* `id`: Required. ODB Subnet full resource name in `projects/{project}/locations/{location}/odbNetworks/{odb_network}/odbSubnets/{odb_subnet}` format. The parent ODB Network segment is always derived from `id`.
* `purpose`: Required. `CLIENT_SUBNET` or `BACKUP_SUBNET`. VM Cluster subnet keys are validated against this value.

Output maps produced by `modules/odb-networking` also include informational fields (`name`, `odb_subnet_id`, `odb_network`, `cidr_range`, `location`, `project`, `state`) for debugging and downstream consumers. These are ignored by this module and need not be supplied when constructing the map manually.

`gcp_cloud_exadata_infrastructures_dependency` is a map keyed by logical name. Each value has these attributes:

* `id`: Required. Cloud Exadata Infrastructure full resource name in `projects/{project}/locations/{region}/cloudExadataInfrastructures/{cloud_exadata_infrastructure}` format.

### <a name="cloud-exadata-infrastructures">Cloud Exadata Infrastructures</a>

* `gcp_cloud_exadata_infrastructures_configuration`: Map of Cloud Exadata Infrastructures to create.

Each map value has these attributes:

* `cloud_exadata_infrastructure_id`: Required. The Cloud Exadata Infrastructure ID.
* `display_name`: Optional. Display name of the Exadata infrastructure. Defaults to `cloud_exadata_infrastructure_id` when omitted.
* `location`: Optional. The Google Cloud region. Overrides `default_location`. Must be `null` or non-empty with no whitespace.
* `project_id`: Optional. The Google Cloud project ID. Overrides `default_project_id`. Must be `null` or non-empty with no whitespace.
* `gcp_oracle_zone`: Optional. The GCP Oracle zone. Overrides `default_gcp_oracle_zone`. Must be `null` or non-empty.
* `labels`: Optional. Labels for the Exadata infrastructure. Keys and values must satisfy the module label validation.
* `deletion_protection`: Optional. Whether deletion protection is enabled. Overrides `default_deletion_protection`.
* `timeouts`: Optional. Provider timeout overrides for `create`, `update`, and `delete`.
* `properties`: Required. Exadata infrastructure properties.

The `properties` object has these attributes:

* `shape`: Required. Shape of the Exadata infrastructure. Must be non-empty.
* `compute_count`: Optional. Compute count of the Exadata infrastructure. Must be greater than 0 when set.
* `storage_count`: Optional. Storage count of the Exadata infrastructure. Must be greater than 0 when set.
* `total_storage_size_gb`: Optional. Total storage size in GB. Must be greater than 0 when set.
* `customer_contacts`: Optional. Customer contact information.
* `maintenance_window`: Optional. Maintenance window configuration.

If `maintenance_window` is not set, the module uses `default_cloud_exadata_maintenance_window` when provided.

Each `customer_contacts` object has these attributes:

* `email`: Required. Customer contact email address. Must be a valid email address.

The `maintenance_window` object has these attributes:

* `preference`: Optional. Maintenance window preference. Must be `MAINTENANCE_WINDOW_PREFERENCE_UNSPECIFIED`, `CUSTOM_PREFERENCE`, or `NO_PREFERENCE` when set.
* `months`: Optional. Maintenance months. Values must be `MONTH_UNSPECIFIED` or a month name from `JANUARY` through `DECEMBER`.
* `weeks_of_month`: Optional. Maintenance weeks of the month. Values must be 1, 2, 3, or 4.
* `days_of_week`: Optional. Maintenance days of the week. Values must be `DAY_OF_WEEK_UNSPECIFIED` or a day name from `MONDAY` through `SUNDAY`.
* `hours_of_day`: Optional. Maintenance hours of the day. Values must be 0, 4, 8, 12, 16, or 20.
* `lead_time_week`: Optional. Lead time in weeks. Must be from 1 through 4 when set.
* `patching_mode`: Optional. Patching mode. Must be `PATCHING_MODE_UNSPECIFIED`, `ROLLING`, or `NON_ROLLING` when set.
* `custom_action_timeout_mins`: Optional. Custom action timeout in minutes. Must be from 15 through 120 when set.
* `is_custom_action_timeout_enabled`: Optional. Whether custom action timeout is enabled.

The module intentionally ignores Terraform drift for selected Cloud Exadata Infrastructure capacity fields. These values can change after Oracle-managed maintenance or after operations performed through the OCI control plane in dual control-plane deployments. Ignoring them prevents a later Google provider plan from rolling back capacity or storage changes made outside this module.

This policy follows Oracle's published Terraform guidance for [modifying an Exadata Infrastructure](https://docs.oracle.com/en-us/iaas/Content/database-at-gcp/gcpmd-modify-exadata-infrastructure.html#terraform) in Oracle Database@Google Cloud.

Ignored Cloud Exadata Infrastructure fields:

* `properties[0].compute_count`
* `properties[0].storage_count`
* `properties[0].total_storage_size_gb`

The policy is deliberately limited to capacity and storage fields that are likely to drift when Google and OCI control planes are both used. Maintenance windows, customer contacts, labels, and computed-only version/status fields remain visible to Terraform.

Provider resource: `google_oracle_database_cloud_exadata_infrastructure`.

### <a name="cloud-vm-clusters">Cloud VM Clusters</a>

* `gcp_cloud_vm_clusters_configuration`: Map of Cloud VM Clusters to create.

Each map value has these attributes:

* `cloud_vm_cluster_id`: Required. The Cloud VM Cluster ID.
* `display_name`: Optional. Display name of the VM cluster. Defaults to `cloud_vm_cluster_id` when omitted.
* `location`: Optional. The Google Cloud region. Overrides `default_location`. Must be `null` or non-empty with no whitespace.
* `project_id`: Optional. The Google Cloud project ID. Overrides `default_project_id`. Must be `null` or non-empty with no whitespace.
* `labels`: Optional. Labels for the VM cluster. Keys and values must satisfy the module label validation.
* `deletion_protection`: Optional. Whether deletion protection is enabled. Overrides `default_deletion_protection`.
* `timeouts`: Optional. Provider timeout overrides for `create`, `update`, and `delete`.
* `exadata_infrastructure`: Required. Exadata infrastructure reference. Accepts either the full resource name in `projects/{project}/locations/{region}/cloudExadataInfrastructures/{cloud_exadata_infrastructure}` format or a key from `gcp_cloud_exadata_infrastructures_configuration` / `gcp_cloud_exadata_infrastructures_dependency`.
* `odb_network`: Required. ODB network reference. Accepts either the full resource name in `projects/{project}/locations/{location}/odbNetworks/{odb_network}` format or a key from `gcp_odb_networks_dependency`.
* `odb_subnet`: Required. Client ODB subnet reference. Accepts either the full resource name in `projects/{project}/locations/{location}/odbNetworks/{odb_network}/odbSubnets/{odb_subnet}` format or a key from `gcp_odb_subnets_dependency`.
* `backup_odb_subnet`: Required. Backup ODB subnet reference. Accepts either the full resource name in `projects/{project}/locations/{location}/odbNetworks/{odb_network}/odbSubnets/{odb_subnet}` format or a key from `gcp_odb_subnets_dependency`.
* `properties`: Required. VM cluster properties.

Each VM cluster must set one Exadata reference, one ODB network reference, one client ODB subnet reference, and one backup ODB subnet reference. Values that start with `projects/` must match the full resource-name shape and are passed directly; other values are resolved as keys. Bare cloud resource ID segments are not accepted as external resource references; a short value is valid only when it matches a local configuration key or dependency-map key. To reference external Exadata Infrastructure, ODB Network, or ODB Subnet resources that are not present in a dependency map, pass the full Google resource name. This module intentionally exposes only ODB subnet mode for new environments. Dependency subnet entries must include `purpose`; when using keys, `odb_subnet` must point to a subnet with purpose `CLIENT_SUBNET`, and `backup_odb_subnet` must point to a subnet with purpose `BACKUP_SUBNET`. Full ODB Subnet resource names are also checked against known purpose metadata when the same subnet `id` appears in `gcp_odb_subnets_dependency`; if no matching dependency metadata exists, Terraform cannot infer the purpose before apply. The VM Cluster, Exadata Infrastructure, and ODB Network references must resolve to the same Google Cloud location. When the parent ODB Network segment is known, both subnet references must belong to the selected ODB Network. The module does not require the selected ODB Network project to match the VM Cluster project. Provider fields `network`, `cidr`, and `backup_subnet_cidr` are intentionally unsupported in this module contract.

The module intentionally ignores Terraform drift for selected VM cluster fields that can change during Oracle-managed maintenance or during operations performed through the OCI control plane in dual control-plane deployments. This prevents a later Google provider plan from trying to roll back patch, shape, capacity, storage, backup, or database server placement changes made outside this module.

This policy follows Oracle's published Terraform guidance for [modifying an Exadata VM Cluster](https://docs.oracle.com/en-us/iaas/Content/database-at-gcp/gcpmd-modify-exadata-vm-cluster.html#terraform) in Oracle Database@Google Cloud.

Ignored VM cluster fields:

* `labels`
* `properties[0].gi_version`
* `properties[0].db_server_ocids`
* `properties[0].cpu_core_count`
* `properties[0].node_count`
* `properties[0].ocpu_count`
* `properties[0].memory_size_gb`
* `properties[0].db_node_storage_size_gb`
* `properties[0].data_storage_size_tb`
* `properties[0].local_backup_enabled`
* `properties[0].sparse_diskgroup_enabled`
* `properties[0].disk_redundancy`

The policy is deliberately limited to operational fields that are likely to drift when Google and OCI control planes are both used. VM Cluster labels are also ignored after creation because the current Google provider marks label changes as replacement. Treat VM Cluster labels as creation-time metadata. Computed-only system attributes such as `system_version`, `scan_listener_port_tcp`, and `scan_listener_port_tcp_ssl` are not ignored because they are not Terraform inputs.

The `properties` object has these attributes:

* `license_type`: Required. License type of the VM cluster. Must be `LICENSE_TYPE_UNSPECIFIED`, `LICENSE_INCLUDED`, or `BRING_YOUR_OWN_LICENSE`.
* `cpu_core_count`: Required. CPU core count of the VM cluster. Must be at least 4.
* `gi_version`: Required. Grid Infrastructure version. The Google provider schema marks this field optional, but the Oracle Database@Google Cloud API rejects VM Cluster creation when it is omitted.
* `ssh_public_keys`: Optional. RSA SSH public keys for the VM cluster in OpenSSH format, for example `ssh-rsa <base64> user@example.com`.
* `node_count`: Optional. Node count of the VM cluster. Must be at least 2 when set.
* `ocpu_count`: Optional. OCPU count of the VM cluster. Must be at least 0.1 when set.
* `memory_size_gb`: Optional. Memory size in GB. Must be at least 60 when set.
* `db_node_storage_size_gb`: Optional. DB node storage size in GB. Must be at least 120 when set.
* `data_storage_size_tb`: Optional. Data storage size in TB. Must be at least 2 when set.
* `disk_redundancy`: Optional. Disk redundancy setting. Must be `DISK_REDUNDANCY_UNSPECIFIED`, `HIGH`, or `NORMAL` when set.
* `sparse_diskgroup_enabled`: Optional. Whether sparse diskgroup is enabled.
* `local_backup_enabled`: Optional. Whether local backup is enabled.
* `hostname_prefix`: Optional. Hostname prefix. Must start with a letter, contain only letters, numbers, and hyphens, and be 1-12 characters long when set.
* `db_server_ocids`: Optional in the Google provider schema, but recommended for real VM Cluster creation. Database server OCIDs for explicit VM placement. Values must be complete DB server OCIDs in `ocid1.dbserver.<realm>.<region>.<id>` format, and the list must include at least one OCID per requested `node_count`. Leaving this unset is provider-schema-valid, but VM Cluster creation can fail at API time when the service cannot choose DB servers implicitly.
* `cluster_name`: Optional. Cluster name. Must start with a letter, contain only letters, numbers, and hyphens, and be 1-11 characters long when set.
* `time_zone`: Optional. Time zone configuration.
* `diagnostics_data_collection_options`: Optional. Diagnostics data collection options.

The `time_zone` object has these attributes:

* `id`: Optional. Time zone ID.
* `version`: Optional. Time zone version.

The `diagnostics_data_collection_options` object has these attributes:

* `diagnostics_events_enabled`: Optional. Whether diagnostic events collection is enabled.
* `health_monitoring_enabled`: Optional. Whether health monitoring is enabled.
* `incident_logs_enabled`: Optional. Whether incident log collection is enabled.

Provider resource: `google_oracle_database_cloud_vm_cluster`.

## <a name="module-outputs">Module Outputs</a>

The module returns these outputs:

* `module_name`: The module instance name.
* `gcp_cloud_exadata_infrastructures`: Created Exadata infrastructures, keyed by input key.
* `gcp_cloud_vm_clusters`: Created Exadata VM clusters, keyed by input key.

Each resource output includes stable identifiers and selected computed attributes exported by the Google provider. Exadata Infrastructure outputs include server versions and storage activation counts. VM Cluster outputs include Grid Infrastructure version, cluster identity, placement, capacity, SCAN details, backup and disk redundancy settings, OCI metadata, and lifecycle state.

If `enable_output` is `false`, `gcp_cloud_exadata_infrastructures` and `gcp_cloud_vm_clusters` return `null`; `module_name` remains available.
