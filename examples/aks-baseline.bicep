param baseName string

param vnetAddressSpace string = '10.240.0.0/16'
param subnetAddressPrefix string = '10.240.0.0/22'

module law '../insights/basic-la-workspace.bicep' = {
  name: 'law'
  params: {
    baseName: baseName
  }
}

module acr '../acr/basic.bicep' = {
  name: 'acr'
  params: {
    baseName: baseName
    logAnalyticsWorkspaceResourceId: law.outputs.id
  }
}

module vnet '../vnet/single-subnet.bicep' = {
  name: 'vnet'
  params: {
    baseName: baseName
    logAnalyticsWorkspaceResourceId: law.outputs.id
    vnetAddressSpace: vnetAddressSpace
    subnetAddressPrefix: subnetAddressPrefix
  }
}

module aks '../aks/baseline.bicep' = {
  name: 'aks'
  dependsOn: [
    law
    acr
    vnet
  ]
  params: {
    baseName: baseName
    acrName: acr.outputs.name
    logAnalyticsWorkspaceResourceId: law.outputs.id
    vnetName: vnet.outputs.name
    vnetSubnetName: vnet.outputs.subnetName
  }
}
