param vnetName string
param roleDefinitionGuid string
param principalId string

var roleDefinitionId = concat(subscription().id, '/providers/Microsoft.Authorization/roleDefinitions/', roleDefinitionGuid)

// this role assignment allows AKS to manage ingress controller resources in the virtual network
resource vnetContributorRoleAssignment 'Microsoft.Network/virtualNetworks/providers/roleAssignments@2018-09-01-preview' = {
  name: concat(vnetName, '/Microsoft.Authorization/', guid(resourceGroup().id, vnetName, roleDefinitionId))
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
  }
}
