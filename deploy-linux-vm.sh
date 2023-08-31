#!/bin/bash

# Run below to deploy to select runner env instance
while getopts e:c: option
do
  case "${option}"
  in
    e) VM_ENV=${OPTARG};;
    c) VM_COUNT=${OPTARG};;
  esac
done

if [ ${#VM_ENV} == 0  ]
then
  echo "Please select a runner environment using -e flag."
  exit 1
fi

if [ ${#VM_COUNT} == 0  ]
then
  echo "Please select a runner count using -c flag."
  exit 1
fi
export TF_VAR_VM_count=$VM_COUNT

export SOLUTION="VM"

#import global Variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $SCRIPT_DIR
echo $SCRIPT_DIR
. ./env/env_variables_$VM_ENV.sh

OP_ENV=$TF_VAR_op_env
LOC_CODE=$(echo "$TF_VAR_location_code" |awk '{print tolower($0)}')

PROJECT_NAME='dse'
export TF_VAR_project_name=$PROJECT_NAME


RESOURCE_GROUP_NAME="rg-${OP_ENV}-${LOC_CODE}-${PROJECT_NAME}-001"
shrd_kv_name=$(az keyvault list --resource-group $RESOURCE_GROUP_NAME --query "[?starts_with(name,'kv-${OP_ENV}-${LOC_CODE}-${PROJECT_NAME}-')].name" -o tsv)
export TF_VAR_shrd_kv_name=`echo $shrd_kv_name | sed 's/\r//g'`

if [ ${#shrd_kv_name} == 0  ]
then
    echo "Unable to retrieve the Key Vault Name for the Secrets. Please check the Key Vault has been created or that your Azure account has access"
    exit 1
fi



STATENAME="tmpl-linux-${OP_ENV}-${TF_VAR_location_code}-${PROJECT_NAME}-${VM_COUNT}"
export TF_CLI_ARGS_init="${TF_CLI_ARGS_init} -backend-config=\"key=${SOLUTION}/${STATENAME}.tfstate\""
# rm .terraform/terraform.tfstate
terraform init -upgrade
terraform plan
terraform apply -auto-approve
