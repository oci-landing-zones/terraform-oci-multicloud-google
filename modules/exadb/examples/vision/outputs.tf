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

output "gcp_cloud_exadata_infrastructures" {
  description = "Created Cloud Exadata Infrastructure resources, keyed by input key."
  value       = module.oracle_database_at_gcp.gcp_cloud_exadata_infrastructures
}

output "gcp_cloud_vm_clusters" {
  description = "Created Cloud VM Cluster resources, keyed by input key."
  value       = module.oracle_database_at_gcp.gcp_cloud_vm_clusters
}
