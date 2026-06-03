# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

module "oracle_database_at_gcp" {
  source = "../.."

  module_name                 = var.module_name
  enable_output               = var.enable_output
  default_project_id          = var.project_id
  default_location            = var.location
  default_deletion_protection = var.default_deletion_protection
  default_labels              = var.default_labels
  ssh_public_keys_file_path   = var.ssh_public_keys_file_path

  gcp_cloud_exadata_infrastructures_configuration = {}

  gcp_odb_networks_dependency                  = var.gcp_odb_networks_dependency
  gcp_odb_subnets_dependency                   = var.gcp_odb_subnets_dependency
  gcp_cloud_exadata_infrastructures_dependency = var.gcp_cloud_exadata_infrastructures_dependency

  gcp_cloud_vm_clusters_configuration = var.gcp_cloud_vm_clusters_configuration
}
