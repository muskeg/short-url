# short-url
short-url is a containerized URL shortener micro service built on Flask and Redis automatically deployed to Kubernetes clusters for auto-scaling, self-healing and globally distributed usage.

## Architecture
Since the application is a small micro service and needed to be scalable and geo-distributed, my initial thoughts were to simply use an existing PaaS such as Google's App Engine, using a fully managed NoSQL database like Firestore. This would have had several advantages:
* Quick setup for a bigger focus on development and testing
* Low to no ops investment
* Leveraging a major provider's infrastructure meaning:
  * High quality of service
  * High availability
  * Easy scaling

However, business requirements asked for greater control over the infrastructure. This is why I decided to go for a Kubernetes deployment pipeline. This allows for a more standardized pipeline across public and private environments where we only need to select the appropriate provider in our IaC platform.

### Pipeline
The plan is to create a Jenkins declarative pipeline that will orchestrate the application lifecycle management. The pipeline checks for 2 branches: dev and main. 
 
The dev branches triggers builds and tagging of the images for further manual deployment on a dev environment. 

The main branch, on approved pull requests, builds and tags the images appropriately. 

![short-url Jenkins pipeline](https://i.imgur.com/0vAqjJH.png )

Components / Steps | Roles
------------ | -------------
Git Repo | I use a git repo not only for the application code but also for the pipeline and infrastructure definition. It is fairly easy to safely store secrets in the repo using encryption tools like [git-secret](https://git-secret.io/) or [git-crypt](https://github.com/AGWA/git-crypt). This creates an easily maintainable and self-contained environment. The repo currently has two branches: `dev` and `main` where `dev` is for, well, urh, app development purposes while `main` gets pushed to production. It would be easy to add feature branches or other specific tags into the pipeline but at the moment we do not use any.
Webhooks | Webhooks are used to trigger jobs on the Jenkins server. 
Jenkins | A declarative pipeline controls the build of the app images but also the provisioning of the infrastructure
Docker Registry | A private docker registry is used to store built images. A public registry could be used but the private registry lets us keep production applications private. The pipeline could be modified to push dev images or another "community" branch to a public registry.
Terraform | Terraform is used to provision the Kubernetes clusters. My initial plan was to use Ansible to configure Kubernetes nodes and join them into clusters. In the end, the choice of Terraform was mostly to take advantage of the different providers, allowing us to create conditional deployment steps specifying the environment where to build the application's infrastructure from scratch. Effectively removing the need to initially deploy "vanilla" nodes on which apply an Ansible role. 
Kubernetes clusters | Since we need an easily scalable, reliable and geo-distributed infrastructure to run Docker apps, Kubernetes seemed the most obvious choice. The clusters use a federated NGINX ingress controller to load-balance and route traffic 

## Disaster Recovery
> What steps can be taken to mitigate downtime and data loss in the event of a database or other relevant storage failure?   

## Scalability
> How does the system change as it scales up or down? 
> What does it look like at 10 users vs 1 million users?

## High Availability and Quality of Service
> What steps should be taken to provide the majority of users with the highest quality service?

## Deployment Flow and Updates
> What does the deployment process look like, both for initial deployments and for updates?

## Monitoring and Observability
> How do we measure the health and performance of the system?

## Security
> What steps would you take to secure these systems?

## Costing
> What cost considerations would there be?

## Support and Documentation
> What are the considerations for keeping it supported over time, including keeping support documentation up-to-date?

## Public VS Private Deployment
> What would the deployment look like if you had to add-on a separate URL for the same application for the company employees only that used our own ON-PREMISE data centers located in  USA, Canada, and South Korea. How would it change the components in the design, deploy, and distribution in the private/public separation for this URL shortener service?