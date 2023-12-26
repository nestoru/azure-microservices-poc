terraform {
  backend "azurerm" {
    resource_group_name   = "devops-microservices"
    storage_account_name  = "devopsmicroservices"
    container_name        = "tfstate"
    key                   = "prod.terraform.tfstate"
  }
}
