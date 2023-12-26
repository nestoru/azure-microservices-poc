# Create AKS cluster
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
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Outputs the cluster componets to be used by tools like helm

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
