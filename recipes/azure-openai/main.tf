terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75.0"
    }
  }
}

variable "location" {
  type    = string
}

variable "resource_group_name" {
  type = string
}

variable "context" {
  description = "This variable contains Radius recipe context."
  type = any
}

locals {
   uniqueName = var.context.resource.name
}

resource "azurerm_cognitive_account" "openai" {
  name                = local.uniqueName
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "OpenAI"
  sku_name            = "S0"
}

resource "azurerm_cognitive_deployment" "gpt-5-nano" {
    name = var.context.resource.properties.model
    cognitive_account_id = azurerm_cognitive_account.openai.id
    model {
        format = "OpenAI"
        name = var.context.resource.properties.model
        version= "2025-08-07"
      }
    rai_policy_name        = "Microsoft.Default"
    version_upgrade_option = "OnceNewDefaultVersionAvailable"  
    sku {
      name     = "GlobalStandard"
      capacity = "10"
    }
  }

output "result" {
  value = {
    values = {
      apiVersion = "2024-10-21"
      endpoint   = azurerm_cognitive_account.openai.endpoint
      model = var.context.resource.properties.model
    }
    # Warning: sensitive output
    secrets = {
      apiKey = azurerm_cognitive_account.openai.primary_access_key
    }
  }
  sensitive = true
}
