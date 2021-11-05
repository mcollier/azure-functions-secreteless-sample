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

# NOTE - Azure Functions Core Tools publishing currently is not working when setting 'AzureWebJobsStorage__accountName'.
#        Error message is: "'app-name' app is missing AzureWebJobsStorage app setting. That setting is required for publishing consumption linux apps."
#
#        Publishing from Visual Studio Code does work.

# FUNCTION_NAME=$(az deployment group show --name "$DEPLOYMENT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query properties.outputs.functionName.value -o tsv)

# cd ./src || exit
# func azure functionapp publish "$FUNCTION_NAME"