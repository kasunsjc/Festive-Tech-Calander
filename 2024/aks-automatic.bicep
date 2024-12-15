@description('Name of the AKS Cluster')
param aksClusterName string = 'aks-automatic'

param location string = resourceGroup().location

resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-03-02-preview' = {
  name: aksClusterName
  location: location
  sku: {
    name: 'Automatic'
    tier: 'Standard'
  }
  properties: {
    agentPoolProfiles: [
      {
        name: 'system'
        count: 3
        vmSize: 'Standard_D2s_v3'
        osDiskSizeGB: 30
        osDiskType: 'ephemeral'
        osType: 'Linux'
        mode: 'System'
      }
    ]  }
  identity: {
    type: 'SystemAssigned'
  }
}
