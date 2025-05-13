# terragrunt.hcl

# 1) Define any locals you need
locals {
  location = "eastus"
}

# 2) Generate the Terraform configuration (main.tf) with a backend block
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

  # Empty backend block is required so Terragrunt's remote_state works
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
  name     = "ci-demo-resource-group"
  location = var.location
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.ci_demo.name
}
EOF
}

# 3) Configure remote state for Terragrunt
remote_state {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-terragrunt-state"
    storage_account_name = "stterragruntstate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
