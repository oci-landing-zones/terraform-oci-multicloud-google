# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  gcp_cloud_exadata_infrastructures_output = {
    for key, infrastructure in google_oracle_database_cloud_exadata_infrastructure.these : key => {
      id                                 = infrastructure.id
      name                               = infrastructure.name
      cloud_exadata_infrastructure_id    = infrastructure.cloud_exadata_infrastructure_id
      location                           = infrastructure.location
      project                            = infrastructure.project
      entitlement_id                     = try(infrastructure.entitlement_id, null)
      ocid                               = try(infrastructure.properties[0].ocid, null)
      state                              = try(infrastructure.properties[0].state, null)
      shape                              = try(infrastructure.properties[0].shape, null)
      available_storage_size_gb          = try(infrastructure.properties[0].available_storage_size_gb, null)
      cpu_count                          = try(infrastructure.properties[0].cpu_count, null)
      max_cpu_count                      = try(infrastructure.properties[0].max_cpu_count, null)
      memory_size_gb                     = try(infrastructure.properties[0].memory_size_gb, null)
      max_memory_gb                      = try(infrastructure.properties[0].max_memory_gb, null)
      data_storage_size_tb               = try(infrastructure.properties[0].data_storage_size_tb, null)
      max_data_storage_tb                = try(infrastructure.properties[0].max_data_storage_tb, null)
      db_node_storage_size_gb            = try(infrastructure.properties[0].db_node_storage_size_gb, null)
      max_db_node_storage_size_gb        = try(infrastructure.properties[0].max_db_node_storage_size_gb, null)
      next_maintenance_run_id            = try(infrastructure.properties[0].next_maintenance_run_id, null)
      next_maintenance_run_time          = try(infrastructure.properties[0].next_maintenance_run_time, null)
      next_security_maintenance_run_time = try(infrastructure.properties[0].next_security_maintenance_run_time, null)
      db_server_version                  = try(infrastructure.properties[0].db_server_version, null)
      storage_server_version             = try(infrastructure.properties[0].storage_server_version, null)
      monthly_db_server_version          = try(infrastructure.properties[0].monthly_db_server_version, null)
      monthly_storage_server_version     = try(infrastructure.properties[0].monthly_storage_server_version, null)
      activated_storage_count            = try(infrastructure.properties[0].activated_storage_count, null)
      additional_storage_count           = try(infrastructure.properties[0].additional_storage_count, null)
      oci_url                            = try(infrastructure.properties[0].oci_url, null)
    }
  }
}

resource "google_oracle_database_cloud_exadata_infrastructure" "these" {
  for_each = var.gcp_cloud_exadata_infrastructures_configuration

  cloud_exadata_infrastructure_id = each.value.cloud_exadata_infrastructure_id
  display_name                    = each.value.display_name != null ? each.value.display_name : each.value.cloud_exadata_infrastructure_id
  location                        = each.value.location != null ? each.value.location : var.default_location
  project                         = each.value.project_id != null ? each.value.project_id : var.default_project_id
  gcp_oracle_zone                 = each.value.gcp_oracle_zone != null ? each.value.gcp_oracle_zone : var.default_gcp_oracle_zone
  labels                          = merge(local.module_tag, local.default_labels, each.value.labels)
  deletion_protection             = each.value.deletion_protection != null ? each.value.deletion_protection : var.default_deletion_protection

  properties {
    shape                 = each.value.properties.shape
    compute_count         = each.value.properties.compute_count
    storage_count         = each.value.properties.storage_count
    total_storage_size_gb = each.value.properties.total_storage_size_gb

    dynamic "customer_contacts" {
      for_each = each.value.properties.customer_contacts == null ? [] : each.value.properties.customer_contacts

      content {
        email = customer_contacts.value.email
      }
    }

    dynamic "maintenance_window" {
      for_each = (
        each.value.properties.maintenance_window != null || var.default_cloud_exadata_maintenance_window != null
      ) ? [1] : []

      content {
        preference                       = try(each.value.properties.maintenance_window.preference, null) != null ? each.value.properties.maintenance_window.preference : try(var.default_cloud_exadata_maintenance_window.preference, null)
        months                           = try(each.value.properties.maintenance_window.months, null) != null ? each.value.properties.maintenance_window.months : try(var.default_cloud_exadata_maintenance_window.months, null)
        weeks_of_month                   = try(each.value.properties.maintenance_window.weeks_of_month, null) != null ? each.value.properties.maintenance_window.weeks_of_month : try(var.default_cloud_exadata_maintenance_window.weeks_of_month, null)
        days_of_week                     = try(each.value.properties.maintenance_window.days_of_week, null) != null ? each.value.properties.maintenance_window.days_of_week : try(var.default_cloud_exadata_maintenance_window.days_of_week, null)
        hours_of_day                     = try(each.value.properties.maintenance_window.hours_of_day, null) != null ? each.value.properties.maintenance_window.hours_of_day : try(var.default_cloud_exadata_maintenance_window.hours_of_day, null)
        lead_time_week                   = try(each.value.properties.maintenance_window.lead_time_week, null) != null ? each.value.properties.maintenance_window.lead_time_week : try(var.default_cloud_exadata_maintenance_window.lead_time_week, null)
        patching_mode                    = try(each.value.properties.maintenance_window.patching_mode, null) != null ? each.value.properties.maintenance_window.patching_mode : try(var.default_cloud_exadata_maintenance_window.patching_mode, null)
        custom_action_timeout_mins       = try(each.value.properties.maintenance_window.custom_action_timeout_mins, null) != null ? each.value.properties.maintenance_window.custom_action_timeout_mins : try(var.default_cloud_exadata_maintenance_window.custom_action_timeout_mins, null)
        is_custom_action_timeout_enabled = try(each.value.properties.maintenance_window.is_custom_action_timeout_enabled, null) != null ? each.value.properties.maintenance_window.is_custom_action_timeout_enabled : try(var.default_cloud_exadata_maintenance_window.is_custom_action_timeout_enabled, null)
      }
    }
  }

  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]

    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    ignore_changes = [
      properties[0].compute_count,
      properties[0].storage_count,
      properties[0].total_storage_size_gb,
    ]

    precondition {
      condition     = each.value.location != null || var.default_location != null
      error_message = "Each Cloud Exadata Infrastructure must set location or default_location."
    }
  }
}
