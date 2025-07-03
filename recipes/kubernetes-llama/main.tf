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

variable "model_url" {
  default = "https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGUF/resolve/main/llama-2-7b-chat.gguf"
}

variable "model_file_name" {
  default = "llama-2-7b-chat.gguf"
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
          command = ["sh", "-c"]
          args = [
            "curl -L ${var.model_url} -o /models/${var.model_file_name}"
          ]

          volume_mount {
            mount_path = "/models"
            name       = "model-volume"
          }
        }

        container {
          name  = "llama"
          image = "ghcr.io/ggerganov/llama.cpp:server"

          port {
            container_port = 8080
          }

          command = ["./server"]
          args    = ["--model", "/models/${var.model_file_name}"]

          volume_mount {
            mount_path = "/models"
            name       = "model-volume"
          }

          resources {
            limits = {
              memory = "4Gi"
              cpu    = "2000m"
            }
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
      target_port = 8000
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