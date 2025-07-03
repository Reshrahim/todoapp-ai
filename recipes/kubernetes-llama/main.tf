terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
}

variable "context" {
  description = "This variable contains Radius recipe context."
  type = any
}

resource "kubernetes_deployment" "llama" {
  metadata {
    name      = "llama"
    namespace = var.context.runtime.kubernetes.namespace
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
        init_container {
          name  = "download-model"
          image = "curlimages/curl:latest"
          command = [
            "sh", "-c",
            <<-EOT
              mkdir -p /models && \
              curl -L -o /models/llama-2-7b-chat.gguf https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGUF/resolve/main/llama-2-7b-chat.gguf
            EOT
          ]

          volume_mount {
            mount_path = "/models"
            name       = "model-volume"
          }
        }

        container {
          name  = "llama"
          image = "ghcr.io/abetlen/llama-cpp-python:latest"

          port {
            container_port = 8080
          }

          resources {
            limits = {
              memory = "2Gi"
              cpu    = "1000m"
            }
          }

          args = ["--model", "/models/llama-2-7b-chat.gguf"]

          volume_mount {
            mount_path = "/models"
            name       = "model-volume"
          }
        }

        volume {
          name = "model-volume"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "llama" {
  metadata {
    name      = "llama-service"
    namespace = var.context.runtime.kubernetes.namespace
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
        llama_endpoint = "http://${kubernetes_service.llama.metadata[0].name}.${kubernetes_service.llama.metadata[0].namespace}.svc.cluster.local:8080"
    }
  }
}