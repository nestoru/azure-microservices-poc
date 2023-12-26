# Define provider (Azure).
provider "azurerm" {
  features {}
   client_secret   = file("credentials.json")
}

# Use modules.
# storage module not needed because the backend state is persisted in a bucket already (see backend.tf)

module "network" {
  source = "./network"
}
module "aks" {
  source = "./aks"
}
module "redis" {
  source = "./redis"
  subnet_id = module.network.subnet1_id
}
module "sql" {
  source    = "./sql"
  subnet2_id = module.network.subnet2_id
}

module "helm" {
  source = "./helm"

  aks_cluster_host             = module.aks.aks_cluster_host
  aks_client_certificate       = module.aks.aks_client_certificate
  aks_client_key               = module.aks.aks_client_key
  aks_cluster_ca_certificate   = module.aks.aks_cluster_ca_certificate
}
