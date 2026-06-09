# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

#-- Used to inform module and release number.
locals {
  module_tag     = { "gcp-oci-terraform-module" : fileexists("${path.module}/release.txt") ? replace(replace("${var.module_name}/${trimspace(file("${path.module}/release.txt"))}", "/", "-"), ".", "-") : var.module_name }
  default_labels = var.default_labels == null ? {} : var.default_labels
}
