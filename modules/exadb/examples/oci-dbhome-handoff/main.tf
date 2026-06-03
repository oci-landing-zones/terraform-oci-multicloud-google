# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  oci_ocid_family_pattern              = "^ocid1[.]"
  cloud_vm_cluster_ocid_family_pattern = "^ocid1[.]cloudvmcluster[.]"
  cloud_vm_cluster_ocid_pattern        = "^ocid1[.]cloudvmcluster[.][^./[:space:]]+[.][^./[:space:]]+[.][^/[:space:]]+$"

  gcp_cloud_vm_clusters_dependency = {
    for key, cluster in var.gcp_cloud_vm_clusters_dependency : key => {
      id    = try(cluster.id, null)
      name  = try(cluster.name, null)
      ocid  = try(cluster.ocid, null)
      state = try(cluster.state, null)
    }
  }

  db_home_vm_cluster_raw_refs = {
    for key, db_home in coalesce(var.cloud_db_homes_configuration, {}) : key => (
      try(db_home.vm_cluster_id, null) == null ? "" : tostring(db_home.vm_cluster_id)
    )
  }

  db_home_vm_cluster_refs = {
    for key, vm_cluster_id in local.db_home_vm_cluster_raw_refs : key => vm_cluster_id
    if vm_cluster_id != ""
  }

  db_home_vm_cluster_dependency_keys = {
    for key, vm_cluster_id in local.db_home_vm_cluster_refs : key => vm_cluster_id
    if !can(regex(local.oci_ocid_family_pattern, vm_cluster_id))
  }

  db_home_vm_cluster_ids = {
    for key, vm_cluster_id in local.db_home_vm_cluster_refs : key => (
      can(regex(local.cloud_vm_cluster_ocid_pattern, vm_cluster_id))
      ? vm_cluster_id : (
        can(regex(local.oci_ocid_family_pattern, vm_cluster_id))
        ? null
        : try(local.gcp_cloud_vm_clusters_dependency[vm_cluster_id].ocid, null)
      )
    )
  }

  cloud_db_homes_configuration = {
    for key, db_home in coalesce(var.cloud_db_homes_configuration, {}) : key => merge(
      db_home,
      {
        vm_cluster_id = try(local.db_home_vm_cluster_ids[key], null)
      }
    )
  }
}

resource "terraform_data" "validate_handoff" {
  lifecycle {
    precondition {
      condition     = length(local.db_home_vm_cluster_refs) == length(keys(coalesce(var.cloud_db_homes_configuration, {})))
      error_message = "Each cloud_db_homes_configuration entry must set vm_cluster_id to either an OCI Cloud VM Cluster OCID or a key from gcp_cloud_vm_clusters_dependency."
    }

    precondition {
      condition = alltrue([
        for key, vm_cluster_id in local.db_home_vm_cluster_refs :
        trimspace(vm_cluster_id) != "" && !can(regex("[[:space:]]", vm_cluster_id))
      ])
      error_message = "Each cloud_db_homes_configuration vm_cluster_id must not be empty or contain whitespace."
    }

    precondition {
      condition = alltrue([
        for key, vm_cluster_id in local.db_home_vm_cluster_refs :
        !can(regex(local.oci_ocid_family_pattern, vm_cluster_id)) ||
        can(regex(local.cloud_vm_cluster_ocid_pattern, vm_cluster_id))
      ])
      error_message = "Direct OCI OCID values in cloud_db_homes_configuration vm_cluster_id must be OCI Cloud VM Cluster OCIDs using the ocid1.cloudvmcluster.{realm}.{region}.{id} format."
    }

    precondition {
      condition = alltrue([
        for key, vm_cluster_id in local.db_home_vm_cluster_dependency_keys :
        contains(keys(local.gcp_cloud_vm_clusters_dependency), vm_cluster_id)
      ])
      error_message = "Each cloud_db_homes_configuration vm_cluster_id that is not an OCI Cloud VM Cluster OCID must reference a key from gcp_cloud_vm_clusters_dependency."
    }

    precondition {
      condition = alltrue([
        for key, vm_cluster_id in local.db_home_vm_cluster_dependency_keys :
        try(local.gcp_cloud_vm_clusters_dependency[vm_cluster_id].ocid, null) != null &&
        can(regex(local.cloud_vm_cluster_ocid_pattern, tostring(local.gcp_cloud_vm_clusters_dependency[vm_cluster_id].ocid)))
      ])
      error_message = "Each referenced GCP VM Cluster dependency must include a non-null OCI Cloud VM Cluster OCID in the ocid field."
    }

    precondition {
      condition = alltrue([
        for key, vm_cluster_id in local.db_home_vm_cluster_dependency_keys :
        try(local.gcp_cloud_vm_clusters_dependency[vm_cluster_id].state, null) == "AVAILABLE"
      ])
      error_message = "Each referenced GCP VM Cluster dependency must be AVAILABLE before OCI DB Homes are created."
    }
  }
}

module "oci_exadata_database" {
  source = "git::https://github.com/oci-landing-zones/terraform-oci-modules-exadata.git//exadata-database?ref=v1.1.0"

  depends_on = [terraform_data.validate_handoff]

  default_defined_tags              = var.default_defined_tags
  default_freeform_tags             = var.default_freeform_tags
  cloud_db_homes_configuration      = local.cloud_db_homes_configuration
  databases_configuration           = var.databases_configuration
  pluggable_databases_configuration = var.pluggable_databases_configuration
}
