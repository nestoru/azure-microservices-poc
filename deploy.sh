#!/bin/bash -ex

# Check if the app version argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <appVersion>"
    exit 1
fi

# Read the app version from the first argument
APP_VERSION="$1"
ACR_NAME="devopsmicroservicesacr"  # Replace with your Azure Container Registry name
IMAGE_NAME="$ACR_NAME.azurecr.io/devops-microservices:$APP_VERSION"
CHART_DIR="./helm"
NAMESPACE="devops-microservices"
major_version="${APP_VERSION%%.*}"

# Azure Login (if not already logged in)
# az login

# Build and Push Docker Image
cd microservice
echo "Building Docker image: $IMAGE_NAME"
docker build -t $IMAGE_NAME .

# Authenticate to ACR
az acr login --name $ACR_NAME

echo "Pushing Docker image to Azure Container Registry"
docker push $IMAGE_NAME
cd ../

# Get AKS Credentials (if needed)
# az aks get-credentials --resource-group yourResourceGroup --name yourAKSClusterName

# Deploy with Helm
echo "Deploying application with Helm"
helm upgrade --install helm-${major_version} $CHART_DIR --namespace $NAMESPACE --set majorVersion=$major_version --set appVersion=$APP_VERSION

echo "Deployment complete"

