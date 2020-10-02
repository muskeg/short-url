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

First Header | Second Header
------------ | -------------
Content from cell 1 | Content from cell 2
Content in the first column | Content in the second column

Please detail what underlying infrastructure and services the system will need, each of their roles, what problems they address and what tradeoffs were involved in your design decisions. You don't need to explain the detailed inner workings of the software service itself, but you should explain what if any other systems (databases, load balancers, etc.) it relies on upon and why.

## Disaster Recovery
What steps can be taken to mitigate downtime and data loss in the event of a database or other relevant storage failure?   

## Scalability
How does the system change as it scales up or down?
What does it look like at 10 users vs 1 million users?

## High Availability and Quality of Service
What steps should be taken to provide the majority of users with the highest quality service?

## Deployment Flow and Updates
What does the deployment process look like, both for initial deployments and for updates?

## Monitoring and Observability
How do we measure the health and performance of the system?

## Security
What steps would you take to secure these systems?

## Costing
What cost considerations would there be?

## Support and Documentation
What are the considerations for keeping it supported over time, including keeping support documentation up-to-date?

## Public VS Private Deployment
What would the deployment look like if you had to add-on a separate URL for the same application for Unity employees only that used our own ON-PREMISE data centers located in  USA, Canada, and South Korea. How would it change the components in the design, deploy, and distribution in the private/public separation for this URL shortener service?