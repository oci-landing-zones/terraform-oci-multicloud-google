# Oracle Database@Google Cloud

## Provision Autonomous Database with Terraform
<walkthrough-tutorial-duration duration="30"></walkthrough-tutorial-duration>

[![gcp-oci-adbs-quickstart](https://github.com/oci-landing-zones/terraform-oci-multicloud-google/blob/main/images/gcp-oci-adbs-quickstart.png?raw=true)](https://github.com/oci-landing-zones/terraform-oci-multicloud-google/blob/main/images/gcp-oci-adbs-quickstart.png?raw=true)

In this tutorial, you will 

1. Setup your Terraform environment for this tutorial
2. Provision an Oracle Autonomous Database in a new VPC
3. Provision an client VM in a new client subnet
4. Perform a sample query from client VM
5. Cleanup the environment

**Let's get started!**

<walkthrough-footnote>[OCI Multicloud Landing Zone for Google Cloud](https://github.com/oci-landing-zones/terraform-oci-multicloud-google)</walkthrough-footnote>

## Prerequisites
This tutorial has the following prerequisites:
- **[Oracle Database@Google Cloud subscription](https://console.cloud.google.com/marketplace/product/oracle/oracle-database-at-google-cloud)**
- **[Google Cloud Project](https://cloud.google.com/resource-manager/docs/creating-managing-projects)**
- **[Google Cloud CLI](https://cloud.google.com/sdk/docs/install)** 
- **[Terraform 1.5+](https://cloud.google.com/docs/terraform/install-configure-terraform#cloud-shell)** 

<walkthrough-footnote></walkthrough-footnote>

### Verify software installation
- **Google Cloud CLI** 
  ``` sh
  gcloud -v | grep SDK
  ```
  You should get `Google Cloud SDK XXX.X.X`
- **Terraform**: 
  ``` sh
  terraform -v | grep "Terraform v"
  ```
  You should get `Terraform vX.X.X`
<walkthrough-footnote></walkthrough-footnote>


### Cloud Shell in Default Mode (recommended) <walkthrough-cloud-shell-icon	></walkthrough-cloud-shell-icon>
- **Cloud Shell** already [pre-installed tools](https://cloud.google.com/shell/docs/how-cloud-shell-works#tools) e.g. Terraform and Google Cloud CLI. 
- **Trust the repo** when you open this tutorial in Cloud Shell, the session will be in Default Mode that come with integrated authorization and persistent storage.
- If you didn't trusted the repo, the session will be in [**Ephemeral Mode**](https://cloud.google.com/shell/docs/using-cloud-shell#choosing_ephemeral_mode) that **all the files you create in this session will be lost** on session end, including your terraform stage and customized configuration. The integrated authorization is not supported as well.



<walkthrough-footnote>[OCI Multicloud Landing Zone for Google Cloud](https://github.com/oci-landing-zones/terraform-oci-multicloud-google)</walkthrough-footnote>

## Authenication Google CLI & Terraform
Cloud Shell support integrated authenication, while a local shell requires explicit authenication setup.
### Cloud Shell <walkthrough-cloud-shell-icon	></walkthrough-cloud-shell-icon>
- When you firstly use `gcloud` or `terraform`, it prompts you to authorize it like below:
  ![Authorize Cloud Shell](https://github.com/oci-landing-zones/terraform-oci-multicloud-google/blob/main/images/gcp-authorize-cloud-shell.png?raw=true)
- Simply click `Authorize` when you see it (in the next step) to allow the tool using your credentials to make calls.
- **If you're using Cloud Shell, you can proceed to next step and skip the below.** 

<walkthrough-footnote></walkthrough-footnote>

### Local Shell 
If you are using Local Shell (or Cloud Shell in Ephemeral Mode), use the following commands for authorizing CLI and Terraform. Please refer to the links for more details.
- [**Authorizing Google Cloud CLI**](https://cloud.google.com/sdk/docs/authorizing#auth-google): `gcloud auth login`
- [**Authorizing Terraform**](https://cloud.google.com/docs/terraform/authentication#local_dev_environment): `gcloud auth application-default login`

<walkthrough-footnote>[OCI Multicloud Landing Zone for Google Cloud](https://github.com/oci-landing-zones/terraform-oci-multicloud-google)</walkthrough-footnote>


## Google Cloud Project
- You need a Google Cloud Project to start provisioning resources for this tutorial. Follow this [document](https://cloud.google.com/resource-manager/docs/creating-managing-projects) to create one if you don't have one.
- You can find your current Project ID at the [Google Cloud Console](https://console.cloud.google.com/welcome)
- Check your project ID is active and accessiable using the following command. Replace the `PROJECT_ID` with your Project ID. 
  ``` sh
  gcloud projects describe PROJECT_ID
  ``` 
<walkthrough-footnote>[OCI Multicloud Landing Zone for Google Cloud](https://github.com/oci-landing-zones/terraform-oci-multicloud-google)</walkthrough-footnote>

## Provision an Autonomous Database + VPC
Template [gcp-oci-adbs-quickstart](https://github.com/oci-landing-zones/terraform-oci-multicloud-google/tree/main/templates/gcp-oci-adbs-quickstart) will be used.
<walkthrough-footnote></walkthrough-footnote>

### 1. Customise the sample configuration
- Open <walkthrough-editor-select-line filePath="cloudshell_open/terraform-oci-multicloud-google/examples/adbs-minimal/main.tf" startLine="1" endLine="3" startCharacterOffset="0" endCharacterOffset="0">main.tf</walkthrough-editor-select-line> to update `project` and `customer_email` to start with.
- Review and customise other parameters as needed, save the file when you're done.
- Setup the admin password using environment variable as shown below. Or you will be prompted when applying the Terraform. 
- The admin password must be between 12 and 30 characters long and contain a digit.
  ``` bash
  export TF_VAR_admin_password="Your0wnPassword"
  ``` 
<walkthrough-footnote></walkthrough-footnote>
### 2. Initialize Terraform 
- In cloud shell, change directory to where the terraform configuration locate
  ``` bash
  cd examples/adbs-minimal
  ``` 
- Initialize Terraform with the following command. 
  ``` bash
  terraform init
  ``` 
  You should get `Terraform has been successfully initialized!`. 
- This initialization prepare the working directory of Terraform configuration, including accessing state, downloading and installing provider plugins, and downloading modules.

<walkthrough-footnote></walkthrough-footnote>
### 3. Validate configuration
- Validate the TF configuration with the following command, which will generate an execution plan for review.
``` bash
terraform plan
``` 
- You should get the following with this template.
  `Plan: 3 to add, 0 to change, 0 to destroy.`

<walkthrough-footnote></walkthrough-footnote>
### 4. Provision resources 
- Run the following command to proceed when the execution plan is good to go. 
  ``` bash
  terraform apply
  ``` 
- Review and confirm the plan by typing `yes` to proceed.
- It's a good time for a coffee break when you see
  `google_oracle_database_autonomous_database.this: Still creating... [10s elapsed]` 
  <walkthrough-tutorial-duration duration="20"></walkthrough-tutorial-duration>

<walkthrough-footnote></walkthrough-footnote>
### 5. Provision complete!
- When you're back, you should get something like this: `Apply complete! Resources: 3 added, 0 changed, 0 destroyed.`
- You will also get Autonomous Database IDs as output:
  - `adbs_dbid` for [Google Cloud](https://console.cloud.google.com/oracle/autonomous-databases)
  - `adbs_ocid` for [Oracle Cloud](https://cloud.oracle.com/search/?category=resources)

<walkthrough-footnote>[OCI Multicloud Landing Zone for Google Cloud](https://github.com/oci-landing-zones/terraform-oci-multicloud-google)</walkthrough-footnote>

## Provision an client VM in a new client subnet

### Congratulations
You've successfully provision an Autonomous Database of *Oracle Database@Google Cloud with Terraform (modules)*. 
<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

<walkthrough-footnote></walkthrough-footnote>
### Let's make some changes
- Now you can expand the architecture by adding a client subnet and VM with SQLPlus pre-installed using the `oradb-client` template. 
- Append the below configuraiton to the <walkthrough-editor-open-file filePath="cloudshell_open/terraform-oci-multicloud-google/examples/adbs-minimal/main.tf" startLine="19" endLine="20">main.tf</walkthrough-editor-open-file>. Save when you're done.
  ```tf
  module "oradb-client" {
    # source = "github.com/oci-landing-zones/terraform-oci-multicloud-google//templates/oradb-client"
    source = "../../templates/oradb-client"
    project = local.project
    location = local.location
    network_name = module.gcp-oci-adbs-quickstart.network_name
    cidr = "10.2.0.0/24"
  }

  output "client_vm" {
    value = module.oradb-client.client_vm
  }
  ```
- Use the following command to install the newly added module
  ```sh
  terraform init -upgrade
  ```
  You should see something like `Upgrading modules...`
- Now you can review and apply the changes
  ```sh
  terraform apply
  ```
  You should see `Plan: 6 to add, 0 to change, 0 to destroy.`, confirm proceed with `yes`.
- You get a new output `client_vm` when the apply complete.

<walkthrough-footnote></walkthrough-footnote>

### Check Terraform Idempotency
- You can check the terraform idempotency by re-running `terraform apply`
  ```sh
  terraform apply
  ```
- As no change is expected, you should get 
  `No changes. Your infrastructure matches the configuration.`
  
<walkthrough-footnote>[OCI Multicloud Landing Zone for Google Cloud](https://github.com/oci-landing-zones/terraform-oci-multicloud-google)</walkthrough-footnote>

## Perform a sample query from client VM

### Make use of the Terraform output
- You can export the Terraform outputs as environment variables by using `terraform output` and `jq`.
  ```sh
  export VM_PROJECT=$(terraform output -json client_vm | jq -r '.project')
  export VM_ZONE=$(terraform output -json client_vm | jq -r '.zone')
  export VM_NAME=$(terraform output -json client_vm | jq -r '.name')
  export LOCATION=$(terraform output -raw location)
  export CONNSTR=$(terraform output -raw connstr)
  export DBID=$(terraform output -raw adbs_dbid)
  ```
- Check your environment variables as below.
  ```sh
  echo LOCATION = $LOCATION
  echo DBID = $DBID
  echo CONNSTR = $CONNSTR
  echo VM_PROJECT = $VM_PROJECT
  echo VM_ZONE = $VM_ZONE
  echo VM_NAME = $VM_NAME
  ```
<walkthrough-footnote></walkthrough-footnote>

### Query the Autonomous Database from the client VM
- Use `gcloud compute scp` to copy the sample sql file to the client VM. 
  ```sh
  gcloud compute scp cloud_identity.sql $VM_NAME:~/ --project $VM_PROJECT --zone $VM_ZONE
  ```
  - `gcloud` will prompt you to input the passphrase for the newly generated SSH key when you run this for the first time.
- You can query the Autonomous Database from the client VM using SSH (`gcloud compute ssh`) and SQLPlus (`--command="sqlplus"`) together
  ```sh
  gcloud compute ssh --project $VM_PROJECT --zone $VM_ZONE $VM_NAME --command="sqlplus admin/$TF_VAR_admin_password@'$CONNSTR' @cloud_identity.sql" 
  ```
  - If you receive `SQLPlus not avaialble` error, retry after a little while. The SQLPlus installation might take a few minutes to complete after the VM is provisioned.
  - You can use the following command to verify the sqlplus installation.
    ```sh
    gcloud compute ssh --project $VM_PROJECT --zone $VM_ZONE $VM_NAME --command="sqlplus -v" 
    ```
<walkthrough-footnote></walkthrough-footnote>

### Connect SQLPlus at the client VM
- Alternatively, you can connect to sqlplus at the client VM directly for any other query.
  ```sh
  gcloud compute ssh --project $VM_PROJECT --zone $VM_ZONE $VM_NAME --command="sqlplus admin/$TF_VAR_admin_password@'$CONNSTR'"
  ```
<walkthrough-footnote></walkthrough-footnote>

### Prepare the Wallet
- If you prefer to [connect with Wallet (mTLS)](https://docs.oracle.com/en/cloud/paas/autonomous-database/serverless/adbsb/connect-sqlplus.html), you can prepare the wallet in the client VM using `gcloud` as below.
  ```sh
  gcloud oracle-database autonomous-databases generate-wallet "projects/$VM_PROJECT/locations/$LOCATION/autonomousDatabases/$DBID" --location=$LOCATION --password=$TF_VAR_admin_password --project=$VM_PROJECT --format=json | jq -r '.archiveContent' | sed -e 's/-/+/g' -e 's/_/\//g' | base64 -d > Wallet_$DBID.zip
  gcloud compute scp Wallet_$DBID.zip $VM_NAME:~/ --project $VM_PROJECT --zone $VM_ZONE
  rm Wallet_$DBID.zip
  ```
<walkthrough-footnote>[OCI Multicloud Landing Zone for Google Cloud](https://github.com/oci-landing-zones/terraform-oci-multicloud-google)</walkthrough-footnote>

## Congratulations
You've successfully complete the tutorial by querying the Autonomous Database from the client VM with SQLPlus.
<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

### What's next:
- **Continue with [RAG Chatbot engine](https://github.com/oci-landing-zones/terraform-oci-multicloud-google/blob/main/docs/tutorials/adbs-rag-chatbot/README_RAG.md)**: Use the Autonomous Database you've just provisioned as vector database for building a RAG Chatbot engine.
- **Don't forget to clean up**: Run the following command to cleanup the environment when you're done with all the related tutorials.
    ```bash
    terraform destroy
    ```
- **Explore more**: See the [OCI Multicloud Landing Zone for Google Cloud](https://github.com/oci-landing-zones/terraform-oci-multicloud-google) for more Terraform modules, templates, examples, and tutorials for Oracle Database @ Google.

