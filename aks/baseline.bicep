// required parameters
param baseName string
param logAnalyticsWorkspaceResourceId string

// vnet parameters
param vnetName string
param vnetSubnetName string

// acr parameters
param acrName string

// optional parameters
param vnetResourceGroupName string {
  default: resourceGroup().name
}
param acrResourceGroupName string {
  default: resourceGroup().name
}
param kubernetesVersion string {
  default: '1.17.11'
}
param serviceCidr string {
  default: '172.16.0.0/16'
}
param dnsServiceIP string {
  default: '172.16.0.10'
}
param dockerBridgeCidr string {
  default: '172.18.0.1/16'
}
param agentCount int {
  default: 3
}
param agentVmSize string {
  default: 'Standard_DS2_v2'
}
param agentDiskSizeGB int {
  default: 30
}

// variables
var clusterName = 'aks-${baseName}'
var clusterNodeResourceGroup = 'rg-${clusterName}-nodepools'
var clusterVnetSubnetId = concat(resourceId(vnetResourceGroupName, 'Microsoft.Network/virtualNetworks', vnetName), '/subnets/', vnetSubnetName)

// variables from aks cluster
var kubeletIdentityObjectId = aks.properties.identityProfile.kubeletidentity.objectId
var omsAgentIdentityObjectId = aks.properties.addonProfiles.omsagent.identity.objectId

// role definition ids
var monitoringMetricsPublisherRoleDefinitionGuid = '3913510d-42f4-4e42-8a64-420c390055eb'
var acrPullRoleDefinitionGuid = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
var networkContributorRoleDefinitionGuid = '4d97b98b-1d4f-4787-a291-c67834d212e7'
var virtualMachineContributorRoleDefinitionGuid = '9980e02c-c2be-4d73-94e8-173b1dc7cf3c'
var managedIdentityOperatorRoleDefinitionGuid = 'f1a07417-d97a-45cb-824c-7a7467783830'

resource aks 'Microsoft.ContainerService/managedClusters@2020-07-01' = {
  name: clusterName
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
    tier: 'Free'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: baseName
    nodeResourceGroup: clusterNodeResourceGroup
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: 'npdefault'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        count: agentCount
        orchestratorVersion: kubernetesVersion
        osType: 'Linux'
        osDiskSizeGB: agentDiskSizeGB
        vmSize: agentVmSize
        maxPods: 30
        vnetSubnetID: clusterVnetSubnetId
      }
    ]
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
        }
      }
      KubeDashboard: {
        enabled: false
      }
    }
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      loadBalancerSku: 'standard'
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP
      dockerBridgeCidr: dockerBridgeCidr
    }
  }
}

resource aksDiagnosticSettings 'Microsoft.ContainerService/managedClusters/providers/diagnosticSettings@2017-05-01-preview' = {
  name: concat(clusterName, '/Microsoft.Insights/default')
  dependsOn: [
    aks
  ]
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        category: 'kube-controller-manager'
        enabled: true
      }
      {
        category: 'kube-audit-admin'
        enabled: true
      }
      {
        category: 'guard'
        enabled: true
      }
    ]
  }
}

// this role assignment allows OMS Agent to publish metrics to Azure Monitor
resource monitoringMetricsPublisherRoleAssignment 'Microsoft.ContainerService/managedClusters/providers/roleAssignments@2018-09-01-preview' = {
  name: concat(clusterName, '/Microsoft.Authorization/', guid(resourceGroup().id, clusterName, monitoringMetricsPublisherRoleDefinitionGuid))
  properties: {
    roleDefinitionId: concat(subscription().id, '/providers/Microsoft.Authorization/roleDefinitions/', monitoringMetricsPublisherRoleDefinitionGuid)
    principalId: omsAgentIdentityObjectId
  }
}

// required for aad-pod-identity to assign identities from the cluster's resource group
module managedIdentityOperatorRoleAssignment '../auth/rg-role-assignment.bicep' = {
  name: 'ClusterResourceGroupManagedIdentityOperator'
  scope: resourceGroup(clusterNodeResourceGroup)
  params: {
    principalId: kubeletIdentityObjectId
    roleDefinitionGuid: managedIdentityOperatorRoleDefinitionGuid
  }
}

// required for aad-pod-identity to assign identities from the cluster's resource group
module virtualMachineContributorRoleAssignment '../auth/rg-role-assignment.bicep' = {
  name: 'ClusterResourceGroupVirtualMachineContributor'
  scope: resourceGroup(clusterNodeResourceGroup)
  params: {
    principalId: kubeletIdentityObjectId
    roleDefinitionGuid: virtualMachineContributorRoleDefinitionGuid
  }
}

// this role assignment allows AKS to manage ingress controller resources in the virtual network
module vnetContributorRoleAssignment '../auth/subnet-role-assignment.bicep' = {
  name: 'VnetSubnetNetworkContributor'
  scope: resourceGroup(vnetResourceGroupName)
  params: {
    vnetName: vnetName
    principalId: aks.identity.principalId
    roleDefinitionGuid: networkContributorRoleDefinitionGuid
  }
}

// this role assignment allows AKS to pull images from an Azure Container Registry
module acrPullRoleAssignment '../auth/acr-role-assignment.bicep' = {
  name: 'AcrPull'
  scope: resourceGroup(acrResourceGroupName)
  params: {
    acrName: acrName
    principalId: aks.properties.identityProfile.kubeletidentity.objectId
    roleAssignmentName: guid(resourceGroup().id, clusterName, acrPullRoleDefinitionGuid)
    roleDefinitionGuid: acrPullRoleDefinitionGuid
  }
}

output id string = aks.id
