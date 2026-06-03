# OCI DB Home Handoff Example

This wrapper shows the Day-2 handoff from Oracle Database@Google Cloud to the
OCI Exadata Database module.

Pass the GCP VM Cluster dependency map from orchestration. This example extracts
the OCI VM Cluster OCID from `gcp_cloud_vm_clusters_dependency.<key>.ocid` and
passes it to the OCI module as
`cloud_db_homes_configuration.<dbhome>.vm_cluster_id`.

The reusable GCP module does not call the OCI provider. This wrapper is the
handoff boundary between the GCP VM Cluster output contract and the upstream OCI
Exadata module input contract.
It only resolves DB Home `vm_cluster_id` values to OCI Cloud VM Cluster OCIDs;
DB Home, CDB, and PDB resource semantics remain owned by the upstream OCI
module.

## Flow

1. Deploy the GCP VM Cluster stack, for example `../cluster`, with `enable_output = true`.
2. Pass the producer `gcp_cloud_vm_clusters` output into this wrapper as `gcp_cloud_vm_clusters_dependency`.
3. Wait until the VM Cluster output has `state = "AVAILABLE"` and `ocid` is not
   null.
4. Copy `input.auto.tfvars.template` to `<name>.auto.tfvars`.
5. Set OCI authentication values, the OCI region, and DB/CDB/PDB settings.
6. Run the normal Terraform workflow from this directory.

A normal `terraform plan` for this wrapper can require OCI credentials and network access because it initializes and calls the downstream OCI Exadata module. The local tests for this handoff path mock the OCI provider so they can validate the wrapper contract without live OCI access.

This wrapper inherits the upstream OCI Exadata module's Terraform requirement of `>= 1.5.0`. The reusable Google Cloud modules in this repository remain on the repository-wide `>= 1.4.0` contract.

Use the OCI region embedded in the VM Cluster OCID, not the Google Cloud region.
For example, if the OCID starts with `ocid1.cloudvmcluster.oc1.uk-london-1`,
set `region = "uk-london-1"`.

## Handoff Contract

The orchestration dependency map form is:

```hcl
gcp_cloud_vm_clusters_dependency = {
  PRIMARY = {
    ocid  = "ocid1.cloudvmcluster.oc1.<region>.<id>"
    state = "AVAILABLE"
  }
}
```

All logical keys in dependency and configuration maps must be uppercase semantic
identifiers using `A-Z`, `0-9`, `_`, and `-`.

Then each DB Home can reference the VM Cluster by key through `vm_cluster_id`:

```hcl
cloud_db_homes_configuration = {
  DBHOME1 = {
    vm_cluster_id  = "PRIMARY"
    display_name   = "dgc-dbhome1"
    db_version     = "19.0.0.0"
    source         = "VM_CLUSTER_NEW"
  }
}
```

The wrapper converts that to:

```hcl
vm_cluster_id = local.gcp_cloud_vm_clusters_dependency.PRIMARY.ocid
```

Direct OCID handoff uses the same field:

When `vm_cluster_id` starts with `ocid1.`, the wrapper treats it as a direct OCI OCID, passes it through without dependency lookup, and requires it to be a valid OCI Cloud VM Cluster OCID. Dependency keys must be uppercase semantic identifiers, so an exact collision between a direct OCID and a dependency key is not a supported shape.

```hcl
cloud_db_homes_configuration = {
  DBHOME1 = {
    vm_cluster_id = "ocid1.cloudvmcluster.oc1.<region>.<id>"
    display_name  = "dgc-dbhome1"
    db_version    = "19.0.0.0"
    source        = "VM_CLUSTER_NEW"
  }
}
```

Do not use the Google resource name
`projects/<project>/locations/<region>/cloudVmClusters/<name>` as
`vm_cluster_id`; the OCI module requires the OCI OCID.

## Validation

The wrapper fails the plan when:

* a DB Home does not set `vm_cluster_id`;
* a dependency or configuration map uses a non-uppercase logical key;
* a `vm_cluster_id` value is empty or contains whitespace;
* a direct `vm_cluster_id` OCID starts with `ocid1.` but is not a valid `ocid1.cloudvmcluster.<realm>.<region>.<id>` value;
* a `vm_cluster_id` value that is not an OCI OCID does not exist in the GCP VM Cluster dependency map;
* the referenced dependency has no valid OCI Cloud VM Cluster OCID in `ocid`;
* the referenced dependency has no `state` or a state other than `AVAILABLE`.

## Source Pinning

This example pins the upstream OCI Exadata module to release `v1.1.0`:

```hcl
git::https://github.com/oci-landing-zones/terraform-oci-modules-exadata.git//exadata-database?ref=v1.1.0
```

Update the pin deliberately after validating a newer upstream release.
