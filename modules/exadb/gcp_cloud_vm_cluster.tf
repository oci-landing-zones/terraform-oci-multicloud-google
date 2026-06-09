# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  gcp_resource_id_segment_pattern                    = "[a-z]([a-z0-9-]{0,61}[a-z0-9])?"
  cloud_exadata_infrastructure_resource_name_pattern = "^projects/[^/[:space:]]+/locations/[^/[:space:]]+/cloudExadataInfrastructures/${local.gcp_resource_id_segment_pattern}$"
  odb_network_resource_name_pattern                  = "^projects/[^/[:space:]]+/locations/[^/[:space:]]+/odbNetworks/${local.gcp_resource_id_segment_pattern}$"
  odb_subnet_resource_name_pattern                   = "^projects/[^/[:space:]]+/locations/[^/[:space:]]+/odbNetworks/${local.gcp_resource_id_segment_pattern}/odbSubnets/${local.gcp_resource_id_segment_pattern}$"

  ssh_public_keys_from_file = var.ssh_public_keys_file_path != null ? [
    for key in split("\n", trimspace(file(var.ssh_public_keys_file_path))) :
    trimspace(key) if trimspace(key) != ""
  ] : null

  cloud_vm_cluster_exadata_infrastructures = {
    for key, cluster in var.gcp_cloud_vm_clusters_configuration : key =>
    can(regex(local.cloud_exadata_infrastructure_resource_name_pattern, cluster.exadata_infrastructure)) ? cluster.exadata_infrastructure : (
      contains(keys(var.gcp_cloud_exadata_infrastructures_configuration), cluster.exadata_infrastructure) ? google_oracle_database_cloud_exadata_infrastructure.these[cluster.exadata_infrastructure].id : try(local.gcp_cloud_exadata_infrastructures_dependency[cluster.exadata_infrastructure].id, null)
    )
  }

  cloud_vm_cluster_odb_networks = {
    for key, cluster in var.gcp_cloud_vm_clusters_configuration : key =>
    can(regex(local.odb_network_resource_name_pattern, cluster.odb_network)) ? cluster.odb_network : try(local.gcp_odb_networks_dependency[cluster.odb_network].id, null)
  }

  cloud_vm_cluster_odb_subnets = {
    for key, cluster in var.gcp_cloud_vm_clusters_configuration : key =>
    can(regex(local.odb_subnet_resource_name_pattern, cluster.odb_subnet)) ? cluster.odb_subnet : try(local.gcp_odb_subnets_dependency[cluster.odb_subnet].id, null)
  }

  cloud_vm_cluster_backup_odb_subnets = {
    for key, cluster in var.gcp_cloud_vm_clusters_configuration : key =>
    can(regex(local.odb_subnet_resource_name_pattern, cluster.backup_odb_subnet)) ? cluster.backup_odb_subnet : try(local.gcp_odb_subnets_dependency[cluster.backup_odb_subnet].id, null)
  }

  cloud_vm_cluster_locations = {
    for key, cluster in var.gcp_cloud_vm_clusters_configuration : key =>
    cluster.location != null ? cluster.location : var.default_location
  }

  cloud_vm_cluster_exadata_infrastructure_locations = {
    for key, cluster in var.gcp_cloud_vm_clusters_configuration : key =>
    cluster.exadata_infrastructure == null ? null : (
      can(regex(local.cloud_exadata_infrastructure_resource_name_pattern, cluster.exadata_infrastructure)) ? try(split("/", cluster.exadata_infrastructure)[3], null) : (
        contains(keys(var.gcp_cloud_exadata_infrastructures_configuration), cluster.exadata_infrastructure) ? (
          var.gcp_cloud_exadata_infrastructures_configuration[cluster.exadata_infrastructure].location != null ? var.gcp_cloud_exadata_infrastructures_configuration[cluster.exadata_infrastructure].location : var.default_location
        ) : try(split("/", local.gcp_cloud_exadata_infrastructures_dependency[cluster.exadata_infrastructure].id)[3], null)
      )
    )
  }

  cloud_vm_cluster_exadata_infrastructure_zones = {
    for key, cluster in var.gcp_cloud_vm_clusters_configuration : key =>
    cluster.exadata_infrastructure == null ? null : (
      can(regex(local.cloud_exadata_infrastructure_resource_name_pattern, cluster.exadata_infrastructure)) ? null : (
        contains(keys(var.gcp_cloud_exadata_infrastructures_configuration), cluster.exadata_infrastructure) ? (
          var.gcp_cloud_exadata_infrastructures_configuration[cluster.exadata_infrastructure].gcp_oracle_zone != null ? var.gcp_cloud_exadata_infrastructures_configuration[cluster.exadata_infrastructure].gcp_oracle_zone : var.default_gcp_oracle_zone
        ) : try(local.gcp_cloud_exadata_infrastructures_dependency[cluster.exadata_infrastructure].gcp_oracle_zone, null)
      )
    )
  }

  cloud_vm_cluster_odb_network_zones = {
    for key, cluster in var.gcp_cloud_vm_clusters_configuration : key =>
    cluster.odb_network == null ? null : (
      can(regex(local.odb_network_resource_name_pattern, cluster.odb_network)) ? null : try(local.gcp_odb_networks_dependency[cluster.odb_network].gcp_oracle_zone, null)
    )
  }

  odb_subnet_dependency_ids_with_purpose = distinct([
    for subnet in values(local.gcp_odb_subnets_dependency) : subnet.id
    if try(subnet.id, null) != null && try(subnet.purpose, null) != null
  ])

  odb_subnet_dependency_purposes_by_id = {
    for subnet_id in local.odb_subnet_dependency_ids_with_purpose : subnet_id => distinct([
      for subnet in values(local.gcp_odb_subnets_dependency) : subnet.purpose
      if try(subnet.id, null) == subnet_id && try(subnet.purpose, null) != null
    ])
  }

  cloud_vm_cluster_client_odb_subnet_purposes = {
    for key, cluster in var.gcp_cloud_vm_clusters_configuration : key =>
    can(regex(local.odb_subnet_resource_name_pattern, cluster.odb_subnet)) ? try(local.odb_subnet_dependency_purposes_by_id[cluster.odb_subnet], []) : (try(local.gcp_odb_subnets_dependency[cluster.odb_subnet].purpose, null) == null ? [] : [local.gcp_odb_subnets_dependency[cluster.odb_subnet].purpose])
  }

  cloud_vm_cluster_backup_odb_subnet_purposes = {
    for key, cluster in var.gcp_cloud_vm_clusters_configuration : key =>
    can(regex(local.odb_subnet_resource_name_pattern, cluster.backup_odb_subnet)) ? try(local.odb_subnet_dependency_purposes_by_id[cluster.backup_odb_subnet], []) : (try(local.gcp_odb_subnets_dependency[cluster.backup_odb_subnet].purpose, null) == null ? [] : [local.gcp_odb_subnets_dependency[cluster.backup_odb_subnet].purpose])
  }

  cloud_vm_cluster_selected_odb_network_segments = {
    for key, odb_network in local.cloud_vm_cluster_odb_networks : key => (
      odb_network == null ? null : {
        project  = try(split("/", odb_network)[1], null)
        location = try(split("/", odb_network)[3], null)
        segment  = try(split("/", odb_network)[5], null)
      }
    )
  }

  cloud_vm_cluster_client_subnet_parent_segments = {
    for key, odb_subnet in local.cloud_vm_cluster_odb_subnets : key => (
      odb_subnet == null ? null : {
        project  = try(split("/", odb_subnet)[1], null)
        location = try(split("/", odb_subnet)[3], null)
        segment  = try(split("/", odb_subnet)[5], null)
      }
    )
  }

  cloud_vm_cluster_backup_subnet_parent_segments = {
    for key, backup_odb_subnet in local.cloud_vm_cluster_backup_odb_subnets : key => (
      backup_odb_subnet == null ? null : {
        project  = try(split("/", backup_odb_subnet)[1], null)
        location = try(split("/", backup_odb_subnet)[3], null)
        segment  = try(split("/", backup_odb_subnet)[5], null)
      }
    )
  }

  gcp_cloud_vm_clusters_configuration_with_ssh_keys = (
    var.ssh_public_keys_file_path != null ? {
      for key, cluster in var.gcp_cloud_vm_clusters_configuration : key => merge(
        cluster,
        {
          properties = merge(
            cluster.properties,
            {
              ssh_public_keys = local.ssh_public_keys_from_file
            }
          )
        }
      )
    } : var.gcp_cloud_vm_clusters_configuration
  )

  gcp_cloud_vm_clusters_output = {
    for key, cluster in google_oracle_database_cloud_vm_cluster.these : key => {
      id                         = cluster.id
      name                       = cluster.name
      cloud_vm_cluster_id        = cluster.cloud_vm_cluster_id
      location                   = cluster.location
      project                    = cluster.project
      gcp_oracle_zone            = cluster.gcp_oracle_zone
      exadata_infrastructure     = cluster.exadata_infrastructure
      odb_network                = cluster.odb_network
      odb_subnet                 = cluster.odb_subnet
      backup_odb_subnet          = cluster.backup_odb_subnet
      ocid                       = try(cluster.properties[0].ocid, null)
      state                      = try(cluster.properties[0].state, null)
      shape                      = try(cluster.properties[0].shape, null)
      gi_version                 = try(cluster.properties[0].gi_version, null)
      cluster_name               = try(cluster.properties[0].cluster_name, null)
      hostname                   = try(cluster.properties[0].hostname, null)
      hostname_prefix            = try(cluster.properties[0].hostname_prefix, null)
      domain                     = try(cluster.properties[0].domain, null)
      scan_dns                   = try(cluster.properties[0].scan_dns, null)
      scan_ip_ids                = try(cluster.properties[0].scan_ip_ids, null)
      scan_listener_port_tcp     = try(cluster.properties[0].scan_listener_port_tcp, null)
      scan_listener_port_tcp_ssl = try(cluster.properties[0].scan_listener_port_tcp_ssl, null)
      scan_dns_record_id         = try(cluster.properties[0].scan_dns_record_id, null)
      dns_listener_ip            = try(cluster.properties[0].dns_listener_ip, null)
      system_version             = try(cluster.properties[0].system_version, null)
      license_type               = try(cluster.properties[0].license_type, null)
      cpu_core_count             = try(cluster.properties[0].cpu_core_count, null)
      ocpu_count                 = try(cluster.properties[0].ocpu_count, null)
      node_count                 = try(cluster.properties[0].node_count, null)
      memory_size_gb             = try(cluster.properties[0].memory_size_gb, null)
      db_node_storage_size_gb    = try(cluster.properties[0].db_node_storage_size_gb, null)
      data_storage_size_tb       = try(cluster.properties[0].data_storage_size_tb, null)
      storage_size_gb            = try(cluster.properties[0].storage_size_gb, null)
      db_server_ocids            = try(cluster.properties[0].db_server_ocids, null)
      disk_redundancy            = try(cluster.properties[0].disk_redundancy, null)
      local_backup_enabled       = try(cluster.properties[0].local_backup_enabled, null)
      sparse_diskgroup_enabled   = try(cluster.properties[0].sparse_diskgroup_enabled, null)
      compartment_id             = try(cluster.properties[0].compartment_id, null)
      oci_url                    = try(cluster.properties[0].oci_url, null)
    }
  }
}

resource "google_oracle_database_cloud_vm_cluster" "these" {
  for_each = local.gcp_cloud_vm_clusters_configuration_with_ssh_keys

  cloud_vm_cluster_id = each.value.cloud_vm_cluster_id
  display_name        = each.value.display_name != null ? each.value.display_name : each.value.cloud_vm_cluster_id
  location            = each.value.location != null ? each.value.location : var.default_location
  project             = each.value.project_id != null ? each.value.project_id : var.default_project_id

  exadata_infrastructure = local.cloud_vm_cluster_exadata_infrastructures[each.key]

  odb_network       = local.cloud_vm_cluster_odb_networks[each.key]
  odb_subnet        = local.cloud_vm_cluster_odb_subnets[each.key]
  backup_odb_subnet = local.cloud_vm_cluster_backup_odb_subnets[each.key]

  labels              = merge(local.module_tag, local.default_labels, each.value.labels)
  deletion_protection = each.value.deletion_protection != null ? each.value.deletion_protection : var.default_deletion_protection
  deletion_policy     = each.value.deletion_policy != null ? each.value.deletion_policy : var.default_deletion_policy

  properties {
    license_type             = each.value.properties.license_type
    gi_version               = each.value.properties.gi_version
    ssh_public_keys          = each.value.properties.ssh_public_keys
    node_count               = each.value.properties.node_count
    ocpu_count               = each.value.properties.ocpu_count
    memory_size_gb           = each.value.properties.memory_size_gb
    db_node_storage_size_gb  = each.value.properties.db_node_storage_size_gb
    data_storage_size_tb     = each.value.properties.data_storage_size_tb
    disk_redundancy          = each.value.properties.disk_redundancy
    sparse_diskgroup_enabled = each.value.properties.sparse_diskgroup_enabled
    local_backup_enabled     = each.value.properties.local_backup_enabled
    hostname_prefix          = each.value.properties.hostname_prefix
    cpu_core_count           = each.value.properties.cpu_core_count
    db_server_ocids          = each.value.properties.db_server_ocids
    cluster_name             = each.value.properties.cluster_name

    dynamic "time_zone" {
      for_each = each.value.properties.time_zone == null ? [] : [each.value.properties.time_zone]

      content {
        id      = time_zone.value.id
        version = time_zone.value.version
      }
    }

    dynamic "diagnostics_data_collection_options" {
      for_each = each.value.properties.diagnostics_data_collection_options == null ? [] : [each.value.properties.diagnostics_data_collection_options]

      content {
        diagnostics_events_enabled = diagnostics_data_collection_options.value.diagnostics_events_enabled
        health_monitoring_enabled  = diagnostics_data_collection_options.value.health_monitoring_enabled
        incident_logs_enabled      = diagnostics_data_collection_options.value.incident_logs_enabled
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
      labels,
      properties[0].cpu_core_count,
      properties[0].data_storage_size_tb,
      properties[0].db_node_storage_size_gb,
      properties[0].db_server_ocids,
      properties[0].disk_redundancy,
      properties[0].gi_version,
      properties[0].local_backup_enabled,
      properties[0].memory_size_gb,
      properties[0].node_count,
      properties[0].ocpu_count,
      properties[0].sparse_diskgroup_enabled,
    ]

    precondition {
      condition     = each.value.location != null || var.default_location != null
      error_message = "Each Cloud VM cluster must set location or default_location."
    }

    precondition {
      condition = can(regex(local.cloud_exadata_infrastructure_resource_name_pattern, each.value.exadata_infrastructure)) ? true : (
        (contains(keys(var.gcp_cloud_exadata_infrastructures_configuration), each.value.exadata_infrastructure) ? 1 : 0) +
        (contains(keys(local.gcp_cloud_exadata_infrastructures_dependency), each.value.exadata_infrastructure) ? 1 : 0) == 1
      )
      error_message = "Each Cloud VM cluster exadata_infrastructure must be a full resource name or reference exactly one key from gcp_cloud_exadata_infrastructures_configuration or gcp_cloud_exadata_infrastructures_dependency."
    }

    precondition {
      condition     = local.cloud_vm_cluster_odb_networks[each.key] != null
      error_message = "Each Cloud VM cluster odb_network must be a full ODB Network resource name or a key from gcp_odb_networks_dependency."
    }

    precondition {
      condition     = local.cloud_vm_cluster_odb_subnets[each.key] != null
      error_message = "Each Cloud VM cluster odb_subnet must be a full ODB Subnet resource name or a key from gcp_odb_subnets_dependency."
    }

    precondition {
      condition     = local.cloud_vm_cluster_backup_odb_subnets[each.key] != null
      error_message = "Each Cloud VM cluster backup_odb_subnet must be a full ODB Subnet resource name or a key from gcp_odb_subnets_dependency."
    }

    precondition {
      condition = (
        local.cloud_vm_cluster_locations[each.key] == null ||
        local.cloud_vm_cluster_exadata_infrastructure_locations[each.key] == null ||
        local.cloud_vm_cluster_locations[each.key] == local.cloud_vm_cluster_exadata_infrastructure_locations[each.key]
      )
      error_message = "Each Cloud VM cluster must be in the same location as the selected Exadata Infrastructure."
    }

    precondition {
      condition = (
        local.cloud_vm_cluster_exadata_infrastructure_zones[each.key] == null ||
        local.cloud_vm_cluster_odb_network_zones[each.key] == null ||
        local.cloud_vm_cluster_exadata_infrastructure_zones[each.key] == local.cloud_vm_cluster_odb_network_zones[each.key]
      )
      error_message = "Each Cloud VM cluster must use an Exadata Infrastructure and ODB network in the same GCP Oracle zone when both zones are known."
    }

    precondition {
      condition = (
        local.cloud_vm_cluster_locations[each.key] == null ||
        local.cloud_vm_cluster_selected_odb_network_segments[each.key] == null ||
        local.cloud_vm_cluster_selected_odb_network_segments[each.key].location == null ||
        local.cloud_vm_cluster_locations[each.key] == local.cloud_vm_cluster_selected_odb_network_segments[each.key].location
      )
      error_message = "Each Cloud VM cluster must be in the same location as the selected ODB network."
    }

    precondition {
      condition = (
        local.cloud_vm_cluster_selected_odb_network_segments[each.key] == null ||
        local.cloud_vm_cluster_client_subnet_parent_segments[each.key] == null ||
        (
          local.cloud_vm_cluster_selected_odb_network_segments[each.key].segment != null &&
          local.cloud_vm_cluster_client_subnet_parent_segments[each.key].segment != null &&
          local.cloud_vm_cluster_selected_odb_network_segments[each.key].project == local.cloud_vm_cluster_client_subnet_parent_segments[each.key].project &&
          local.cloud_vm_cluster_selected_odb_network_segments[each.key].location == local.cloud_vm_cluster_client_subnet_parent_segments[each.key].location &&
          local.cloud_vm_cluster_selected_odb_network_segments[each.key].segment == local.cloud_vm_cluster_client_subnet_parent_segments[each.key].segment
        )
      )
      error_message = "Each Cloud VM cluster client ODB subnet must resolve to a non-null parent ODB network and belong to the selected ODB network, including project and location."
    }

    precondition {
      condition = (
        local.cloud_vm_cluster_selected_odb_network_segments[each.key] == null ||
        local.cloud_vm_cluster_backup_subnet_parent_segments[each.key] == null ||
        (
          local.cloud_vm_cluster_selected_odb_network_segments[each.key].segment != null &&
          local.cloud_vm_cluster_backup_subnet_parent_segments[each.key].segment != null &&
          local.cloud_vm_cluster_selected_odb_network_segments[each.key].project == local.cloud_vm_cluster_backup_subnet_parent_segments[each.key].project &&
          local.cloud_vm_cluster_selected_odb_network_segments[each.key].location == local.cloud_vm_cluster_backup_subnet_parent_segments[each.key].location &&
          local.cloud_vm_cluster_selected_odb_network_segments[each.key].segment == local.cloud_vm_cluster_backup_subnet_parent_segments[each.key].segment
        )
      )
      error_message = "Each Cloud VM cluster backup ODB subnet must resolve to a non-null parent ODB network and belong to the selected ODB network, including project and location."
    }

    precondition {
      condition     = alltrue([for purpose in local.cloud_vm_cluster_client_odb_subnet_purposes[each.key] : purpose == "CLIENT_SUBNET"])
      error_message = "Each Cloud VM cluster odb_subnet must have purpose CLIENT_SUBNET when the subnet purpose is known from gcp_odb_subnets_dependency."
    }

    precondition {
      condition     = alltrue([for purpose in local.cloud_vm_cluster_backup_odb_subnet_purposes[each.key] : purpose == "BACKUP_SUBNET"])
      error_message = "Each Cloud VM cluster backup_odb_subnet must have purpose BACKUP_SUBNET when the subnet purpose is known from gcp_odb_subnets_dependency."
    }

    precondition {
      condition = each.value.properties.db_server_ocids == null ? true : (
        length(each.value.properties.db_server_ocids) >= coalesce(each.value.properties.node_count, 2)
      )
      error_message = "Each Cloud VM cluster db_server_ocids list must include at least one DB server OCID per node: minimum of node_count entries when node_count is set, or minimum of two entries when node_count is left unset."
    }
  }
}
