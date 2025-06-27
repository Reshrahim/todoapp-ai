extension radius

extension radiusResources

param environment string

resource todolist 'Applications.Core/applications@2023-10-01-preview' = {
  name: 'todolist'
  properties: {
    environment: environment
  }
}

resource frontend 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'frontend'
  properties: {
    application: todolist.id
    environment: environment
    container: {
      image: 'ghcr.io/reshrahim/todoapp-ai:latest'
      ports: {
        http: {
          containerPort: 3000
        }
      }
      env: {
        CONNECTION_AI_REGION: {
          value: feedbackai.properties.region
        }
        CONNECTION_AI_MODEL: {
          value: feedbackai.properties.model
        }
      }     
    }
  }
}

resource feedbackai 'Radius.Resources/feedbackAI@2023-10-01-preview' = {
  name: 'feedbackai'
  properties: {
    application: todolist.id
    environment: environment
  }
}
