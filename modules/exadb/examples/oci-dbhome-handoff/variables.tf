# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

variable "tenancy_ocid" {
  description = "OCI tenancy OCID."
  type        = string
}

variable "region" {
  description = "OCI region for DB Home, CDB, and PDB operations. Use the OCI region of the VM Cluster OCID."
  type        = string
}

variable "user_ocid" {
  description = "OCI user OCID for API-key authentication."
  type        = string
  default     = ""
}

variable "fingerprint" {
  description = "OCI API key fingerprint."
  type        = string
  default     = ""
}

variable "private_key_path" {
  description = "Path to the OCI API signing private key."
  type        = string
  default     = ""
}

variable "private_key_password" {
  description = "Password for the OCI API signing private key, when encrypted."
  type        = string
  default     = ""
  sensitive   = true
}

variable "gcp_cloud_vm_clusters_dependency" {
  description = "Optional direct dependency map from modules/exadb output gcp_cloud_vm_clusters."
  type = map(object({
    id    = optional(string)
    name  = optional(string)
    ocid  = optional(string)
    state = optional(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key in keys(var.gcp_cloud_vm_clusters_dependency) :
      can(regex("^[A-Z][A-Z0-9_-]*$", key))
    ])
    error_message = "gcp_cloud_vm_clusters_dependency keys must be uppercase semantic identifiers using only A-Z, 0-9, underscores, and hyphens, for example PRIMARY or PROD_CLUSTER."
  }
}

variable "default_defined_tags" {
  description = "Default OCI defined tags passed through to terraform-oci-modules-exadata."
  type        = any
  default     = {}
}

variable "default_freeform_tags" {
  description = "Default OCI freeform tags passed through to terraform-oci-modules-exadata."
  type        = any
  default     = {}
}

variable "cloud_db_homes_configuration" {
  description = "OCI DB Home configuration. Each entry must set vm_cluster_id to either an OCI Cloud VM Cluster OCID or a key from gcp_cloud_vm_clusters_dependency."
  type        = any
  default     = null

  validation {
    condition = var.cloud_db_homes_configuration == null ? true : (
      can(keys(var.cloud_db_homes_configuration)) &&
      alltrue([
        for key in keys(var.cloud_db_homes_configuration) :
        can(regex("^[A-Z][A-Z0-9_-]*$", key))
      ])
    )
    error_message = "cloud_db_homes_configuration keys must be uppercase semantic identifiers using only A-Z, 0-9, underscores, and hyphens, for example DBHOME1."
  }
}

variable "databases_configuration" {
  description = "OCI CDB configuration passed through to terraform-oci-modules-exadata."
  type        = any
  default     = null

  validation {
    condition = var.databases_configuration == null ? true : (
      can(keys(var.databases_configuration)) &&
      alltrue([
        for key in keys(var.databases_configuration) :
        can(regex("^[A-Z][A-Z0-9_-]*$", key))
      ])
    )
    error_message = "databases_configuration keys must be uppercase semantic identifiers using only A-Z, 0-9, underscores, and hyphens, for example CDB1."
  }
}

variable "pluggable_databases_configuration" {
  description = "OCI PDB configuration passed through to terraform-oci-modules-exadata."
  type        = any
  default     = null

  validation {
    condition = var.pluggable_databases_configuration == null ? true : (
      can(keys(var.pluggable_databases_configuration)) &&
      alltrue([
        for key in keys(var.pluggable_databases_configuration) :
        can(regex("^[A-Z][A-Z0-9_-]*$", key))
      ])
    )
    error_message = "pluggable_databases_configuration keys must be uppercase semantic identifiers using only A-Z, 0-9, underscores, and hyphens, for example PDB1."
  }
}
