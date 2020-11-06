param baseName string
param workspaceResourceId string

resource appi 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: 'appi-${baseName}'
  location: resourceGroup().location
  kind: 'web'
  properties: {
    WorkspaceResourceId: workspaceResourceId
    Application_Type: 'web'
  }
}

output id string = appi.id
