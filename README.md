# Oracle Database@Google Cloud Terraform Modules

![Oracle Database@Google Cloud](./images/landing_zone_300.png)

This repository provides Terraform modules for Oracle Database@Google Cloud resources managed through the HashiCorp Google provider.

## Modules

* [modules/odb-networking](./modules/odb-networking/README.md) — ODB Networks and ODB Subnets on top of an existing Google Cloud VPC.
* [modules/exadb](./modules/exadb/README.md) — Cloud Exadata Infrastructure and Cloud VM Clusters in ODB Network mode.
* [modules/adb](./modules/adb/README.md) — Oracle Autonomous Databases in ODB Network mode.

The modules follow the OCI Landing Zones style. Resources are declared through keyed maps, created with `for_each`, and returned with the same keys in the outputs. ODB Network dependency outputs produced by `modules/odb-networking` can be consumed directly by the ExaDB and ADB modules through the dependency injection pattern.

For the recommended Day-1 and Day-2 control plane model, see [Oracle Database@Google Cloud Operations Best Practices](https://github.com/oracle-devrel/technology-engineering/blob/main/operations-advisory/customer-operations/oracle-database/Oracle%20Database%20%40%20Google%20Cloud%20Operations/Oracle%20Database%20%40%20Google%20Operations%20Best%20Practices/README.md).

## Requirements

* Terraform `>= 1.4.0`
* HashiCorp Google provider `>= 7.13.0, < 8.0.0`
* Google provider authentication configured for the Terraform caller; Application Default Credentials via `gcloud auth application-default login` is one supported option
* OCI provider authentication configured when using the OCI DB Home handoff wrapper or operating through the OCI control plane
* A Google Cloud project enabled for Oracle Database@Google Cloud with the required entitlement and regional capacity

The OCI DB Home handoff wrapper under `modules/exadb/examples/oci-dbhome-handoff` inherits the upstream OCI Exadata module's Terraform requirement of `>= 1.5.0`.

## Getting Started

For ODB networking, start with [modules/odb-networking/examples/basic](./modules/odb-networking/examples/basic). It creates an ODB Network and client/backup ODB Subnets on an existing Google Cloud VPC.

For Cloud Exadata Infrastructure and VM Cluster deployments, start with [modules/exadb/examples/vision](./modules/exadb/examples/vision). It composes `modules/odb-networking` and `modules/exadb` to create the ODB networking layer, a Cloud Exadata Infrastructure, and a Cloud VM Cluster end to end.

For Exadata DB Homes, Container Databases, and Pluggable Databases, use the OCI Landing Zones Exadata module [`terraform-oci-modules-exadata//exadata-database`](https://github.com/oci-landing-zones/terraform-oci-modules-exadata/tree/v1.1.0/exadata-database). The Google Cloud modules stop at the Cloud VM Cluster boundary and expose the OCI Cloud VM Cluster OCID in `gcp_cloud_vm_clusters`; [modules/exadb/examples/oci-dbhome-handoff](./modules/exadb/examples/oci-dbhome-handoff) shows how to pass that output into the OCI module pinned at `v1.1.0`.

For Autonomous Database deployments, start with [modules/adb/examples/vision](./modules/adb/examples/vision). It composes `modules/odb-networking` and `modules/adb` to create the ODB networking layer and a single Autonomous Database end to end.

Each example includes an `input.auto.tfvars.template` file. Copy it to `<project-name>.auto.tfvars` and Terraform will load it automatically.

## Help

Open an [issue](https://github.com/oci-landing-zones/terraform-oci-multicloud-google/issues) for bugs or enhancement requests.

## Contributing

Before submitting a pull request, review the [contribution guide](./CONTRIBUTING.md).

## Security

Do not open GitHub issues for security vulnerabilities. Follow the [security vulnerability reporting process](./SECURITY.md).

## License

Copyright (c) 2026, Oracle and/or its affiliates.

Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
