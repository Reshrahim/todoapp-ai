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
    }
    connections: {
      ai: {
        source: ai.id
      }
    }
  }
}

resource ai 'Radius.Resources/aiModels@2025-07-14-preview' = {
  name: 'ai'
  properties: {
    application: todolist.id
    environment: environment
    model:'tinyllama'
  }
}
