#!/bin/bash
export PS4="\$LINENO: "
set -xv

export TF_LOG="ERROR" 
# Name of the cluster instance
export TERRAFORM_STATE_CONTAINER_NAME="tfstateasdkamgmt"


#Operating Environment for the runner
OP_ENV="ASDK"  #e.g. Dev prod, preprod, test...

#Project Name - change to identify your GHE runner vms ( e.g. dse = DevsSecops Enterprise partner)
export TF_VAR_project_name="dse"

#Change the default username if you wish
export TF_VAR_user_name="azureuser"

#Resource Group Tags
export TF_VAR_solution="Linux Template"
export TF_VAR_owner="danielm@elderda.uk"

#Location vars
export TF_VAR_location_code="uks"               #used to generate the resource names - represents location when naming resources
export LOCATION="uksouth"                       #Azure region name for deployment of resources



export RES_SUB=$(az account list --query "[?ends_with(name,'-$OP_ENV')].name" -o tsv) # Resource Sub Subscription name
export SIG_SUB=$(az account list --query "[?ends_with(name,'-Connectivity')].name" -o tsv)  # Specialized Image Gallery Sub

az account set --subscription $RES_SUB

### Only do this once. Make sure that the versions.tf files also represent the settings below
export STORAGE_ACCOUNT_NAME=$TERRAFORM_STATE_CONTAINER_NAME # storage name must be unique throughout azure. Change so the Account name does not conflict. Ensure ALL versions.tf files have this also set.


### Do Not Change these Variables ###
export TF_VAR_resource_group_location=$LOCATION
export RESOURCE_GROUP_NAME="rg-tfstate-mgmt-${TF_VAR_location_code}"
export CONTAINER_NAME=terraform-backend
export TF_VAR_res_sub_name=$RES_SUB            # Infrastructure Subscription name
export TF_VAR_sig_sub_name=$SIG_SUB              # Management Subscription name
export TF_VAR_resource_group_location=$LOCATION

STG_KEY=$(az storage account keys list -g ${RESOURCE_GROUP_NAME} -n ${TERRAFORM_STATE_CONTAINER_NAME} --query "[?keyName=='key1'].value" -o tsv)
export TF_CLI_ARGS_init="-backend-config=\"storage_account_name=${TERRAFORM_STATE_CONTAINER_NAME}\" -backend-config=\"resource_group_name=${RESOURCE_GROUP_NAME}\" -backend-config=\"access_key=${STG_KEY}\""

# # get the subscription Id's
 export TF_VAR_shared_sub_id=$(az account show --subscription ${SIG_SUB} --query id -o tsv )
 export TF_VAR_infra_sub_id=$(az account show --subscription ${RES_SUB} --query id -o tsv )

# # remove the \r from the variable as it breaks TF
export TF_VAR_shared_sub_id=$(echo $TF_VAR_shared_sub_id | sed -r  's/\r//g')
export TF_VAR_infra_sub_id=$(echo $TF_VAR_infra_sub_id | sed -r  's/\r//g')
TF_VAR_op_env=$(echo "$OP_ENV" |awk '{print tolower($0)}')