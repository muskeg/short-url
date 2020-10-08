# GKE Provisioning
This folder contains the GKE cluster definition files
```
├── README.md
├── backend.tf
├── vpcnetwork.tf
├── gke.tf
├── gke.auto.tfvars 
└── secrets.auto.tfvars.secret
```
Jenkins enables Terraform to connect to terraform.io to get the current workspace state as defined in the `backend.tf` file. Terraform then deploys or updates the GKE cluster (using Jenkins-provided credentials) according to the rest of the .tf files. 

## backend&#46;tf
This file contains the backend definition. Currently the pipeline uses Hashicorp's remote backend to allow state persistence between builds as the Jenkins's workspace is wiped at the beginning of every build. On terraform.io, the execution mode is set to "remote" and uses the manual apply method as it is controlled by Jenkins. My Jenkins pipeline manages the `.terraformrc` for authentication purposes. You should adjust this file to your environment.

## vpcnetwork&#46;tf
This file contains the google provider (including credentials definition) and the Virtual Private Cloud definitions.
It has a `region` (the region where the VPC is deployed) output.

## gke&#46;tf
This file describes the GKE cluster and the node pool.
It has a (self-explanatory) `kubernetes_cluster_name` output.

## gke.auto.tfvars
Contains variables defition
Variable names | Described in | Description
------------ | ------------- | -------------
region | vpcnetwork&#46;tf | Region where the cluster is deployed (ref: https://cloud.google.com/compute/docs/regions-zones). Only 1 region is used at the moment
primary_location | gke&#46;tf | The location where to deploy the primary cluster. This can be a zone or a region
gke_node_count | gke&#46;tf | The number of nodes to provision initially
scaling_min | gke&#46;tf | The minimum number of nodes used in autoscaling
scaling_max | gke&#46;tf | The maximum number of nodes used in autoscaling

## secrets.auto.tfvars.secret
Contains "sensitive" variables. This file is encrypted using [git-secret](https://git-secret.io/). It is revealed during deployment to an automatically loaded variables file: `secrets.auto.tfvars`.
Variable names | Described in | Description
------------ | ------------- | -------------
project_id | vpcnetwork&#46;tf | The GCP project ID
gke_username | gke&#46;tf | The GKE cluster's username
gke_password | gke&#46;tf | The GKE cluster's password