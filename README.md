# Azure DevOps Pipeline Documentation

This document outlines the two Azure DevOps pipelines provided in the YAML configuration files. The first pipeline focuses on deploying Azure resources, and the second pipeline builds and deploys backend and frontend applications to an AKS (Azure Kubernetes Service) cluster.

## Pipeline 1: Deploy Azure Resources

### Pipeline Trigger
This pipeline does not have any triggers defined, meaning it needs to be manually started.

### Pool
The pipeline runs on the `ubuntu-latest` VM image.

### Variables
Variables are imported from an external file `variables.yml`.

### Stages

#### Stage: Deploy_Azure_Resources
- **Display Name:** Deploy_Azure_Resources
- **Jobs:**
  - **Job:** Deploy_Azure_Resources
    - **Steps:**
      1. **Checkout:**
         - Check out the repository to the agent.
      2. **Debug Checkout:**
         - Display the directory contents of the working directory using a PowerShell script.
      3. **Create Resource Group:**
         - Use the Azure CLI to check if a resource group exists. If not, create a new resource group.
      4. **Create Storage Account:**
         - Use the Azure CLI to create a storage account and container. If they already exist, output a message indicating their existence.
      5. **Display Directory:**
         - Display the current working directory and its contents using a Bash script.
      6. **Install Python:**
         - Install Python version 3.x.
      7. **Install Terraform:**
         - Install Terraform version 1.0.11.
      8. **Terraform Init:**
         - Initialize Terraform with the Azure backend.
      9. **Terraform Plan:**
         - Run `terraform plan` to create an execution plan.
      10. **Terraform Apply:**
          - Apply the Terraform plan to deploy the infrastructure.

### Detailed Steps for Deploy_Azure_Resources Job

1. **Checkout:**
   - Command: `checkout: self`
   - Description: Checks out the repository to the build agent.

2. **Debug Checkout:**
   - Command: `pwsh`
   - Script:
     ```powershell
     Get-ChildItem $(System.DefaultWorkingDirectory) -Recurse
     ```
   - Description: Lists all files and directories recursively in the working directory.

3. **Create Resource Group:**
   - Command: `AzureCLI@2`
   - Script:
     ```bash
     if ! az group show --name $(rg_name); then
       az group create --name $(rg_name) --location $(location)
     else
       echo "Resource group $(rg_name) already exists."
     fi
     ```
   - Description: Checks if the resource group exists, and creates it if it doesn't.

4. **Create Storage Account:**
   - Command: `AzureCLI@2`
   - Script:
     ```bash
     az storage account create --resource-group $(rg_name) --name "$(st_name)" --sku Standard_LRS --encryption-services blob
     az storage container create --name $(st_container) --account-name "$(st_name)" --auth-mode login

     if ! az storage account show --name "$(st_name)" --resource-group $(rg_name); then
       az storage account create --resource-group $(rg_name) --name "$(st_name)" --sku Standard_LRS --encryption-services blob
     else
       echo "Storage account $(st_name) already exists."
     fi

     if ! az storage container show --name $(st_container)  --account-name "$(st_name)"; then
       az storage container create --name $(st_container)  --account-name "$(st_name)" --auth-mode login
     else
       echo "Storage container $(st_container)  already exists."
     fi
     ```
   - Description: Creates the storage account and container if they don't already exist.

5. **Display Directory:**
   - Command: `Bash@3`
   - Script:
     ```bash
     echo "Working Directory"
     pwd
     ls -la
     ```
   - Description: Displays the current working directory and its contents.

6. **Install Python:**
   - Command: `UsePythonVersion@0`
   - Inputs: `versionSpec: '3.x', addToPath: true`
   - Description: Installs Python version 3.x and adds it to the PATH.

7. **Install Terraform:**
   - Command: `TerraformInstaller@0`
   - Inputs: `terraformVersion: '1.0.11'`
   - Description: Installs Terraform version 1.0.11.

8. **Terraform Init:**
   - Command: `TerraformTaskV4@4`
   - Inputs:
     ```yaml
     provider: 'azurerm'
     command: 'init'
     workingDirectory: '$(System.DefaultWorkingDirectory)/infra'
     backendServiceArm: $(serviceconnection)
     ensureBackend: true
     backendAzureRmResourceGroupName: $(rg_name)
     backendAzureRmStorageAccountName: $(st_name)
     backendAzureRmContainerName: $(st_container)
     backendAzureRmKey: $(tfstateFile)
     ```
   - Description: Initializes Terraform with the Azure backend.

9. **Terraform Plan:**
   - Command: `TerraformTaskV4@4`
   - Inputs:
     ```yaml
     provider: 'azurerm'
     command: 'plan'
     workingDirectory: '$(System.DefaultWorkingDirectory)/infra'
     environmentServiceNameAzureRM: $(serviceconnection)
     ```
   - Description: Runs `terraform plan` to create an execution plan.

10. **Terraform Apply:**
    - Command: `TerraformTaskV4@4`
    - Inputs:
      ```yaml
      provider: 'azurerm'
      command: 'apply'
      workingDirectory: '$(System.DefaultWorkingDirectory)/infra'
      environmentServiceNameAzureRM: $(serviceconnection)
      ```
    - Description: Applies the Terraform plan to deploy the infrastructure.

## Pipeline 2: Build and Deploy Applications

### Pipeline Trigger
This pipeline does not have any triggers defined, meaning it needs to be manually started.

### Pool
The pipeline runs on the `ubuntu-latest` VM image.

### Variables
Variables are imported from an external file `variables.yml` and a variable group `appidcred`.

### Stages

#### Stage: BuildBackend
- **Display Name:** Build and Push Backend
- **Jobs:**
  - **Job:** Build
    - **Display Name:** Build Backend Docker Image
    - **Steps:**
      1. **Checkout:**
         - Check out the repository to the agent.
      2. **Build and Push Backend Image:**
         - Use Docker to build and push the backend image to Azure Container Registry.

#### Stage: BuildFrontend
- **Display Name:** Build and Push Frontend
- **Depends On:** BuildBackend
- **Jobs:**
  - **Job:** Build
    - **Display Name:** Build Frontend Docker Image
    - **Steps:**
      1. **Checkout:**
         - Check out the repository to the agent.
      2. **Build and Push Frontend Image:**
         - Use Docker to build and push the frontend image to Azure Container Registry.

#### Stage: DeployApplication
- **Display Name:** Deploy Application
- **Jobs:**
  - **Job:** Deploy
    - **Display Name:** Deploy Apps to AKS
    - **Steps:**
      1. **Install Kubectl:**
         - Install the latest version of kubectl.
      2. **Deploy Kubernetes Manifests:**
         - Deploy the Kubernetes manifests to the AKS cluster.
      3. **Deploy Prometheus and Grafana:**
         - Use Azure CLI and Helm to deploy Prometheus and Grafana to the AKS cluster.

### Detailed Steps for BuildBackend Job

1. **Checkout:**
   - Command: `checkout: self`
   - Description: Checks out the repository to the build agent.

2. **Build and Push Backend Image:**
   - Command: `Docker@2`
   - Inputs:
     ```yaml
     command: 'buildAndPush'
     repository: '$(ACR_NAME).azurecr.io/$(BACKEND_IMAGE_NAME)'
     dockerfile: '$(System.DefaultWorkingDirectory)/apps/backendDockerfile'
     containerRegistry: '$(dockerRegistryServiceConnection)'
     tags: |
       latest
     ```
   - Description: Builds and pushes the backend Docker image to Azure Container Registry.

### Detailed Steps for BuildFrontend Job

1. **Checkout:**
   - Command: `checkout: self`
   - Description: Checks out the repository to the build agent.

2. **Build and Push Frontend Image:**
   - Command: `Docker@2`
   - Inputs:
     ```yaml
     command: 'buildAndPush'
     repository: '$(ACR_NAME).azurecr.io/$(FRONTEND_IMAGE_NAME)'
     dockerfile: '$(System.DefaultWorkingDirectory)/apps/frontendDockerfile'
     containerRegistry: '$(dockerRegistryServiceConnection)'
     tags: |
       latest
     ```
   - Description: Builds and pushes the frontend Docker image to Azure Container Registry.

### Detailed Steps for DeployApplication Job

1. **Install Kubectl:**
   - Command: `KubectlInstaller@0`
   - Inputs: `kubectlVersion: 'latest'`
   - Description: Installs the latest version of kubectl.

2. **Deploy Kubernetes Manifests:**
   - Command: `KubernetesManifest@1`
   - Inputs:
     ```yaml
     action: 'deploy'
     connectionType: 'azureResourceManager'
    
