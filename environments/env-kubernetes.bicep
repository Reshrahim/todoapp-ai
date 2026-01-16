extension radius

resource local 'Applications.Core/environments@2023-10-01-preview' = {
  name: 'local'
  properties: {
    compute: {
      kind: 'kubernetes'
      namespace: 'local'
    }
    recipes: {
      'Radius.Resources/aiModels': {
        default: {
          templateKind: 'terraform'
          templatePath: 'git::https://github.com/reshrahim/todoapp-ai.git//recipes/kubernetes-llama'
        }
      }
    }
  }
}
