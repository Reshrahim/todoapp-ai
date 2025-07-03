terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
}

resource "kubernetes_namespace" "llama" {
  metadata {
    name = "llama"
  }
}

resource "kubernetes_deployment" "llama" {
  metadata {
    name      = "llama"
    namespace = kubernetes_namespace.llama.metadata[0].name
    labels = {
      app = "llama"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "llama"
      }
    }

    template {
      metadata {
        labels = {
          app = "llama"
        }
      }

      spec {
        container {
          name  = "llama"
          image = "ghcr.io/ggerganov/llama.cpp:latest"

          port {
            container_port = 8080
          }

          resources {
            limits = {
              memory = "2Gi"
              cpu    = "1000m"
            }
          }

          command = ["bash", "-c"]
          args = ["./main -m /models/llama-2-7b-chat.gguf -p 'Hello from Terraform!'"]

          volume_mount {
            mount_path = "/models"
            name       = "model-volume"
          }
        }

        volume {
          name = "model-volume"

          host_path {
            path = "/path/on/host/to/model"
            type = "Directory"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "llama" {
  metadata {
    name      = "llama-service"
    namespace = kubernetes_namespace.llama.metadata[0].name
  }

  spec {
    selector = {
      app = "llama"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "ClusterIP"
  }
}


output "result" {
  value = {
    values = {
        llama_endpoint = "http://${kubernetes_service.llama.metadata[0].name}.${kubernetes_namespace.llama.metadata[0].name}.svc.cluster.local:8080"
    }
  }
}