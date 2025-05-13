# terragrunt.hcl
# Place this file at the root of your repository, next to .github/

locals {
  location = "eastus"
}

# Generate a Terraform configuration, including an empty backend block
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

  # Empty backend so Terragrunt's remote_state config is applied
  backend "azurerm" {}
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
  name     = "ci-demo-rg"
  location = var.location
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.ci_demo.name
}
EOF
}

# Tell Terragrunt how to configure remote state
remote_state {
  backend = "azurerm"
  config = {
    resource_group_name   = "rg-terragrunt-state"
    storage_account_name  = "stterragruntstate"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }
}
