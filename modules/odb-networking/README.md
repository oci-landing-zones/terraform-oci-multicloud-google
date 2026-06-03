# Oracle Database@Google Cloud ODB Networking Terraform Module

## Overview

This module creates the Oracle Database@Google Cloud networking layer on top of an existing Google Cloud VPC:

* ODB Networks
* ODB Subnets

It follows the OCI Landing Zones style: resources are declared through keyed maps, created with `for_each`, and returned with the same keys in the outputs. Logical keys must use uppercase semantic identifiers matching `^[A-Z][A-Z0-9_-]*$`, such as `PRIMARY`, `CLIENT`, `BACKUP`, or `CMP-1`; keep Google resource ID segments in the lowercase provider syntax. The outputs can be passed directly into `modules/exadb` and `modules/adb` as dependency maps.

The module does not create Google Cloud VPC networks. VPCs are expected to be provided by the platform foundation or Google Cloud landing zone, commonly through Shared VPC or another centrally governed networking stack.

Use [SPEC.md](./SPEC.md) for the exact input and output contract.

## Requirements

* Terraform `>= 1.4.0`
* HashiCorp Google provider `>= 7.13.0, < 8.0.0`
* A Google Cloud project enabled for Oracle Database@Google Cloud
* An existing Google Cloud VPC network
* Oracle Database@Google Cloud entitlement and regional capacity

## Usage

```hcl
module "odb_networking" {
  source = "./modules/odb-networking"

  default_project_id      = "my-project"
  default_location        = "us-east4"
  default_gcp_oracle_zone = "us-east4-b-r2"

  gcp_odb_networks_configuration = {
    PRIMARY = {
      odb_network_id = "prod-odb-network"
      network        = "projects/my-project/global/networks/prod-vpc"
    }
  }

  gcp_odb_subnets_configuration = {
    CLIENT = {
      odb_subnet_id = "prod-client"
      odb_network   = "PRIMARY"
      cidr_range    = "192.168.1.0/24"
      purpose       = "CLIENT_SUBNET"
    }
    BACKUP = {
      odb_subnet_id = "prod-backup"
      odb_network   = "PRIMARY"
      cidr_range    = "192.168.2.0/28"
      purpose       = "BACKUP_SUBNET"
    }
  }
}
```

Downstream modules should consume `module.odb_networking.gcp_odb_networks` and `module.odb_networking.gcp_odb_subnets` directly when they are composed in the same root module.

Each subnet `odb_network` must be either a local ODB Network key or a full ODB Network resource name. Bare external ODB Network ID segments are rejected because they are ambiguous with local keys. Logical keys are case-sensitive and must be uppercase to keep local references distinct from lowercase Google resource ID segments.

The module validates provider-sensitive inputs at plan time: project, location, and GCP Oracle zone defaults cannot contain whitespace; labels must use Google Cloud label-compatible syntax; VPC network ID segments must use lowercase Google resource ID syntax; and subnet CIDRs must be canonical network blocks. Duplicate resource IDs are left to the Google provider/API, matching the OCI module style.

## Output Controls

The reusable module emits Terraform outputs. The recommended handoff path is direct dependency maps from Terraform outputs, Terragrunt dependency blocks, `terraform_remote_state`, HCP Terraform workspace outputs, CI/CD variables, or an orchestration layer.

Use `enable_output = false` only when a caller intentionally wants `gcp_odb_networks` and `gcp_odb_subnets` to return `null`; `module_name` remains available.

## Operational Drift Policy

ODB Network and ODB Subnet labels are treated as creation-time tracking metadata. The current Google provider plans replacement for label-only changes on these resources, so the module ignores `labels` drift to avoid accidental replacement of networking resources. All other ODB Networking attributes remain visible to Terraform.

## Examples

* [examples/basic](./examples/basic): creates an ODB Network and client/backup ODB Subnets on an existing VPC.

## Outputs

* `gcp_odb_networks`
* `gcp_odb_subnets`
* `module_name`

Both outputs are keyed by the same logical keys used in the input maps.

When `enable_output` is `false`, both resource outputs are `null`; `module_name` remains available.

## License

Copyright (c) 2026, Oracle and/or its affiliates.

Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
