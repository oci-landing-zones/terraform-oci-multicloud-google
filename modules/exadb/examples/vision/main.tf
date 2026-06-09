# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

module "odb_networking" {
  # Local source for repository examples. In production wrappers, replace with a pinned Git or registry source.
  source = "../../../odb-networking"

  module_name                 = var.odb_networking_module_name
  enable_output               = true
  default_project_id          = var.project_id
  default_location            = var.location
  default_gcp_oracle_zone     = var.gcp_oracle_zone
  default_deletion_protection = var.default_deletion_protection
  default_labels              = var.default_labels

  gcp_odb_networks_configuration = var.gcp_odb_networks_configuration
  gcp_odb_subnets_configuration  = var.gcp_odb_subnets_configuration
}

module "oracle_database_at_gcp" {
  source = "../.."

  module_name                 = var.exadb_module_name
  enable_output               = var.exadb_enable_output
  default_project_id          = var.project_id
  default_location            = var.location
  default_gcp_oracle_zone     = var.gcp_oracle_zone
  default_deletion_protection = var.default_deletion_protection
  default_labels              = var.default_labels
  ssh_public_keys_file_path   = var.ssh_public_keys_file_path

  default_cloud_exadata_maintenance_window = var.default_cloud_exadata_maintenance_window

  gcp_odb_networks_dependency                     = module.odb_networking.gcp_odb_networks
  gcp_odb_subnets_dependency                      = module.odb_networking.gcp_odb_subnets
  gcp_cloud_exadata_infrastructures_configuration = var.gcp_cloud_exadata_infrastructures_configuration
  gcp_cloud_vm_clusters_configuration             = var.gcp_cloud_vm_clusters_configuration
}
