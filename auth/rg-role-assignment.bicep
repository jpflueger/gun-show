// required params
param principalId string
param roleDefinitionGuid string

// optional params
param principalType string = 'ServicePrincipal'

// variables
var roleDefinitionId = concat(subscription().id, '/providers/Microsoft.Authorization/roleDefinitions/', roleDefinitionGuid)

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, principalId, roleDefinitionGuid)
  properties: {
    principalId: principalId
    roleDefinitionId: roleDefinitionId
    principalType: principalType
  }
}
