name: Terragrunt CI/CD

on:
  push:
    branches:
      - main
      - 'feature/**'
  pull_request:
    types: [opened, synchronize, reopened]
  workflow_dispatch:

jobs:
  terragrunt-plan:
    name: Terragrunt Plan
    runs-on: ubuntu-latest
    env:
      # For Terraform backend auth
      ARM_CLIENT_ID:       ${{ fromJson(secrets.AZURE_CREDENTIALS).clientId }}
      ARM_CLIENT_SECRET:   ${{ fromJson(secrets.AZURE_CREDENTIALS).clientSecret }}
      ARM_SUBSCRIPTION_ID: ${{ fromJson(secrets.AZURE_CREDENTIALS).subscriptionId }}
      ARM_TENANT_ID:       ${{ fromJson(secrets.AZURE_CREDENTIALS).tenantId }}
      TF_IN_AUTOMATION: true

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Azure Login (for CLI)
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Prepare remote-state backend
        run: |
          az group create \
            --name rg-terragrunt-state \
            --location eastus
          az storage account create \
            --name stterragruntstate \
            --resource-group rg-terragrunt-state \
            --sku Standard_LRS
          az storage container create \
            --name tfstate \
            --account-name stterragruntstate

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: '1.5.0'

      - name: Install Terragrunt
        run: |
          curl -LO https://github.com/gruntwork-io/terragrunt/releases/download/v0.45.8/terragrunt_linux_amd64
          chmod +x terragrunt_linux_amd64
          sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt

      - name: Terragrunt Init
        run: terragrunt init -input=false

      - name: Terragrunt Validate
        run: terragrunt validate

      - name: Terragrunt Plan
        run: terragrunt plan -out=tfplan

      - name: Upload Terraform plan
        uses: actions/upload-artifact@v4
        with:
          name: tfplan
          path: tfplan

  terragrunt-apply:
    name: Terragrunt Apply
    needs: terragrunt-plan
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
    env:
      ARM_CLIENT_ID:       ${{ fromJson(secrets.AZURE_CREDENTIALS).clientId }}
      ARM_CLIENT_SECRET:   ${{ fromJson(secrets.AZURE_CREDENTIALS).clientSecret }}
      ARM_SUBSCRIPTION_ID: ${{ fromJson(secrets.AZURE_CREDENTIALS).subscriptionId }}
      ARM_TENANT_ID:       ${{ fromJson(secrets.AZURE_CREDENTIALS).tenantId }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Azure Login (for CLI)
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: '1.5.0'

      - name: Install Terragrunt
        run: |
          curl -LO https://github.com/gruntwork-io/terragrunt/releases/download/v0.45.8/terragrunt_linux_amd64
          chmod +x terragrunt_linux_amd64
          sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt

      - name: Download Terraform plan
        uses: actions/download-artifact@v4
        with:
          name: tfplan
          path: .

      - name: Terragrunt Apply
        run: terragrunt apply -auto-approve tfplan
