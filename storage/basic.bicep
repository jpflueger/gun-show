param baseName string

param sku string {
  default: 'Standard_LRS'
}

resource stg 'Microsoft.Storage/storageAccounts@2020-08-01-preview' = {
  name: 'st${baseName}'
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: sku
  }
  properties: {
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      //TODO: create keyvault module with encryption keys
      // keySource: 'Microsoft.Keyvault'
      // keyvaultproperties: {
      //   keyvaulturi: ''
      //   keyname: ''
      //   keyversion: ''
      // }
    }
  }
}

output id string = stg.id
