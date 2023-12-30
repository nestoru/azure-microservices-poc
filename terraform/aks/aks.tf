variable "client_id" {}
variable "client_secret" {}
variable "subnet_id" {
  description = "The ID of the subnet for the AKS cluster"
  type        = string
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.cluster_ca_certificate)
}

resource "kubernetes_namespace" "devops_microservices" {
  metadata {
    name = "devops-microservices"
  }
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "devops-microservices"
  location            = "francecentral"
  resource_group_name = "devops-microservices"
  dns_prefix          = "devopsmicroservices"

  default_node_pool {
    name             = "default"
    node_count       = 1
    vm_size          = "Standard_DS2_v2"
    vnet_subnet_id   = var.subnet_id
  }

  network_profile {
    network_plugin = "azure"
    service_cidr   = "10.2.0.0/24"
    dns_service_ip = "10.2.0.10"
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  ingress_application_gateway {
    gateway_name = "devops-microservices-appgw"
    subnet_cidr = "10.0.2.0/24"
  }
}

output "aks_cluster_host" {
  value = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].host
}

output "aks_client_certificate" {
  value = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_certificate
}

output "aks_client_key" {
  value = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_key
}

output "aks_cluster_ca_certificate" {
  value = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].cluster_ca_certificate
}

