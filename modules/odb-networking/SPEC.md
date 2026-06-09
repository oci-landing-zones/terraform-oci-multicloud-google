# Oracle Database@Google Cloud ODB Networking Module Specification

## Overview

This module creates ODB Networks and ODB Subnets for Oracle Database@Google Cloud. It is the shared producer module for ExaDB and ADB stacks that need ODB Network mode.

The module is intentionally narrow: it does not create Google Cloud VPC networks and it does not consume remote state or any transport-specific source. It creates resources from keyed maps and returns keyed dependency outputs. Logical keys are case-sensitive and must follow the OCI Landing Zones convention: uppercase semantic keys matching `^[A-Z][A-Z0-9_-]*$`, such as `PRIMARY`, `CLIENT`, `BACKUP`, or `CMP-1`, while Google resource ID segments remain lowercase provider IDs.

## Compatibility

This module requires Terraform `>= 1.4.0` and HashiCorp Google provider `>= 7.35.0, < 8.0.0`.

## Inputs

### General

* `module_name`: The module name. Defaults to `oracle-database-networking-at-gcp`.
* `enable_output`: Whether Terraform should enable module resource outputs. Defaults to `true`.
* `default_project_id`: Default Google Cloud project ID used when `project_id` is not set on a resource. If set, it must be non-empty and contain no whitespace.
* `default_location`: Default Google Cloud region used when `location` is not set on a resource. If set, it must be non-empty and contain no whitespace.
* `default_gcp_oracle_zone`: Default GCP Oracle zone used when `gcp_oracle_zone` is not set on an ODB Network. If set, it must be non-empty and contain no whitespace.
* `default_labels`: Default labels merged into all resources. Keys and values must follow Google Cloud label syntax: keys must start with a lowercase letter and contain lowercase letters, numbers, underscores, or hyphens; values may be empty and may contain lowercase letters, numbers, underscores, or hyphens.
* `default_deletion_protection`: Default deletion protection value. Defaults to `true`.
* `default_deletion_policy`: Default deletion policy for resources that support `deletion_policy`. Defaults to `PREVENT`. Must be `DELETE`, `PREVENT`, or `ABANDON`.

### ODB Networks

`gcp_odb_networks_configuration` is a map keyed by logical name. Each value has:

* `odb_network_id`: Required. ODB Network ID segment.
* `network`: Required. Existing Google Cloud VPC network resource name in `projects/{project}/global/networks/{network}` format. The VPC network segment must follow lowercase Google resource ID syntax.
* `location`: Optional. Overrides `default_location`. If set, it must be non-empty and contain no whitespace.
* `project_id`: Optional. Overrides `default_project_id`. If set, it must be non-empty and contain no whitespace.
* `gcp_oracle_zone`: Optional. Overrides `default_gcp_oracle_zone`. If set, it must be non-empty and contain no whitespace.
* `labels`: Optional. Resource labels. Keys and values must follow the same Google Cloud label syntax as `default_labels`.
* `deletion_protection`: Optional. Overrides `default_deletion_protection`.
* `deletion_policy`: Optional. Overrides `default_deletion_policy`. Must be `DELETE`, `PREVENT`, or `ABANDON`.
* `timeouts`: Optional provider timeout overrides.

Provider resource: `google_oracle_database_odb_network`.

### ODB Subnets

`gcp_odb_subnets_configuration` is a map keyed by logical name. Each value has:

* `odb_subnet_id`: Required. ODB Subnet ID segment.
* `cidr_range`: Required. Canonical RFC1918 private IPv4 CIDR range for the ODB Subnet; the address must be the network address for the prefix. Do not use Oracle-reserved `100.64.0.0/10` space.
* `purpose`: Required. `CLIENT_SUBNET` or `BACKUP_SUBNET`.
* `odb_network`: Required. Parent ODB Network reference. Accepts either a key from `gcp_odb_networks_configuration` or a full ODB Network resource name in `projects/{project}/locations/{location}/odbNetworks/{odb_network}` format. The module extracts the final ID segment before passing it to the Google provider.
* `location`: Optional. Overrides `default_location`. If set, it must be non-empty and contain no whitespace.
* `project_id`: Optional. Overrides `default_project_id`. If set, it must be non-empty and contain no whitespace.
* `labels`: Optional. Resource labels. Keys and values must follow the same Google Cloud label syntax as `default_labels`.
* `deletion_protection`: Optional. Overrides `default_deletion_protection`.
* `deletion_policy`: Optional. Overrides `default_deletion_policy`. Must be `DELETE`, `PREVENT`, or `ABANDON`.
* `timeouts`: Optional provider timeout overrides.

Provider resource: `google_oracle_database_odb_subnet`.

## Validations

* ODB Network and ODB Subnet IDs must follow Google resource ID syntax.
* ODB Network `network` values must use `projects/{project}/global/networks/{network}` format, with a lowercase Google VPC network ID segment.
* ODB Network `project_id` or `default_project_id`, when known, must match the project segment in the VPC `network` resource name.
* ODB Subnet CIDR ranges must be valid canonical RFC1918 private IPv4 CIDR blocks whose address is the network address. Oracle-reserved `100.64.0.0/10` space is rejected.
* ODB Subnet purpose must be `CLIENT_SUBNET` or `BACKUP_SUBNET`.
* Each ODB Subnet must set `odb_network` to either a key from `gcp_odb_networks_configuration` or a full ODB Network resource name.
* Bare external ODB Network ID segments are not accepted because they are ambiguous with local map keys.
* Logical map keys are case-sensitive and must match `^[A-Z][A-Z0-9_-]*$` so local references cannot be confused with lowercase Google resource ID segments.
* When `odb_network` is a key in `gcp_odb_networks_configuration`, the subnet must share the same location as that ODB Network and the same project when project values are explicitly known.
* When `odb_network` is a full ODB Network resource name, the resource name project and location must match the subnet project and location when those values are explicitly known.
* ODB Network resources may set `gcp_oracle_zone` or `default_gcp_oracle_zone`; when omitted, the Google provider/API selects the zone.
* Project, location, and GCP Oracle zone defaults and overrides can be omitted when another value supplies the setting, but cannot contain whitespace when set.
* `default_labels`, ODB Network `labels`, and ODB Subnet `labels` must use Google Cloud label-compatible syntax.
* ODB Network and ODB Subnet ID uniqueness is enforced by the Google provider/API at create time.

## Operational Drift Policy

The module intentionally ignores Terraform drift for ODB Network and ODB Subnet `labels`.

The policy is intentionally narrow. The current Google provider plans replacement for label-only changes on `google_oracle_database_odb_network` and `google_oracle_database_odb_subnet`. Labels are therefore treated as creation-time tracking metadata to avoid accidental replacement of networking resources. All other ODB Networking attributes remain visible to Terraform.

## Outputs

* `module_name`: The module instance name.
* `gcp_odb_networks`: Created ODB Networks, keyed by input key. Each value includes:
  * `id`: Full ODB Network resource name.
  * `name`: Provider name for the ODB Network.
  * `odb_network_id`: ODB Network ID segment.
  * `network`: Google Cloud VPC network resource name.
  * `location`: Google Cloud region.
  * `project`: Google Cloud project ID.
  * `gcp_oracle_zone`: GCP Oracle zone when returned by the provider.
  * `state`: Provider lifecycle state.
  * `entitlement_id`: Oracle Database@Google Cloud entitlement ID when returned by the provider.
* `gcp_odb_subnets`: Created ODB Subnets, keyed by input key. Each value includes:
  * `id`: Full ODB Subnet resource name.
  * `name`: Provider name for the ODB Subnet.
  * `odb_subnet_id`: ODB Subnet ID segment.
  * `odb_network`: Full parent ODB Network resource name.
  * `cidr_range`: ODB Subnet CIDR range.
  * `purpose`: `CLIENT_SUBNET` or `BACKUP_SUBNET`.
  * `location`: Google Cloud region.
  * `project`: Google Cloud project ID.
  * `state`: Provider lifecycle state.

If `enable_output` is `false`, Terraform resource outputs return `null`; `module_name` remains available.

The reusable module does not read remote state, object storage, or other transport-specific sources.
