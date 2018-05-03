#!/bin/bash

# Write stdout and stderr to text file
exec > >(tee "createCluster-1.txt")
exec 2>&1

# Required inputs
SUBSCRIPTION_ID= # Azure subscription ID
RESOURCE_GROUP= # Name of resource group used to create Azure artifacts for Kubernetes cluster
LOCATION= # Azure location where Kubernetes cluster artifcats are created
DNS_PREFIX= # Unique prefix required for the Kubernets master node. Also used for the name of the service principal

# Delete and create new resource group.
echo Deleting old resource group
az group delete --name=$RESOURCE_GROUP --yes

echo Creating resource group
az group create --name=$RESOURCE_GROUP --location=$LOCATION

# Delete and create service principal
echo Deleting service principal
SERVICE_PRINCIPAL_NAME=$DNS_PREFIX
az ad sp delete --id http://$SERVICE_PRINCIPAL_NAME

echo Creating service principal

SERVICE_PRINCIPAL_PASSWORD=`az ad sp create-for-rbac --name $SERVICE_PRINCIPAL_NAME --role="Contributor" --scopes="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" --query password -o tsv`
SERVICE_PRINCIPAL_ID=$(az ad sp show --id http://$SERVICE_PRINCIPAL_NAME --query appId --output tsv)
echo Service principal id: $SERVICE_PRINCIPAL_ID
echo Service principal password: $SERVICE_PRINCIPAL_PASSWORD

# Azure CLI bug requires some time for the service principal to propagate
echo Waiting for service principal to propagate
sleep 30

# Gives service principal contributor permissions to the resource group created above
echo Giving service principal contributor permissions to the resource group
az role assignment create --assignee $SERVICE_PRINCIPAL_ID \
    --resource-group $RESOURCE_GROUP \
    --role contributor

# Create a pair of SSH keys. Warning hard-coded password below. Do no use in production!!
echo Creating SSH keys
ssh-keygen -N LukkhaCoder1! -C lukkhacoder.com -f ./acsEngine_rsa
SSH_PUBLIC_KEY=$(<acsEngine_rsa.pub)
echo Public key: $SSH_PUBLIC_KEY


# prepare the cluster deployment file for ACS Engine
echo Starting update of cluster definition json file
CLUSTER_DEFINITION=$(<clusterDefinition.json)
CLUSTER_DEFINITION=$(jq --arg keyData "$SSH_PUBLIC_KEY" '.properties.linuxProfile.ssh.publicKeys[0].keyData=$keyData' <<< "$CLUSTER_DEFINITION")
CLUSTER_DEFINITION=$(jq --arg id $SERVICE_PRINCIPAL_ID '.properties.servicePrincipalProfile.clientId=$id' <<< "$CLUSTER_DEFINITION")
CLUSTER_DEFINITION=$(jq --arg secret $SERVICE_PRINCIPAL_PASSWORD '.properties.servicePrincipalProfile.secret=$secret' <<< "$CLUSTER_DEFINITION")
CLUSTER_DEFINITION=$(jq --arg dnsPrefix $DNS_PREFIX '.properties.masterProfile.dnsPrefix=$dnsPrefix' <<< "$CLUSTER_DEFINITION")
echo $CLUSTER_DEFINITION > clusterDefinition-1.json
echo clusterDefinition-1.json created

# generate the ARM template
echo Invoking acs-engine to generate ARM template.
acs-engine generate ./clusterDefinition-1.json

# deploy the ARM template
echo Deploying generated template. This will take some time.
az group deployment create \
    --name acs-engine-cluster \
    --resource-group $RESOURCE_GROUP \
    --template-file ./_output/$DNS_PREFIX/azuredeploy.json \
    --parameters ./_output/$DNS_PREFIX/azuredeploy.parameters.json

# Download Kubernetes Credentials and show cluster information
echo Downloading cluster connection information. You may need to enter private key password.
chmod 700 ./acsEngine_rsa
scp -i ./acsEngine_rsa azureuser@$DNS_PREFIX.$LOCATION.cloudapp.azure.com:.kube/config .
export KUBECONFIG=`pwd`/config
kubectl cluster-info

echo All Done!! Created new files: acsEngine_rsa, acsEngine_rsa.pub, clusterDefinition-1.json and config. Created folder: _output