param baseName string

param retentionInDays int {
  default: 30
}
param skuName string {
  default: 'PerGB2018'
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: 'log-${baseName}-${guid(resourceGroup().id, baseName)}'
  location: resourceGroup().location
  properties: {
    retentionInDays: retentionInDays
    sku: {
      name: skuName
    }
  }
  //TODO: add prometheus queries as sub-resources
}

output id string = logAnalyticsWorkspace.id
