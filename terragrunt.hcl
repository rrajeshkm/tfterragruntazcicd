# terragrunt.hcl

# You can tweak the location here if desired
locals {
  location = "eastus"
}

# Generate a Terraform file with provider, RG resource, variables & outputs
generate "main_tf" {
  path      = "main.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "azurerm" {
  features {}
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "${local.location}"
}

resource "azurerm_resource_group" "ci_demo" {
  name     = "ci-demo-resource-group"
  location = var.location
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.ci_demo.name
}
EOF
}

# (Optional) configure remote state for this repo
remote_state {
  backend = "azurerm"
  config = {
    resource_group_name   = "rg-terragrunt-state"
    storage_account_name  = "stterragruntstate"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }
}
