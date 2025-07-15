extension radius

resource azure 'Applications.Core/environments@2023-10-01-preview' = {
  name: 'azure'
  properties: {
    compute: {
      kind: 'kubernetes'
      namespace: 'azure'
    }
    providers: {
      azure: {
        // Update subscription and resource group
        scope: '/subscriptions/<subscription-id>/resourceGroups/<resource-group-name>'
      }
    }
    recipes: {

      'Radius.Resources/aiModels': {
        default: {
          templateKind: 'terraform'
          templatePath: 'git::https://github.com/reshrahim/todoapp-ai.git//recipes/azure-openai'
          parameters: {
            // Update resource group name
            resource_group_name: '<resource-group-name>'
            location: 'eastus'
          }
        }
      }
    }
  }
}
