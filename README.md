# short-url
short-url is a containerized URL shortener micro service built on Flask and Redis automatically deployed to Kubernetes clusters for auto-scaling, self-healing and globally distributed usage.

- [Architecture](#architecture)
  * [Application](#application)
    + [Flask](#flask)
    + [Redis](#redis)
    + [Users management / Authentication](#users-management---authentication)
  * [Pipeline](#pipeline)
- [Disaster Recovery](#disaster-recovery)
- [Scalability](#scalability)
- [High Availability and Quality of Service](#high-availability-and-quality-of-service)
- [Deployment Flow and Updates](#deployment-flow-and-updates)
  * [Initial Deployment](#initial-deployment)
  * [Updates](#updates)
- [Monitoring and Observability](#monitoring-and-observability)
- [Security](#security)
- [Costing](#costing)
- [Support and Documentation](#support-and-documentation)
- [Public VS Private Deployment](#public-vs-private-deployment)
  * [Load Balancing](#load-balancing)
  * [Scaling](#scaling)

## Architecture
Since the application is a small micro service and needed to be scalable and geo-distributed, my initial thoughts were to simply use an existing PaaS such as Google's App Engine, using a fully managed NoSQL database like Firestore. This would have had several advantages:
* Quick setup for a bigger focus on development and testing
* Low to no ops investment
* Leveraging a major provider's infrastructure meaning:
  * High quality of service
  * High availability
  * Easy scaling

However, business requirements asked for greater control over the infrastructure. This is why I decided to go for a Kubernetes deployment pipeline. This allows for a more standardized pipeline across public and private environments where we only need to select the appropriate provider in our IaC platform.
### Application
The application is a Flask application using a Redis datastore to store users' submitted data. Users provide an URL to the service which then serves a "shortened" URL. Shortened URL are linked to users so they can track and manage them (how often it was opened, remove them from index, etc.)
![application design](https://i.imgur.com/ntv6cFk.png)
#### Flask
Flask was chosen for my familiarity with Python and because of its lightweight nature. As it provides simple URL routing it seemed an appropriate choice for an URL-based service.
#### Redis
Since the service does not process highly time-sensitive transactions such as payments, Redis was chosen for its performances and its simple "leader-follower" replication capabilities.
#### Users management / Authentication
To allow users to track or delete their shortened URLs, a user's profile page is accessible through authentication with Google. Since the company is apparently a "Google shop" (as in using G Suite services), this allows the development of a single authentication system for both the public and the private/corporate services.

### Pipeline
The plan is to create a Jenkins declarative pipeline that will orchestrate the application lifecycle management. The pipeline checks for 2 branches: dev and main. 
 
The dev branches triggers builds and tagging of the images for further manual deployment on a dev environment. 

The main branch, on approved pull requests, builds and tags the images appropriately. 

![short-url Jenkins pipeline](https://i.imgur.com/0vAqjJH.png)

Components / Steps | Roles
------------ | -------------
Git Repo | I use a git repo not only for the application code but also for the pipeline and infrastructure definition. It is fairly easy to safely store secrets in the repo using encryption tools like [git-secret](https://git-secret.io/) or [git-crypt](https://github.com/AGWA/git-crypt). This creates an easily maintainable and self-contained environment. The repo currently has two branches: `dev` and `main` where `dev` is for, well, urh, app development purposes while `main` gets pushed to production. It would be easy to add feature branches or other specific tags into the pipeline but at the moment we do not use any.
Webhooks | Webhooks are used to trigger jobs on the Jenkins server. 
Jenkins | A declarative pipeline controls the build of the app images but also the provisioning of the infrastructure
Docker Registry | A private docker registry is used to store built images. A public registry could be used but the private registry lets us keep production applications private. The pipeline could be modified to push dev images or another "community" branch to a public registry.
Terraform | Terraform is used to provision the Kubernetes clusters. My initial plan was to use Ansible to configure pre-existing VMs and turn them into nodes of a custom cluster. In the end, the choice of Terraform was mostly to take advantage of the different providers and modules, allowing for a more unified strategy in case we end up wanting to shift between traditional VMs or VMware's Tanzu or any Cloud vendor's solution like GKE. 
Kubernetes clusters | Since we need an easily scalable, reliable and geo-distributed infrastructure to run Docker apps, Kubernetes seemed the most obvious choice. The clusters rely on a federated NGINX ingress controller to load-balance and route traffic to the most appropriate nodes. The primary cluster, holding the primary Redis database service is located in eastern North-America as the first (and currently only) subset of users and operators are located in this region. Replicas are deployed to others nodes globally as the application needs to scale up and down.

## Disaster Recovery
As the application is easily replicated, the expected downtime in case of failure is very low. Also, despite performance drawbacks two persistence strategies are used for the Redis database: RDB and AOF. The combination of the two gives us almost realtime protection while reducing the rebuild time from the AOF in case of catastrophic failure.

All the persistent volumes are expected to be on multi-zonal replicated storage (i.e. Google's Regional SSD Space) to avoid any storage downtime and improve global availability.

## Scalability
The application should use autoscaling features where possible. Since I expect the service to be fault tolerant and because it should not require 100% continuous availability I am planing to use GKE's cluster autoscaler functionality, even if brief disruption of service on certain nodes are possible during resizing. The primary pods sets, including Redis leaders pods, could be excluded from autoscaling.

Since the service is of limited complexity and is not expected to use a lot of resources, the initial deployment should easily run on 1 node (2 vCPUs, 7.5 GB RAM - n1-standard-2). Even with a single machine, the specifications should leave idle resources to for additional pods deployments on that machine when necessary. This ensures we already have available resources for scaling if there were some usage bursts before the system requires and provisions additional nodes.

As the userbase gets bigger, additional zonal clusters can be spun up to cover and balance resources usage where the users are physically located.  

_<sub><sup>(note: I hesitated between manual and automatic scaling as it remains a risk of semi-uncontrolled billing, especially when you're not 100% sure of all the details. I went for automatic scaling mostly because it "looked" nice on paper but in a real life scenario I think I would prefer to get a certain amount of usage statistics before enabling full-fledged automating scaling. Just to be sure we don't end up with thousands of dollars to pay for a small service like this one)</sup></sub>_


## High Availability and Quality of Service
Running the service at a Cloud provider should help greatly in offering higher availability (expected SLA of at least 99.5%). As mentioned previously, the use of regional persistent disks allows for multi-zone replication reducing latency to access the storage and making sure it stays up even through a hypothetical zonal failure. 

To help users reach the service as quickly as possible, a federated NGINX (for its `rewrite` capabilities but also for personal preferences) ingress controller is used to load-balance traffic to the most appropriate service's pods. The ingress controller allows us to centralize load balancing and ingress rules. As clusters are deployed globally, the ingress controller ensures users reach the closest (or most available) pod for better response times. 

## Deployment Flow and Updates
The Jenkins pipeline should manage two types of events:
* Initial deployment: when no infrastructure has been provisioned, app is not running
* Updates: infrastructure is already available, app is already running and serving clients
### Initial Deployment
When the application is first deployed, Jenkins should first trigger infrastructure provisioning steps after a successful build of the Docker image. After creating the Kubernetes cluster, Jenkins should then apply a deployment definition yaml file to the cluster that includes the ingress controller, the persistent volume claims and the Prometheus sidecar containers (as described in the next section)
### Updates
Since the service will eventually run in multiple replicated pods and nodes, I opted for a rolling updates strategy. After a successful stable and approved build, if the infrastructure is already deployed and the service is running, Jenkins should simply `rollout` the deployment to replace the existing pods with the latest version of the images.

## Monitoring and Observability
I'm using Prometheus to gain observability on the application and the infrastructure where it's running. To do so, a `node_exporter` sidecar container is deployed alongside the application images to expose pods' metrics. Redis instances could also have an additional Redis exporter sidecar. 

The metrics are then sent to Grafana to setup visualization dashboards and alerts. We should be looking for the number of requests to each pods as well as resources usage to make sure the load is indeed balanced properly and the scaling limits are appropriate. Redis monitoring should look for the number of calls made to the DBs and the numbner of objects they contain to make sure we they do not suffer from latency spikes during persistence filesave operations.

## Security
Since the application receives users data we should first ensure that this data is properly sanitized before processing it. During build steps we could use an OWASP plugin to scan the code and application for vulnerabilities. Since we are using containers, the application and containers should be designed to run with a non-root user.

To secure the infrastructure, we need to make sure the API management endpoints and other metrics exports are not openly reachable. A bastion host allowing access to limited IP ranges could be setup for remote access and management. We should also prevent unneeded kernel modules to be loaded using node's deny lists where applicable.  

## Costing
I imagine that auto-scaling clusters can create some surprises in billing and costs. One of the strategy mentioned earlier is to provision nodes with larger resources. While this has the downside of making initial costs slightly higher, this is quickly balanced by allowing us to pack more pods in the same nodes as the application scales. In comparison to running a higher number of smaller sized nodes, this strategy helps avoiding having nodes idling after being provisioned. I believe this should help in making costs scaling more predictable.  

## Support and Documentation
To ensure it's available and updated frequently, I believe the documentation should be as close to the code as possible, whether it's application code or infrastructure code. This means keeping it in the SCM such as this README in the git repository. Folders containing code should also contain proper documentation pertaining to that code. Keeping it close to the code makes that a reminder to not leave it untouched when updating the code.

The application is quite basic with a limited set of features. This should make general support fairly easy with a (hopefully) limited number of possible issues.  Again, the SCM's wiki sections could contain FAQs to guide that support and possibly allow for auto-support.

## Public VS Private Deployment
Knowing that the application required the ability to be deployed on on-premise infrastructure directed the unified IaC strategy. This means that the differences in the deployment between a publicly accessible service and a privately hosted service should be minimal. For example, using Terraform's vSphere provider should make the provisioning of a VMware-based in-house Kubernetes cluster more simple while leaving the rest of the application deployment untouched (assuming VM storage for the database also has snapshots and replication capabilities). The main differences, especially since it would use its own separate access URL, would be in the ingress/load balancing and autoscaling systems. 

### Load Balancing
Since we will be hosting clusters in 3 different data centers the company owns in the world, we should leverage the company's internal DNS architecture to route traffic appropriately instead of trying to replicate a Cloud vendor's system with things like [MetalLB](https://metallb.universe.tf/). It should be fairly straightforward to route traffic to the best available resource using the company's infrastructure.

### Scaling
Because we already know that an internal service will only have to handle at max a few thousands users, autoscaling the application seems unnecessary. We should be able to determine initially how many nodes would be required to handle that traffic (which, considering the service, will mostly likely look like single-node clusters in each data center) and still have time to adjust in a more manual fashion, would the company's employees count grow immensely. 