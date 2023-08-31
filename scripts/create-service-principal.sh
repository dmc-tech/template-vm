#!/bin/bash

# This script requires Azure CLI version 2.25.0 or later. Check version with `az --version`.

while getopts e: option
do
  case "${option}"
  in
    e) SUB_ENV=${OPTARG};;
  esac
done

if [ ${#SUB_ENV} == 0  ]
then
  echo "Please select a Subscription environment using -e flag."
  exit 1
fi
RES_SUB_ID=$(az account list --query "[?ends_with(name,'-$SUB_ENV')].tenantId" -o tsv) # Resource Sub Subscription name
if [ -z ${RES_SUB_ID+x} ]
then
    echo "Subscription for the environment not found. Correct options are:"
    echo "Dev"
  exit 1
fi

create_AadSpn () {
    SERVICE_PRINCIPAL_NAME=$1
    PASSWORD=$(az ad sp create-for-rbac --name $SERVICE_PRINCIPAL_NAME --query "password" --output tsv)
    USER_NAME=$(az ad sp list --display-name $SERVICE_PRINCIPAL_NAME --query "[].appId" --output tsv)
    echo "Service Principal Name:       : $SERVICE_PRINCIPAL_NAME "
    echo "Service principal ID:         : $USER_NAME"
    echo "Service principal password    : $PASSWORD"
    echo "Service principal Tenant ID   : $RES_SUB_ID"

}

PROJECT_NAME=devsecops

ACR_NAME=$(az acr list --query [].name -o tsv)
AKS_NAME=$(az aks list --query [].name -o tsv)

SPN_1="$PROJECT_NAME-to-$ACR_NAME"
SPN_2="$PROJECT_NAME-from-$ACR_NAME-to-$AKS_NAME"

#create_AadSpn $SPN_1
#create_AadSpn $SPN_2

SERVICE_PRINCIPAL_NAME=$SPN_2
echo "Service Principal Name:       : $SERVICE_PRINCIPAL_NAME "
az ad sp list --display-name $SERVICE_PRINCIPAL_NAME #--query "[].appId" --output tsv

