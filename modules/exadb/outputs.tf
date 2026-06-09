# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "module_name" {
  description = "The module instance name."
  value       = var.module_name
}

output "gcp_cloud_exadata_infrastructures" {
  description = "Created Exadata infrastructures, keyed by input key."
  value       = var.enable_output ? local.gcp_cloud_exadata_infrastructures_output : null
}

output "gcp_cloud_vm_clusters" {
  description = "Created Exadata VM clusters, keyed by input key."
  value       = var.enable_output ? local.gcp_cloud_vm_clusters_output : null
}
