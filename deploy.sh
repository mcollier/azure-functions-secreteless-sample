#!/bin/bash

LOCATION=eastus
RESOURCE_GROUP_NAME=[YOUR-RESOURCE-GROUP-NAME]
DEPLOYMENT_NAME=Deployment-$(date +"%Y-%m-%d_%H%M%S")

az group create \
    --location $LOCATION \
    --name "$RESOURCE_GROUP_NAME"

az deployment group create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$DEPLOYMENT_NAME" \
    --template-file ".\main.bicep" \
    --confirm-with-what-if

FUNCTION_NAME=$(az deployment group show --name "$DEPLOYMENT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query properties.outputs.functionName.value -o tsv)

cd ./src || exit
func azure functionapp publish "$FUNCTION_NAME"