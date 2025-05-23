// Assigns the necessary roles to the AI project

@description('Name of the cosmos DB account')
param cosmosAccountName string


@description('Principal ID of the AI project')
param aiProjectPrincipalId string

@description('Resource ID of the AI project')
param aiProjectId string

param projectWorkspaceId string

var userThreadName = '${projectWorkspaceId}-thread-message-store'
var systemThreadName = '${projectWorkspaceId}-system-thread-message-store'
var agentEntityStoreName = '${projectWorkspaceId}-agent-entity-store'


#disable-next-line BCP081
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2025-01-01-preview' existing = {
  name: cosmosAccountName
  scope: resourceGroup()
}

// Reference existing database
#disable-next-line BCP081
resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2025-01-01-preview' existing = {
  parent: cosmosAccount
  name: 'enterprise_memory'
}

#disable-next-line BCP081
resource containerUserMessageStore  'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2025-01-01-preview' existing = {
  parent: database
  name: userThreadName
}

#disable-next-line BCP081
resource containerSystemMessageStore 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2025-01-01-preview' existing = {
  parent: database
  name: systemThreadName
}

#disable-next-line BCP081
resource containerAgentEntityStore 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-12-01-preview' existing = {
  parent: database
  name: agentEntityStoreName
}

var roleDefinitionId = resourceId(
  'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions',
  cosmosAccountName,
  '00000000-0000-0000-0000-000000000002'
)

var scopeSystemContainer = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccountName}/dbs/enterprise_memory/colls/${systemThreadName}'
var scopeUserContainer = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccountName}/dbs/enterprise_memory/colls/${userThreadName}'
var scopeAgentEntityContainer = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccountName}/dbs/enterprise_memory/colls/${agentEntityStoreName}'

resource containerRoleAssignmentUserContainer 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-05-15' = {
  parent: cosmosAccount
  name: guid(aiProjectId, containerUserMessageStore.id, roleDefinitionId)
  properties: {
    principalId: aiProjectPrincipalId
    roleDefinitionId: roleDefinitionId
    scope: scopeUserContainer
  }
}

resource containerRoleAssignmentSystemContainer 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-05-15' = {
  parent: cosmosAccount
  name: guid(aiProjectId, containerSystemMessageStore.id, roleDefinitionId)
  properties: {
    principalId: aiProjectPrincipalId
    roleDefinitionId: roleDefinitionId
    scope: scopeSystemContainer
  }
}

resource containerRoleAssignmentAgentEntityContainer 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-05-15' = {
  parent: cosmosAccount
  name: guid(aiProjectId, containerAgentEntityStore.id, roleDefinitionId)
  properties: {
    principalId: aiProjectPrincipalId
    roleDefinitionId: roleDefinitionId
    scope: scopeAgentEntityContainer
  }
}
