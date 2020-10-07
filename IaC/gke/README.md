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

## backend&#46;tf
This file contains the backend definition. Currently uses a Hashicorp's remote backend. My Jenkins pipeline manages the .terraformrc for authentication purposes. You should adjust this to your environment

## vpcnetwork&#46;tf
This file contains the google provider and the Virtual Private Cloud definitions.
It has a `region` (the region where the VPC is deployed) output

## gke&#46;tf
This file describes the GKE cluster and the node pool.
It has a (self-explanatory) `kubernetes_cluster_name` output

## gke.auto.tfvars
Contains variables defition
Variable names | Described in | Description
------------ | ------------- | -------------
region | vpcnetwork&#46;tf | Region where the cluster is deployed (ref: https://cloud.google.com/compute/docs/regions-zones). Only 1 region used at the moment
primary_zone | gke&#46;tf | The zone where to deploy the primary cluster
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