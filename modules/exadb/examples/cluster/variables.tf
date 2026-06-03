# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

variable "project_id" { description = "GCP project ID enabled for Oracle Database@Google Cloud." }
variable "location" { description = "GCP region for Oracle Database@Google Cloud resources." }

variable "module_name" {
  type    = string
  default = "oracle-database-at-gcp"
}

variable "enable_output" {
  type    = bool
  default = true
}

variable "ssh_public_keys_file_path" {
  description = "Path to SSH public key file for VM cluster access."
  type        = string
  default     = null
}

variable "default_labels" {
  type    = map(string)
  default = {}

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
  type    = any
  default = false
}

variable "gcp_odb_networks_dependency" {
  type    = map(any)
  default = {}
}

variable "gcp_odb_subnets_dependency" {
  type    = map(any)
  default = {}
}

variable "gcp_cloud_exadata_infrastructures_dependency" {
  type    = map(any)
  default = {}
}

variable "gcp_cloud_vm_clusters_configuration" {
  type    = any
  default = null
}
