terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "k3d-llama-cluster"
}

resource "kubernetes_namespace" "llama" {
  metadata {
    name = "llama"
  }
}

resource "kubernetes_persistent_volume" "llama_model" {
  metadata {
    name = "llama-model-pv"
  }
  spec {
    capacity = {
      storage = "1Gi"
    }
    access_modes = ["ReadOnlyMany"]
    persistent_volume_source {
      host_path {
        path = "/Users/YOUR_USERNAME/models" # <-- update this to your local path
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "llama_model" {
  metadata {
    name      = "llama-model-pvc"
    namespace = kubernetes_namespace.llama.metadata[0].name
  }
  spec {
    access_modes = ["ReadOnlyMany"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
    volume_name = kubernetes_persistent_volume.llama_model.metadata[0].name
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
          command = ["bash", "-c"]
          args = ["./server -m /models/llama-2-7b-chat.gguf -c 2048 --port 8080"]

          port {
            container_port = 8080
          }

          volume_mount {
            mount_path = "/models"
            name       = "llama-model"
          }

          resources {
            limits = {
              memory = "4Gi"
              cpu    = "2000m"
            }
          }
        }

        volume {
          name = "llama-model"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.llama_model.metadata[0].name
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

    type = "LoadBalancer"
  }
}

output "result" {
  value = {
    values = {
        llama_endpoint = "http://${kubernetes_service.llama.metadata[0].name}.${kubernetes_namespace.llama.metadata[0].name}.svc.cluster.local:8080"
    }
  }
}