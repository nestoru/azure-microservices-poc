# Variable Declaration
variable "subnet_id" {
  description = "The ID of the subnet where Redis should be placed"
  type        = string
}

# Azure Redis Cache Resource
resource "azurerm_redis_cache" "redis" {
  name                = "devops-microservices-redis"
  location            = "francecentral"
  resource_group_name = "devops-microservices"
  capacity            = 1
  family              = "P"  # Premium SKU for VNet integration
  sku_name            = "Premium"
  enable_non_ssl_port = false

  redis_configuration {
    # Add any specific Redis configuration settings here
  }

  # Using the subnet ID passed from the variable
  subnet_id = var.subnet_id
}
