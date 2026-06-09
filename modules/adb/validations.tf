# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  gcp_autonomous_databases_admin_password_keys = keys(nonsensitive(var.gcp_autonomous_databases_admin_passwords))
}

resource "terraform_data" "validate_admin_password_keys" {
  lifecycle {
    precondition {
      condition = length(var.gcp_autonomous_databases_configuration) == 0 ? true : alltrue([
        for key in local.gcp_autonomous_databases_admin_password_keys :
        contains(keys(var.gcp_autonomous_databases_configuration), key)
      ])
      error_message = "gcp_autonomous_databases_admin_passwords keys must match keys in gcp_autonomous_databases_configuration. Remove unknown password keys or rename them to match an Autonomous Database key."
    }

    precondition {
      condition = alltrue([
        for key, adb in var.gcp_autonomous_databases_configuration :
        contains(local.gcp_autonomous_databases_admin_password_keys, key) ||
        try(adb.properties.secret_id, null) != null
      ])
      error_message = "Each Autonomous Database must have an admin password keyed by the same map key in gcp_autonomous_databases_admin_passwords unless properties.secret_id is set."
    }

    precondition {
      condition = alltrue([
        for key, adb in var.gcp_autonomous_databases_configuration :
        !(contains(local.gcp_autonomous_databases_admin_password_keys, key) && try(adb.properties.secret_id, null) != null)
      ])
      error_message = "Each Autonomous Database must use either an admin password from gcp_autonomous_databases_admin_passwords or properties.secret_id, not both."
    }
  }
}
