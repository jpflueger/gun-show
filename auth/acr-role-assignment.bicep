param acrName string
param roleDefinitionGuid string
param principalId string
param roleAssignmentName string

var acrPullRoleDefinitionId = concat(subscription().id, '/providers/Microsoft.Authorization/roleDefinitions/', roleDefinitionGuid)

resource acrRoleAssignment 'Microsoft.ContainerRegistry/registries/providers/roleAssignments@2018-09-01-preview' = {
  name: concat(acrName, '/Microsoft.Authorization/', roleAssignmentName)
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: principalId
  }
}
