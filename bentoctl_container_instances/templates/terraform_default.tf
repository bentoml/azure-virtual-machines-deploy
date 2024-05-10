terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.97.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

################################################################################
# Input variable definitions
################################################################################


variable "deployment_name" {
  description = "Name of the deployment."
  type        = string
}

variable "image_tag" {
  description = "full image gcr image tag"
  type        = string
}

variable "image_repository" {
  description = "gcr repository name"
  type        = string
}

variable "image_version" {
  description = "gcr image version"
  type        = string
}

variable "resource_group" {
  description = "Azure resource group into which resource will be created"
}

variable "acr_name" {
  description = "The container registry which has the image."
}

variable "cpu" {
  type        = string
  description = "The required number of CPU cores of the containers."
}

variable "memory" {
  type        = string
  description = "The required memory of the containers in GB."
}

variable "bentoml_port" {
  type        = string
  description = "public port to expose bentoml service."
}

################################################################################
# Resource definitions
################################################################################

data "azurerm_resource_group" "rg" {
  name = var.resource_group
}

data "azurerm_container_registry" "registry" {
  name                = var.acr_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_container_group" "bentoml" {
  name                = var.deployment_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  ip_address_type     = "public"
  os_type             = "Linux"
  exposed_port {
    port     = var.bentoml_port
    protocol = "TCP"
  }

  image_registry_credential {
    server   = data.azurerm_container_registry.registry.login_server
    username = data.azurerm_container_registry.registry.admin_username
    password = data.azurerm_container_registry.registry.admin_password
  }

  #environment_variables {
  #  BENTOMLPORT = "3000"
  #}
  
  container {
    name   = "bentoml"
    image  = var.image_tag
    cpu    = var.cpu
    memory = var.memory

    ports {
      port     = var.bentoml_port
      protocol = "TCP"
    }
  }
}

################################################################################
# Output value definitions
################################################################################

output "resource_group_name" {
  value = data.azurerm_resource_group.rg.name
}

output "endpoint" {
  value = "http://${azurerm_container_group.bentoml.ip_address}:{var.bentoml_port}"
}
