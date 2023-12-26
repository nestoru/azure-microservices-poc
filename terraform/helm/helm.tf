variable "aks_cluster_host" {}
variable "aks_client_certificate" {}
variable "aks_client_key" {}
variable "aks_cluster_ca_certificate" {}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "devops-microservices"

  set {
    name  = "controller.publishService.enabled"
    value = "true"
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.5.0"  # Specify the desired version

  set {
    name  = "installCRDs"
    value = "true"
  }

  # Additional configurations can be added here
}

