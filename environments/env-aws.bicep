extension radius

resource aws 'Applications.Core/environments@2023-10-01-preview' = {
  name: 'aws'
  properties: {
    compute: {
      kind: 'kubernetes'
      namespace: 'aws'
    }
    providers: {
      aws: {
        // Update account id and region
        scope: '/planes/aws/aws/accounts/<account-id>/regions/<region>'
      }
    }
    recipes: {
      'Radius.Resources/aiModels': {
        default: {
          templateKind: 'terraform'
          templatePath: 'git::https://github.com/reshrahim/todoapp-ai.git//recipes/aws-bedrock'
        }
      }
    }
  }
}
