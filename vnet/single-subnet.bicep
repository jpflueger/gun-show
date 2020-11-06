param baseName string
param logAnalyticsWorkspaceResourceId string

param vnetAddressSpace string = '10.240.0.0/16'
param subnetAddressPrefix string = '10.240.0.0/22'

param vnetSubnetName string {
  default: 'default'
}

var vnetName = 'vnet-${baseName}'

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
    subnets: [
      {
        name: vnetSubnetName
        properties: {
          addressPrefix: subnetAddressPrefix
        }
      }
    ]
  }
}

resource vnetDiagnosticSettings 'Microsoft.Network/virtualNetworks/providers/diagnosticSettings@2017-05-01-preview' = {
  name: concat(vnetName, '/Microsoft.Insights/default')
  dependsOn: [
    vnet
  ]
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output name string = vnetName
output subnetName string = vnetSubnetName
