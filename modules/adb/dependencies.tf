# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  gcp_odb_networks_dependency = {
    for key, network in var.gcp_odb_networks_dependency : key => {
      id = network.id
    }
  }

  gcp_odb_subnets_dependency = {
    for key, subnet in var.gcp_odb_subnets_dependency : key => {
      id      = subnet.id
      purpose = subnet.purpose
    }
  }
}
