[![](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/donate/?hosted_button_id=58F9TDDRBND4L)

# Azure Terraform Helm Microservices PoC for Devops
This PoC shows how to use Terraform to host TLS microservices (or many) in Microsoft Azure Kubernetes Service (AKS), deployed with Helm charts. The structure of the project is below and it is the second of three cloud projects (GCP, AZ, AWS) that show how to manage microservices hosted in different cloud providers.
```
├── README.md
├── deploy.sh
├── helm
│   ├── Chart.yaml
│   ├── charts
│   ├── templates
│   │   ├── deployment.yaml
│   │   ├── ingress.yaml
│   │   └── service.yaml
│   └── values.yaml
├── microservice
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
└── terraform
    ├── aks
    │   └── aks.tf
    ├── backend.tf
    ├── credentials.json
    ├── devops-microservices.tf
    ├── helm
    │   └── helm.tf
    ├── network
    │   └── network.tf
    ├── redis
    │   └── redis.tf
    ├── sql
    │   └── sql.tf
    ├── tfplan
    └── versions.tf
```
## Azure CLI
- Install the az command (I will work mainly from OSX and linux)
```
# OSX
brew install azure-cli
# Ubuntu 
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

## Kubernetes
- Configure kubectl to use the correct context. Getting nodes and pods offen is of essence to ensure that they kubectl works with AZ clusters.
```
az login
az aks get-credentials --name devops-microservices --resource-group devops-microservices
kubectl config current-context
kubectl get nodes
kubectl get pods --all-namespaces
```

## Terraform
This POC assumes there are multiple microservices that will use redis for caching in a DMZ vnet1, communicating with a PostgreSQL db in a protected vnet2. To that end a root module devops-microservices.tf is created which deploys all needed modules (network.tf, redis.tf, sql.tf, gke.tf, and helm.tf) and keeps the stage in a bucket defined in backend.tf.
 
- Create the bucket to persist terraform state via storage.tf
```
az group create --name devops-microservices --location "francecentral"
az provider register -n Microsoft.Storage --subscription e0eb6568-04b4-4ac0-bbc2-0beca8157e8a
az storage account create --name devopsmicroservices --resource-group devops-microservices --location "francecentral" --sku Standard_LRS --kind StorageV2
export ACCOUNT_KEY=$(az storage account keys list --resource-group devops-microservices --account-name devopsmicroservices --query '[0].value' --output tsv)
az storage container create --name tfstate --account-name devopsmicroservices  --account-key $ACCOUNT_KEY
```

- Create a Service Principal and Output Credentials. Your subscrioption ID will be different than mine.
```
mkdir -p terraform
cd terraform
az account list
az account set --subscription "e0eb6568-04b4-4ac0-bbc2-0beca8157e8a"
az ad sp create-for-rbac --name "TerraformSP" --role="Contributor" --scopes="/subscriptions/e0eb6568-04b4-4ac0-bbc2-0beca8157e8a" --sdk-auth > credentials.json
```

- List all terraform files and their content
```
find ./ -type f -name "*.tf" -exec sh -c 'echo "File: {}"; cat {}' \;
```

- Create and apply terraform plan
```
cd terraform
export KUBE_CONFIG_PATH=~/.kube/config && terraform init && terraform validate && terraform plan -refresh=false -out=tfplan
export KUBE_CONFIG_PATH=~/.kube/config && terraform init && terraform validate && terraform apply "tfplan"
```

- Check the creation of the NSG. Network Security Groups are essential in Azure.
```
az network nsg list --resource-group devops-microservices --output table
```

## Helm
We use helm to deploy the microservices to the terraform created infrastructure.

- List all helm templates and their content
```
find ./helm/templates -type f -name "*.yaml" -exec sh -c 'echo "File: {}"; cat {}' \;
```
* ./helm/Chart.yaml contains name, version and description of our helm environment to manage microsservices in kubernetes.
* ./helm/values.yaml is an empty file because even though we will use variable values to deploy different majorVersion of our microservice we will inject these values from command line directly instead of hardcoding them in the values.yaml file.
* ./helm/templates/deployment.yaml is the deployment descriptor in charge of deploying two pods per microservice appVersion. Note that the majorVersion ensures that each microservice major version gets their own deployed endpoint,
* ./helm/templates/ingress.yaml should ensure that requests coming to the host where microservices are invoked are enforced to use TLS, are tied to an external reserved IP, served by an nginx gateway behind a loadbalancer, and routes the upcoming traffic to the correct deployed majorVersion by using paths like /v1/, /v2/ etc. Unfortunately for AKS "helm_release" "nginx_ingress" resources do not work as they would out of the box for GCP. Intead we use Azure Gateway Ingress Controller (AGIC) which does not work automatically at the time of this writing to generate certificates with providers like letsencrypt..
* ./helm/templates/service.yaml is a ClusterIP manifest that ensures that the deployed pods will receive the requests equally distributed as these will be round robined through this service which received requests on internal port 80 and forwards it to port 8080 in the deployed pods.

### Deploy and run the microservices locally
Before jumping to deploy our microservices in the cloud infrastructure we built with terraform using helm, we should make sure we can run them locally so that we can test what happens when we deploy them to the cloud.

- Our sample  microservice is written in python and it simply accepts a POST request that provides a from, to and message tokens which are then used to return some confirmation to the invoker. The v1 returns a message different than the v2 so that we can confirm that they both are deployed correctly. To keep these versions independent from each other git branching is used.
```
cd microservice
python -m venv myenv
source myenv/bin/activate
pip install -r requirements.txt
export EXPECTED_API_KEY='2f5ae96c-b558-4c7b-a590-a501ae1c3f6c' && python app.py
```
- At this point we can send the following request and we will get a message back
```
export EXPECTED_API_KEY='2f5ae96c-b558-4c7b-a590-a501ae1c3f6c' && \
export HOST=localhost:8080 && \
curl -kX POST \
-H "X-Parse-REST-API-Key: ${EXPECTED_API_KEY}" \
-H "Content-Type: application/json" \
-d '{ "message": "This is a test", "to": "Juan Perez", "from": "Rita Asturia", "timeToLifeSec": 45 }' \
http://${HOST}/DevOps
```


### Deploy and run the microservices on docker
```
cd microservice/
docker build . -t devops-microservices 
docker stop devops-microservices; docker rm devops-microservices
docker run -e EXPECTED_API_KEY='2f5ae96c-b558-4c7b-a590-a501ae1c3f6c' --detach --publish 8080:8080 --name devops-microservices devops-microservices
export EXPECTED_API_KEY='2f5ae96c-b558-4c7b-a590-a501ae1c3f6c' && export HOST=localhost:8080 && curl -kX POST -H "X-Parse-REST-API-Key: ${EXPECTED_API_KEY}" -H "Content-Type: application/json" -d '{ "message": "This is a test", "to": "Juan Perez", "from": "Rita Asturia", "timeToLifeSec": 45 }' http://${HOST}/DevOps
```

### Deploy and run the microservices in Azure with the help of helm
- Create the devopsmicroservices Azure Container Registry (ACR). In my case devopsmicroservicesacr.azurecr.io
```
az acr create --name devopsmicroservicesacr --resource-group devops-microservices --sku Basic --location francecentral
az acr list --resource-group devops-microservices --output table
```
- Use the ACR to deploy the microservices docker images in the pods via the deployment manifest (deployment.yaml).
- Update the AKS cluster to attach to the Azure Container Registry (ACR) so that docker is authorized to pull images from the kubernetes cluster
```
az aks update -n devops-microservices -g devops-microservices --attach-acr devopsmicroservicesacr
```
- Run a manual deployment with helm to find out if pods are deployed
```
./deploy.sh 1.0.1 # besides building the image and publishing, it also executes helm upgrade --install helm-1 ./helm --namespace devops-microservices --set majorVersion=1 --set appVersion=1.0.1
kubectl get pods -n devops-microservices 
```
- Use port forwarding to interact with the pod running app
```
kubectl port-forward pod/`kubectl get pods --namespace devops-microservices | grep devops | head -1 | awk '{print $1}'` -n devops-microservices 8080
```
- We commit this version to the main git branch and create a new majorVersion v1 branch for it. We go back to the main branch, update the message and then create v2 branch out of it. This allows us to be able to deploy the two versions in different pods and test them with requests having different paths (/v1/ and /v2/ paths). 
```
git checkout -b devops-microservices-1
git push -u origin devops-microservices-1
git branch
git checkout main
vi microservice/app.py
git add .
git commit -m "change in app response"
git push origin main
git checkout -b devops-microservices-2
git push -u origin devops-microservices-2
git checkout devops-microservices-1 && grep Hello microservice/app.py
git checkout devops-microservices-2 && grep Hello microservice/app.py
```
As a result we see something like the below:
```
% git checkout devops-microservices-1 && grep Hello microservice/app.py 
    response_message = f"Hello {sender_name} your message will be sent."
% git checkout devops-microservices-2 && grep Hello microservice/app.py
    response_message = f"Hello {sender_name} your message will be sent to {receiver_name}."
```
- Use port forward to confirm that the two microservices versions are installed independently from each other:
```
git checkout devops-microservices-1
./deploy.sh 1.0.2
kubectl port-forward pod/`kubectl get pods --namespace devops-microservices | grep devops-microservices-1 | head -1 | awk '{print $1}'` -n devops-microservices 8080
# check response with curl
git checkout devops-microservices-2
./deploy.sh 2.0.2
kubectl port-forward pod/`kubectl get pods --namespace devops-microservices | grep devops-microservices-2 | head -1 | awk '{print $1}'` -n devops-microservices 8080
# check response with curl
```

### Testing the service
The pods run on port 8080 and are accessed via a service that uses ClusterIP to balance requests to them. This service runs on port 80. To test it, find out the IP of the services and use it from curl. List the services, pick the IP from the service you want to test, list the pods, pick the pod from where you will test the service, get into the pod and issue the curl command from there.
```
kubectl get pods  -n devops-microservices && kubectl get svc  -n devops-microservices && kubectl get ingresses  -n devops-microservices
kubectl exec -it devops-microservices-2-7b7bf45d65-zlh7r -n devops-microservices -- curl http://10.0.101.79:80
```

### Testing the ingress
Here is a guide to troubleshoot any problems with external access using a divide and conquer procedure.

Now that the service is responding on port 80, we test that the ingress is also responding. in the internal IP. In our case:
```
kubectl exec -it devops-microservices-2-7b7bf45d65-zlh7r -n devops-microservices -- curl http://10.0.13.159:80
```

If all works up to here then the external IP from the ingress should work as well:
```
kubectl exec -it devops-microservices-2-7b7bf45d65-zlh7r -n devops-microservices -- curl http://20.199.36.236:80
```

After adding the IP in a DNS A record we should also be able to confirm it works (using -k to ignore certificate for now and -L to accept the redirect from http to https):
```
host az.nestorurquiza.com
kubectl exec -it devops-microservices-2-7b7bf45d65-zlh7r -n devops-microservices -- curl -kL http://az.nestorurquiza.com:80
```

Up to now we tested that from an internal pod the internal, external IPs and the domain do respond to application requests. Now we should be able to hit the app from any machine using the domain and we can confirm that the two microservice versions are hit as expected. They are different and their SDLC can be separated from each other.
```
nu@az gcp-devops-iac % export EXPECTED_API_KEY='2f5ae96c-b558-4c7b-a590-a501ae1c3f6c'
export HOST=az.nestorurquiza.com
curl -kX POST \
-H "X-Parse-REST-API-Key: ${EXPECTED_API_KEY}" \
-H "Content-Type: application/json" \
-d '{ "message": "This is a test", "to": "Juan Perez", "from": "Rita Asturia", "timeToLifeSec": 45 }' \
http://${HOST}/v1/DevOps
{
  "major_version": 1,
  "message": "Hello Rita Asturia your message will be sent."
}
nu@az gcp-devops-iac % export EXPECTED_API_KEY='2f5ae96c-b558-4c7b-a590-a501ae1c3f6c'
export HOST=az.nestorurquiza.com
curl -kX POST \
-H "X-Parse-REST-API-Key: ${EXPECTED_API_KEY}" \
-H "Content-Type: application/json" \
-d '{ "message": "This is a test", "to": "Juan Perez", "from": "Rita Asturia", "timeToLifeSec": 45 }' \
http://${HOST}/v2/DevOps
{
  "major_version": 2,
  "message": "Hello Rita Asturia your message will be sent to Juan Perez."
}
```

We are ensuring that when requests come to /v1/ they are routed to devops-microservices-1 and when they come to /v2/ they are wouted to devops-microservices-2.

### TODO
I run out of Axzure credits so I could not deliver an automated certificate issuer solution. The nginx ingress did not work as it worked for GCP. This is the reason why I used the recommended by Azure AGIC.

## Cleanup
- Find out your resource groups
```
az group list --query "[].name" -o tsv
```
- Delete the ones that apply to this POC (Warning: Make sure you you understand that you are deleting all resources for this group)
```
az group delete --name <your-POC-resource-group> --yes --no-wait
```
