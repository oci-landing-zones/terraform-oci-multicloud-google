# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

variable "module_name" {
  description = "Display name for this module instance."
  type        = string
  default     = "oracle-autonomous-database-at-gcp"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z]([a-z0-9_-]{0,54})?$", var.module_name))
    error_message = "module_name must be 1-55 characters, start with a lowercase letter, and contain only lowercase letters, numbers, hyphens, or underscores so it can be used in Google Cloud labels."
  }
}

variable "enable_output" {
  description = "Whether this module should emit resource outputs."
  type        = bool
  default     = true
  nullable    = false
}

variable "default_project_id" {
  description = "Default Google Cloud project ID used by resources when project_id is not set on the resource."
  type        = string
  default     = null

  validation {
    condition     = var.default_project_id == null ? true : (trimspace(var.default_project_id) != "" && var.default_project_id == trimspace(var.default_project_id) && !can(regex("[[:space:]]", var.default_project_id)))
    error_message = "default_project_id must be null or a non-empty Google Cloud project ID without leading, trailing, or internal whitespace."
  }
}

variable "default_location" {
  description = "Default Google Cloud region used by resources when location is not set on the resource."
  type        = string
  default     = null

  validation {
    condition     = var.default_location == null ? true : (trimspace(var.default_location) != "" && var.default_location == trimspace(var.default_location) && !can(regex("[[:space:]]", var.default_location)))
    error_message = "default_location must be null or a non-empty Google Cloud region without leading, trailing, or internal whitespace."
  }
}

variable "default_labels" {
  description = "Default labels merged into all resources. Resource-specific labels win on key collisions."
  type        = map(string)
  default     = {}
  nullable    = false

  validation {
    condition = alltrue([
      for key, value in var.default_labels :
      can(regex("^[a-z][a-z0-9_-]{0,62}$", key)) &&
      (value == null ? false : can(regex("^[a-z0-9_-]{0,63}$", value)))
    ])
    error_message = "default_labels keys must be 1-63 characters, start with a lowercase letter, and contain only lowercase letters, numbers, underscores, or hyphens. Values must be empty or 1-63 characters containing only lowercase letters, numbers, underscores, or hyphens."
  }
}

variable "default_deletion_protection" {
  description = "Default deletion protection value for resources that support deletion_protection."
  type        = bool
  default     = true
  nullable    = false
}

variable "default_deletion_policy" {
  description = "Default deletion policy used by resources that support deletion_policy. PREVENT blocks Terraform destroys unless overridden."
  type        = string
  default     = "PREVENT"
  nullable    = false

  validation {
    condition     = contains(["DELETE", "PREVENT", "ABANDON"], var.default_deletion_policy)
    error_message = "default_deletion_policy must be one of DELETE, PREVENT, or ABANDON."
  }
}

variable "gcp_odb_networks_dependency" {
  description = "Externally managed ODB networks this module may depend on, keyed by logical name."
  type = map(object({
    id = string
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key in keys(var.gcp_odb_networks_dependency) :
      can(regex("^[A-Z][A-Z0-9_-]*$", key))
    ])
    error_message = "gcp_odb_networks_dependency keys must be uppercase semantic identifiers using only A-Z, 0-9, underscores, and hyphens, for example PRIMARY or SHARED_NETWORK."
  }

  validation {
    condition = alltrue([
      for network in values(var.gcp_odb_networks_dependency) :
      can(regex("^projects/[^/[:space:]]+/locations/[^/[:space:]]+/odbNetworks/[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", network.id))
    ])
    error_message = "ODB network dependency id values must use projects/{project}/locations/{location}/odbNetworks/{odb_network} format."
  }
}

variable "gcp_odb_subnets_dependency" {
  description = "Externally managed ODB subnets this module may depend on, keyed by logical name."
  type = map(object({
    id      = string
    purpose = string
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key in keys(var.gcp_odb_subnets_dependency) :
      can(regex("^[A-Z][A-Z0-9_-]*$", key))
    ])
    error_message = "gcp_odb_subnets_dependency keys must be uppercase semantic identifiers using only A-Z, 0-9, underscores, and hyphens, for example CLIENT or BACKUP."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.gcp_odb_subnets_dependency) :
      can(regex("^projects/[^/[:space:]]+/locations/[^/[:space:]]+/odbNetworks/[a-z]([a-z0-9-]{0,61}[a-z0-9])?/odbSubnets/[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", subnet.id))
    ])
    error_message = "ODB subnet dependency id values must use projects/{project}/locations/{location}/odbNetworks/{odb_network}/odbSubnets/{odb_subnet} format."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.gcp_odb_subnets_dependency) :
      contains(["CLIENT_SUBNET", "BACKUP_SUBNET"], subnet.purpose)
    ])
    error_message = "ODB subnet dependency purpose must be set to CLIENT_SUBNET or BACKUP_SUBNET on every entry."
  }
}

variable "gcp_autonomous_databases_configuration" {
  description = "Map of Oracle Autonomous Databases to create."
  type = map(object({
    autonomous_database_id = string
    database               = optional(string)
    display_name           = optional(string)
    location               = optional(string)
    project_id             = optional(string)
    labels                 = optional(map(string), {})
    deletion_protection    = optional(bool)
    deletion_policy        = optional(string)

    odb_network = optional(string)
    odb_subnet  = optional(string)

    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }))

    properties = optional(object({
      db_workload                     = optional(string)
      license_type                    = optional(string)
      compute_count                   = optional(number)
      cpu_core_count                  = optional(number)
      data_storage_size_tb            = optional(number)
      data_storage_size_gb            = optional(number)
      db_version                      = optional(string)
      db_edition                      = optional(string)
      character_set                   = optional(string)
      n_character_set                 = optional(string)
      private_endpoint_ip             = optional(string)
      private_endpoint_label          = optional(string)
      is_auto_scaling_enabled         = optional(bool)
      is_storage_auto_scaling_enabled = optional(bool)
      backup_retention_period_days    = optional(number)
      maintenance_schedule_type       = optional(string)
      mtls_connection_required        = optional(bool)
      operations_insights_state       = optional(string)
      secret_id                       = optional(string)
      vault_id                        = optional(string)
      customer_contacts = optional(list(object({
        email = string
      })), [])
    }))
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key in keys(var.gcp_autonomous_databases_configuration) :
      can(regex("^[A-Z][A-Z0-9_-]*$", key))
    ])
    error_message = "gcp_autonomous_databases_configuration keys must be uppercase semantic identifiers using only A-Z, 0-9, underscores, and hyphens, for example PRIMARY or DATABASE."
  }

  validation {
    condition = alltrue([
      for adb in var.gcp_autonomous_databases_configuration :
      can(regex("^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", adb.autonomous_database_id))
    ])
    error_message = "Autonomous database IDs must start with a lowercase letter, end with a lowercase letter or number, contain only lowercase letters, numbers, and hyphens, and be 1-63 characters long."
  }

  validation {
    condition = alltrue([
      for adb in var.gcp_autonomous_databases_configuration :
      adb.database == null ? true : can(regex("^[A-Za-z][A-Za-z0-9]{0,29}$", adb.database))
    ])
    error_message = "Autonomous database database names must begin with a letter, contain only alphanumeric characters, and be at most 30 characters long when set."
  }

  validation {
    condition = alltrue(flatten([
      for adb in var.gcp_autonomous_databases_configuration : [
        for key, value in adb.labels :
        can(regex("^[a-z][a-z0-9_-]{0,62}$", key)) &&
        (value == null ? false : can(regex("^[a-z0-9_-]{0,63}$", value)))
      ]
    ]))
    error_message = "Autonomous database labels keys must be 1-63 characters, start with a lowercase letter, and contain only lowercase letters, numbers, underscores, or hyphens. Values must be empty or 1-63 characters containing only lowercase letters, numbers, underscores, or hyphens."
  }

  validation {
    condition = alltrue([
      for adb in var.gcp_autonomous_databases_configuration :
      adb.project_id == null ? true : (trimspace(adb.project_id) != "" && adb.project_id == trimspace(adb.project_id) && !can(regex("[[:space:]]", adb.project_id)))
    ])
    error_message = "Autonomous database project_id values must be null or non-empty strings without leading, trailing, or internal whitespace."
  }

  validation {
    condition = alltrue([
      for adb in var.gcp_autonomous_databases_configuration :
      adb.location == null ? true : (trimspace(adb.location) != "" && adb.location == trimspace(adb.location) && !can(regex("[[:space:]]", adb.location)))
    ])
    error_message = "Autonomous database location values must be null or non-empty strings without leading, trailing, or internal whitespace."
  }

  validation {
    condition = alltrue([
      for adb in var.gcp_autonomous_databases_configuration :
      adb.deletion_policy == null ? true : contains(["DELETE", "PREVENT", "ABANDON"], adb.deletion_policy)
    ])
    error_message = "Autonomous database deletion_policy values must be null or one of DELETE, PREVENT, or ABANDON."
  }

  validation {
    condition = alltrue([
      for adb in var.gcp_autonomous_databases_configuration :
      adb.odb_network != null && adb.odb_subnet != null
    ])
    error_message = "Each Autonomous Database must set odb_network and odb_subnet to resource names or dependency keys."
  }

  validation {
    condition = alltrue([
      for adb in var.gcp_autonomous_databases_configuration :
      (adb.odb_network == null || (trimspace(adb.odb_network) != "" && adb.odb_network == trimspace(adb.odb_network) && !can(regex("[[:space:]]", adb.odb_network)))) &&
      (adb.odb_subnet == null || (trimspace(adb.odb_subnet) != "" && adb.odb_subnet == trimspace(adb.odb_subnet) && !can(regex("[[:space:]]", adb.odb_subnet))))
    ])
    error_message = "Autonomous database ODB network and subnet references must not be empty or contain whitespace when set."
  }

  validation {
    condition = alltrue([
      for adb in var.gcp_autonomous_databases_configuration :
      adb.odb_network == null ? true : (
        !can(regex("^projects/", adb.odb_network)) ||
        can(regex("^projects/[^/[:space:]]+/locations/[^/[:space:]]+/odbNetworks/[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", adb.odb_network))
      )
    ])
    error_message = "Autonomous database odb_network values that start with projects/ must use projects/{project}/locations/{location}/odbNetworks/{odb_network} format."
  }

  validation {
    condition = alltrue([
      for adb in var.gcp_autonomous_databases_configuration :
      adb.odb_subnet == null ? true : (
        !can(regex("^projects/", adb.odb_subnet)) ||
        can(regex("^projects/[^/[:space:]]+/locations/[^/[:space:]]+/odbNetworks/[a-z]([a-z0-9-]{0,61}[a-z0-9])?/odbSubnets/[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", adb.odb_subnet))
      )
    ])
    error_message = "Autonomous database odb_subnet values that start with projects/ must use projects/{project}/locations/{location}/odbNetworks/{odb_network}/odbSubnets/{odb_subnet} format."
  }

  validation {
    condition = alltrue([
      for adb in var.gcp_autonomous_databases_configuration :
      adb.properties == null ? true : (
        adb.properties.db_workload == null ? true : contains(["DB_WORKLOAD_UNSPECIFIED", "OLTP", "DW", "AJD", "APEX"], adb.properties.db_workload)
      )
    ])
    error_message = "Autonomous database db_workload must be DB_WORKLOAD_UNSPECIFIED, OLTP, DW, AJD, or APEX when set."
  }

  validation {
    condition = alltrue([
      for adb in var.gcp_autonomous_databases_configuration :
      adb.properties == null ? true : (
        adb.properties.license_type == null ? true : contains(["LICENSE_TYPE_UNSPECIFIED", "LICENSE_INCLUDED", "BRING_YOUR_OWN_LICENSE"], adb.properties.license_type)
      )
    ])
    error_message = "Autonomous database license_type must be LICENSE_TYPE_UNSPECIFIED, LICENSE_INCLUDED, or BRING_YOUR_OWN_LICENSE when set."
  }

  validation {
    condition = alltrue([
      for adb in var.gcp_autonomous_databases_configuration :
      adb.properties == null ? true : (
        adb.properties.db_edition == null ? true : contains(["DATABASE_EDITION_UNSPECIFIED", "STANDARD_EDITION", "ENTERPRISE_EDITION"], adb.properties.db_edition)
      )
    ])
    error_message = "Autonomous database db_edition must be DATABASE_EDITION_UNSPECIFIED, STANDARD_EDITION, or ENTERPRISE_EDITION when set."
  }

  validation {
    condition = alltrue([
      for adb in var.gcp_autonomous_databases_configuration :
      adb.properties == null ? true : (
        adb.properties.maintenance_schedule_type == null ? true : contains(["MAINTENANCE_SCHEDULE_TYPE_UNSPECIFIED", "EARLY", "REGULAR"], adb.properties.maintenance_schedule_type)
      )
    ])
    error_message = "Autonomous database maintenance_schedule_type must be MAINTENANCE_SCHEDULE_TYPE_UNSPECIFIED, EARLY, or REGULAR when set."
  }

  validation {
    condition = alltrue([
      for adb in var.gcp_autonomous_databases_configuration :
      adb.properties == null ? true : (
        adb.properties.operations_insights_state == null
      )
    ])
    error_message = "Autonomous database operations_insights_state is service-managed and must not be configured as an input."
  }

  validation {
    condition = alltrue([
      for adb in var.gcp_autonomous_databases_configuration :
      adb.properties == null ? true : (
        adb.properties.private_endpoint_ip == null ? true : can(regex("^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}$", adb.properties.private_endpoint_ip))
      )
    ])
    error_message = "Autonomous database private_endpoint_ip must be a valid IPv4 address without CIDR suffix when set."
  }

  validation {
    condition = alltrue(flatten([
      for adb in var.gcp_autonomous_databases_configuration :
      adb.properties == null ? [true] : [
        for value in [
          adb.properties.character_set,
          adb.properties.n_character_set,
          adb.properties.db_version,
          adb.properties.private_endpoint_label,
          adb.properties.secret_id,
          adb.properties.vault_id
        ] :
        value == null ? true : trimspace(value) != ""
      ]
    ]))
    error_message = "Autonomous database optional string properties character_set, n_character_set, db_version, private_endpoint_label, secret_id, and vault_id must be null or non-empty strings."
  }

  validation {
    condition = alltrue([
      for adb in var.gcp_autonomous_databases_configuration :
      adb.properties == null ? true : (
        adb.properties.backup_retention_period_days == null ? true : (
          adb.properties.backup_retention_period_days >= 1 && adb.properties.backup_retention_period_days <= 60
        )
      )
    ])
    error_message = "Autonomous database backup_retention_period_days must be between 1 and 60 when set."
  }

  validation {
    condition = alltrue([
      for adb in var.gcp_autonomous_databases_configuration :
      adb.properties == null ? true : (
        adb.properties.data_storage_size_tb == null ||
        adb.properties.data_storage_size_gb == null
      )
    ])
    error_message = "Autonomous database properties must set at most one of data_storage_size_tb or data_storage_size_gb."
  }

  validation {
    condition = alltrue(flatten([
      for adb in var.gcp_autonomous_databases_configuration :
      adb.properties == null ? [true] : (
        adb.properties.customer_contacts == null ? [true] : [
          for contact in adb.properties.customer_contacts :
          can(regex("^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$", contact.email))
        ]
      )
    ]))
    error_message = "Autonomous database customer contact email values must be valid email addresses."
  }
}

variable "gcp_autonomous_databases_admin_passwords" {
  description = "Admin passwords for Autonomous Databases, keyed by the same keys as gcp_autonomous_databases_configuration. Kept separate from the configuration map to preserve Terraform's sensitive marking. Consider passing via the TF_VAR_gcp_autonomous_databases_admin_passwords environment variable instead of storing in tfvars files."
  type        = map(string)
  sensitive   = true
  default     = {}
  nullable    = false

  validation {
    condition = alltrue([
      for key in keys(var.gcp_autonomous_databases_admin_passwords) :
      can(regex("^[A-Z][A-Z0-9_-]*$", key))
    ])
    error_message = "gcp_autonomous_databases_admin_passwords keys must be uppercase semantic identifiers using only A-Z, 0-9, underscores, and hyphens, matching gcp_autonomous_databases_configuration keys."
  }

  validation {
    condition = alltrue([
      for password in values(var.gcp_autonomous_databases_admin_passwords) :
      length(password) >= 12 &&
      length(password) <= 30 &&
      can(regex("[A-Z]", password)) &&
      can(regex("[a-z]", password)) &&
      can(regex("[0-9]", password)) &&
      !can(regex("\"", password)) &&
      !can(regex("admin", lower(password)))
    ])
    error_message = "Autonomous Database admin passwords must be between 12 and 30 characters, contain at least one uppercase letter, one lowercase letter, and one number, and must not contain double quotes or 'admin' in any casing."
  }
}
