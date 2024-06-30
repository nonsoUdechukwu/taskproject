terraform {
  required_version = ">=1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    
  }
  # backend "azurerm" {
  #   resource_group_name   = "reactspringapp-rg"
  #   storage_account_name  = "reactspringappst"
  #   container_name        = "reactspringappcontainer"
  #   key                   = "terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "main" {
  name = "reactspringapp-rg"
}


resource "azurerm_container_registry" "acr" {
  name                = "${var.nameprefix}acr"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  sku                 = "Standard"
  admin_enabled       = false
}


resource "azurerm_kubernetes_cluster" "k8" {
  name                = "${var.nameprefix}-k8"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  dns_prefix  =  "${var.nameprefix}"
  tags                = {
    Environment = "dev"
  }

  default_node_pool {
    name       = "default"
    vm_size    = "Standard_d2ads_v5"
    node_count = 1
    enable_auto_scaling  = true
    max_count            = 3
    min_count            = 1
    type                 = "VirtualMachineScaleSets"
  }
  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }
  identity {
    type = "SystemAssigned"
  }
}


resource "azurerm_role_assignment" "role_acrpull" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.k8.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}
