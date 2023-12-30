variable "aks_cluster_host" {}
variable "aks_client_certificate" {}
variable "aks_client_key" {}
variable "aks_cluster_ca_certificate" {}

provider "helm" {
  kubernetes {
    host                   = var.aks_cluster_host
    client_certificate     = base64decode(var.aks_client_certificate)
    client_key             = base64decode(var.aks_client_key)
    cluster_ca_certificate = base64decode(var.aks_cluster_ca_certificate)
  }
}
