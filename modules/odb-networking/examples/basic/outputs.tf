# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "gcp_odb_networks" {
  description = "Created ODB Network resources, keyed by input key."
  value       = module.odb_networking.gcp_odb_networks
}

output "gcp_odb_subnets" {
  description = "Created ODB Subnet resources, keyed by input key."
  value       = module.odb_networking.gcp_odb_subnets
}

output "module_name" {
  description = "The module instance name."
  value       = module.odb_networking.module_name
}
