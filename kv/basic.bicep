param baseName string

resource kv 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: 'kv-${baseName}'
  location: resourceGroup().location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: [
    ]
  }
}

output id string = kv.id
