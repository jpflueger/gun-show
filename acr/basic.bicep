param baseName string
param logAnalyticsWorkspaceResourceId string

var acrName = 'acr${baseName}'

resource acr 'Microsoft.ContainerRegistry/registries@2019-12-01-preview' = {
  name: acrName
  location: resourceGroup().location
  sku: {
    name: 'Basic'
  }
}

resource acrDiagnosticSettings 'Microsoft.ContainerRegistry/registries/providers/diagnosticSettings@2017-05-01-preview' = {
  name: concat(acrName, '/Microsoft.Insights/default')
  dependsOn: [
    acr
  ]
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    metrics: [
      {
        timeGrain: 'PT1M'
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        category: 'ContainerRegistryRepositoryEvents'
        enabled: true
      }
      {
        category: 'ContainerRegistryLoginEvents'
        enabled: true
      }
    ]
  }
}

output id string = acr.id
output name string = acrName
