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
        // Update AWS account ID and region
        scope: '/aws/accounts/<aws-account-id>/regions/<aws-region>'
      }
    }
    recipes: {
      'Radius.Resources/feedbackAI': {
        default: {
          templateKind: 'terraform'
          templatePath: 'git::https://github.com/reshrahim/todoapp-ai.git//recipes/aws-bedrock'
        }
      }
    }
  }
}
