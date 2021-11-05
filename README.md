:construction: This repo is a work in progress! :construction:

## Deployment

1. Use the included deploy.sh script to create a resource group and deploy the Bicep file.
1. Use Visual Studio Code to publish the sample app.

> Azure Functions Core Tools publishing currently is not working when setting _AzureWebJobsStorage__accountName_.  Attempts to use `func azure functionapp publish <APP-NAME>` result in the following error message:
"'APP-NAME' app is missing AzureWebJobsStorage app setting. That setting is required for publishing consumption linux apps."
