@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param resourceBaseName string = uniqueString(resourceGroup().id)

// See https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage
var storageBlobDataOwnerRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')
var storageQueueDataContributorDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '974c5e8b-45b9-4653-ba55-5f855dd0fb88')
var ownerRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'log-${resourceBaseName}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: 'ai-${resourceBaseName}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: 'str${resourceBaseName}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource azureFunctionPlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: 'plan-${resourceBaseName}'
  location: location
  kind: 'functionapp'
  sku: {
    tier: 'Dynamic'
    name: 'Y1'
    size: 'Y1'
    family: 'Y'
  }
}

resource azureFunction 'Microsoft.Web/sites@2021-02-01' = {
  name: 'func-${resourceBaseName}'
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    siteConfig: {
      localMySqlEnabled: false
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccount.name
        }
        {
          name: 'MyBlobStorage__serviceUri'
          value: storageAccount.properties.primaryEndpoints.blob
        }

        // The WEBSITE_CONTENTAZUREFILECONNECTIONSTRING value seems to require a full Azure Storage connection string. I haven't
        // yet figured out if there is a way to get WEBSITE_CONTENTAZUREFILECONNECTIONSTRING to use managed identity.
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
      ]
    }
  }

  resource config 'config' = {
    name: 'web'
    properties: {
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      detailedErrorLoggingEnabled: true
      httpLoggingEnabled: true
      requestTracingEnabled: true
      remoteDebuggingEnabled: false
    }
  }
}

resource roleAssignmentStorageBlobDataOwner 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  scope: storageAccount
  name: guid(resourceGroup().id, storageBlobDataOwnerRoleDefinitionId)
  properties: {
    roleDefinitionId: storageBlobDataOwnerRoleDefinitionId
    principalId: azureFunction.identity.principalId
  }
}

resource roleAssignmentStorageQueueDataContributor 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  scope: storageAccount
  name: guid(resourceGroup().id, storageQueueDataContributorDefinitionId)
  properties: {
    roleDefinitionId: storageQueueDataContributorDefinitionId
    principalId: azureFunction.identity.principalId
  }
}

resource roleAssignmentOwner 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  scope: storageAccount
  name: guid(resourceGroup().id, ownerRoleDefinitionId)
  properties: {
    roleDefinitionId: ownerRoleDefinitionId
    principalId: azureFunction.identity.principalId
  }
}

output functionName string = azureFunction.name
