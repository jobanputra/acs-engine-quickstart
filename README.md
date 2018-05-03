# Target audience
This repository contains code that will get a Kubernetes cluster running on Azure using acs-engine and Azure cli with the fewest amount of changes. The target audience is developers that are unfamiliar with acs-engine.

The generated cluster is fit only for **non production i.e. development and testing** use.

# Developer prerequisites
1. acs-engine: [Download and install](https://lukkhacoder.com/posts/technical/2018/deploy-kubernetes-cluster-in-azure-with-acs-engine-quickstart/).
1. Azure cli: [Download and install](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest).
1. kubectl: [Download and install](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl).
1. jq: [Download and install](https://stedolan.github.io/jq/download/)
1. (Optional) A provisioned Azure Active Directory service principal: [Create using Azure portal](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal) or [Create using Azure CLI](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?toc=%2Fazure%2Fazure-resource-manager%2Ftoc.json&view=azure-cli-latest)


# Using acs-engine to create a Kubernetes cluster on Azure
Using acs-engine to create a Kubernetes cluster on Azure bascially involves the following steps.
1. Customize the cluster that will be created up modifying the cluster definition json file.
2. Invoke acs-engine to generate the ARM templates for your cluster.
3. Deploy the generated ARM template.

## Option 1: The path of least resistance
1. Update `createCluster-1.sh` and set values for the following variables: `SUBSCRIPTION_ID`, `RESOURCE_GROUP`, `LOCATION` and `DNS_PREFIX`.
1. Run the script `createCluster-1.sh`.

The script does the following:
1. Creates a new resource group.
1. Creates a new service principal and:
    - Gives it contributor permissions to the resource group created above.
    - Updates `serviceProfile` section in `clusterDefinition.json` with the appID and secret.
1. Creates a pair of SSH keys and:
    - Updates the `key-data` property in `clusterDefinition.json` with the public key.
1. Updates the `dnsPrefix` property in `clusterDefinition.json`.
1. Writes the new cluster definition to `clusterDefinition-3.json`
1. Invokes acs-engine to generate the ARM templates for creating the cluster.
1. Deploys the generated ARM templates to Azure. This steps takes a while to complete.
1. Downloads the kube config file by connecting to the master node using SSH. This step might require you to enter the password for the private SSH key.
1. Connects to the newly created Kubernetes cluster using the downloaded configuration information and prints the cluster information.

**Note that this option uses a password that is checked into the repository and is therefore publically available. The cluster created by this file should not be considered secure**

## Option 2: Bring your own SSH keys
1. Create/place a set of SSH keys in the root folder. The keys should be named `acsEngine_rsa` and `acsEngine_rsa.pub`.
1. Update `createCluster-2.sh` and set values for the following variables: `SUBSCRIPTION_ID`, `RESOURCE_GROUP`, `LOCATION` and `DNS_PREFIX`.
1. Run the script `createCluster-2.sh`.

The script does the following:
1. Creates a new resource group.
1. Creates a new service principal and:
    - Gives it contributor permissions to the resource group created above.
    - Updates `serviceProfile` section in `clusterDefinition.json` with the appID and secret.
1. Updates the `key-data` property in `clusterDefinition.json` with the public key.
1. Updates the `dnsPrefix` property in `clusterDefinition.json`.
1. Writes the new cluster definition to `clusterDefinition-2.json`
1. Invokes acs-engine to generate the ARM templates for creating the cluster.
1. Deploys the generated ARM templates to Azure. This steps takes a while to complete.
1. Downloads the kube config file by connecting to the master node using SSH. This step might require you to enter the password for the private SSH key.
1. Connects to the newly created Kubernetes cluster using the downloaded configuration information and prints the cluster information.


## Option 3: Bring your own SSH keys and Service Principal
1. Create/place a set of SSH keys in the root folder. The keys should be named `acsEngine_rsa` and `acsEngine_rsa.pub`
1. Update `createCluster-3.sh` and set values for the following variables: **`SERVICE_PRINCIPAL_ID`, `SERVICE_PRINCIPAL_PASSWORD`**, `SUBSCRIPTION_ID`, `RESOURCE_GROUP`, `LOCATION` and `DNS_PREFIX`.
1. Run the script `createCluster-3.sh`.

The script does the following:
1. Creates a new resource group.
1. Gives the service princiapl contributor permissions to the resource group created above.
    - Updates `serviceProfile` section in `clusterDefinition.json` with the appID and secret.
1. Updates the `key-data` property in `clusterDefinition.json` with the public key.
1. Updates the `dnsPrefix` property in `clusterDefinition.json`.
1. Writes the new cluster definition to `clusterDefinition-3.json`
1. Invokes acs-engine to generate the ARM templates for creating the cluster.
1. Deploys the generated ARM templates to Azure. This steps takes a while to complete.
1. Downloads the kube config file by connecting to the master node using SSH. This step might require you to enter the password for the private SSH key.
1. Connects to the newly created Kubernetes cluster using the downloaded configuration information and prints the cluster information.

# Kudos
This repository contains code that is based on the work of [Wes yao](https://github.com/wesyao), [Aaron Schnieder](https://github.com/aaron-schnieder) and [Ivan Shaporov](https://github.com/ivan-shaporov)