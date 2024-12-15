param location string = 'northeurope'

param name string = 'aks-cluster-fes'

@description('Specifies the object id of an Azure Active Directory user. In general, this the object id of the system administrator who deploys the Azure resources.')
param userId string = '<OBJECT_ID>'

resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-07-02-preview' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: '1.29.9'
    autoUpgradeProfile: {
      upgradeChannel: 'stable'
    }
    azureMonitorProfile: {
      containerInsights: {
        enabled: true
        logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.id
      }
      metrics: {
        enabled: true
      }
    }
    dnsPrefix: 'aks-cluster'
    enableRBAC: true
    addonProfiles: {
      HttpApplicationRouting: {
        enabled: true
      }
    }
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 3
        vmSize: 'Standard_DS2_v2'
        osType: 'Linux'
        mode: 'System'
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        enableAutoScaling: true
        minCount: 1
        maxCount: 3
      }
    ]
    linuxProfile: {
      adminUsername: 'adminUserName'
      ssh: {
        publicKeys: [
          {
            keyData: '<PUBLIC_SSH_KEY>'
          }
        ]
      }
    }
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${name}-log-analytics'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource grafana 'Microsoft.Dashboard/grafana@2023-09-01' = {
  name: '${name}-gr'
  location: location
  sku: {
    name: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    grafanaIntegrations: {
      azureMonitorWorkspaceIntegrations: [
        {
          azureMonitorWorkspaceResourceId: prometheus.id
        }
      ]
    }
    publicNetworkAccess: 'Enabled'
  }
}

resource prometheus 'Microsoft.Monitor/accounts@2023-04-03' = {
  name: '${name}-prometheus'
  location: location
}

resource dataCollectionEndpoint 'Microsoft.Insights/dataCollectionEndpoints@2022-06-01' = {
  name: 'MSProm-${location}-${name}'
  location: location
  kind: 'Linux'
  properties: {
    networkAcls: {
      publicNetworkAccess: 'Enabled'
    }
  }
}

resource dataCollectionRuleAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = {
  name: 'MSProm-${location}-${name}'
  scope: aksCluster
  properties: {
    dataCollectionRuleId: dataCollectionRule.id
    description: 'Association of data collection rule. Deleting this association will break the data collection for this AKS Cluster.'
  }
}

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: 'MSProm-${location}-${name}'
  location: location
  properties: {
    dataCollectionEndpointId: dataCollectionEndpoint.id
    dataSources: {
      prometheusForwarder: [
        {
          name: 'PrometheusDataSource'
          streams: [
            'Microsoft-PrometheusMetrics'
          ]
          labelIncludeFilter: {}
        }
      ]
    }
    destinations: {
      monitoringAccounts: [
        {
          accountResourceId: prometheus.id
          name: 'MonitoringAccount1'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-PrometheusMetrics'
        ]
        destinations: [
          'MonitoringAccount1'
        ]
      }
    ]
  }
}

// Resources
resource mmonitoringReaderRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '43d0d8ad-25c7-4714-9337-8ba259a9fe05'
  scope: subscription()
}

resource monitoringDataReaderRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'b0d8363b-8ddd-447d-831f-62ca05bff136'
  scope: subscription()
}

resource grafanaAdminRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '22926164-76b3-42b3-bc55-97df8dab3e41'
  scope: subscription()
}

// Assign the Monitoring Reader role to the Azure Managed Grafana system-assigned managed identity at the workspace scope
resource monitoringReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name:  guid(name, prometheus.name, mmonitoringReaderRole.id)
  scope: prometheus
  properties: {
    roleDefinitionId: mmonitoringReaderRole.id
    principalId: grafana.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Assign the Monitoring Data Reader role to the Azure Managed Grafana system-assigned managed identity at the workspace scope
resource monitoringDataReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name:  guid(name, prometheus.name, monitoringDataReaderRole.id)
  scope: prometheus
  properties: {
    roleDefinitionId: monitoringDataReaderRole.id
    principalId: grafana.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Assign the Grafana Admin role to the AKS admin group at the resource scope
resource grafanaAdminRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(userId)) {
  name:  guid(name, userId, grafanaAdminRole.id)
  scope: grafana
  properties: {
    roleDefinitionId: grafanaAdminRole.id
    principalId: userId
    principalType: 'User'
  }
}

