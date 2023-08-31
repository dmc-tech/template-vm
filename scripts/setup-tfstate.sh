#!/bin/bash

# Run below to deploy to select runner env instance
while getopts e: option
do
  case "${option}"
  in
    e) VM_ENV=${OPTARG};;
  esac
done

if [ ${#VM_ENV} == 0  ]
then
  echo "Please select a runner environment using -e flag."
  exit 1
fi


#import global Variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $SCRIPT_DIR
echo $SCRIPT_DIR
. ./../env/env_variables_$VM_ENV.sh


#assumes connected to correct sub already VIA AZ CLI
az account set --subscription $RES_SUB
# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --kind StorageV2 --sku Standard_LRS --encryption-services blob --public-network-access Disabled --publish-internet-endpoint false

# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME

# Define Resource Group and name of VNET for Private endpoints, etc


# Create Private DNS zone (for testing)

az network private-dns zone create \
    --resource-group test-rg \
    --name "privatelink.azurewebsites.net"

