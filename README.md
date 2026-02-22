
---

# Deploy Strapi on AWS using ECS Fargate with Terraform and GitHub Actions (CI/CD)

---

# 1. Project Overview

This project demonstrates the deployment of a containerized Strapi application on AWS using Infrastructure as Code (Terraform) and a fully automated CI/CD pipeline with GitHub Actions.

The main objective of this project is to build a secure, scalable, and modular cloud architecture where:

* The application runs inside containers using Amazon ECS Fargate.
* Traffic is routed through an Application Load Balancer (ALB).
* The database runs on Amazon RDS (PostgreSQL) inside private subnets.
* The entire infrastructure is provisioned using Terraform modules.
* Application builds and deployments are automated using GitHub Actions.
* Logs and metrics are monitored using Amazon CloudWatch.

This project follows best practices such as:

* Public and private subnet separation.
* No public access to the database.
* ECS tasks running in private subnets.
* IAM roles instead of hardcoded credentials.
* SHA-based Docker image deployments.

The architecture ensures that only the load balancer is publicly accessible, while the application containers and database remain securely isolated inside private networking.

---

## Project Goals

The key goals of this project are:

1. Deploy a Strapi CMS application in a containerized environment.
2. Use serverless containers (ECS Fargate) to avoid EC2 management.
3. Implement a secure networking architecture using a custom VPC.
4. Store application data in a managed PostgreSQL database.
5. Automate infrastructure provisioning using Terraform.
6. Automate build and deployment using GitHub Actions.
7. Implement monitoring and logging using CloudWatch.

---

## Repository Structure

Below is the simplified structure of this repository:

```
strapi-ec2-fargate-terraform/
│
├── strapi-app/                  # Strapi application source code
│   ├── Dockerfile               # Docker build configuration
│   └── (Strapi project files)
│
├── terraform/
│   ├── main.tf                  # Root module configuration
│   ├── variables.tf             # Root variables
│   ├── outputs.tf               # Root outputs
│   ├── backend.tf               # S3 remote state configuration
│   │
│   └── modules/
│       ├── vpc/                 # VPC, subnets, IGW, NAT
│       ├── security/            # Security groups
│       ├── alb/                 # Application Load Balancer
│       ├── ecs/                 # ECS cluster, task, service
│       ├── rds/                 # PostgreSQL RDS instance
│       ├── ecr/                 # ECR repository
│       └── iam/                 # IAM roles for ECS
│
└── .github/
    └── workflows/
        └── deploy.yml           # CI/CD pipeline
```

The repository is structured using Terraform modules so that each AWS service is isolated and reusable. This improves maintainability and makes the infrastructure easier to scale or modify.

---

# 2. Architecture Overview

This project uses a multi-layer AWS architecture designed to separate public access from internal services. The application is deployed inside a custom VPC with both public and private subnets.

The architecture follows a secure flow:

User → Application Load Balancer → ECS Fargate → RDS PostgreSQL

Only the Application Load Balancer is exposed to the internet. All other components are deployed inside private subnets.

---

## High-Level Architecture Components

The infrastructure consists of the following main components:

* Custom VPC
* Public subnets
* Private subnets
* Internet Gateway
* NAT Gateway
* Application Load Balancer (ALB)
* ECS Cluster (Fargate)
* Amazon RDS (PostgreSQL)
* Amazon ECR
* CloudWatch
* IAM Roles

---

## Network Layout

The VPC is divided into two types of subnets:

### Public Subnets

Public subnets contain:

* Application Load Balancer
* NAT Gateway

These subnets have a route to the Internet Gateway, which allows the ALB to receive traffic from users over HTTP.

The ALB acts as the entry point to the application.

---

### Private Subnets

Private subnets contain:

* ECS Fargate tasks (Strapi container)
* Amazon RDS database

These subnets do not have direct internet access. Instead, they route outbound traffic through the NAT Gateway.

This ensures:

* The database is not publicly accessible.
* Application containers are not directly exposed to the internet.
* Only controlled traffic flows through the ALB.

---

## Traffic Flow Explanation

Below is the step-by-step traffic flow in the system:

1. A user accesses the application using the ALB DNS name.
2. The request reaches the Application Load Balancer in the public subnet.
3. The ALB forwards the request to the ECS service target group.
4. ECS Fargate runs the Strapi container inside a private subnet.
5. The Strapi application connects internally to the RDS PostgreSQL database.
6. The response flows back from ECS → ALB → User.

No direct internet access is allowed to ECS tasks or RDS.

---

## Outbound Internet Access

Although ECS tasks run in private subnets, they still require outbound internet access for:

* Pulling Docker images from Amazon ECR
* Accessing external APIs if required
* Installing dependencies during container startup

This outbound traffic flows through:

Private Subnet → NAT Gateway → Internet Gateway

The NAT Gateway allows outbound internet access without allowing inbound traffic.

---

## Security Design Summary

* ALB allows inbound HTTP traffic from the internet.
* ECS security group allows traffic only from the ALB security group.
* RDS security group allows traffic only from the ECS security group.
* RDS is not publicly accessible.
* ECS tasks do not have public IP addresses.

This layered approach ensures proper network isolation and follows AWS security best practices.


---

# 3. Why This Architecture

This architecture was designed with security, scalability, and maintainability in mind. Instead of deploying everything in a simple public setup, the goal was to follow a structured cloud design that resembles real-world production environments.

This section explains the reasoning behind the major design decisions.

---

## Why Containerization?

The application is deployed as a Docker container instead of running directly on a virtual machine.

Reasons:

* Ensures consistent environment across development and production.
* Makes the application portable.
* Simplifies deployment and scaling.
* Works seamlessly with ECS and CI/CD pipelines.

Using Docker allows the application to be versioned and deployed using image tags, making rollbacks and updates easier.

---

## Why ECS Fargate Instead of EC2?

ECS Fargate was chosen instead of managing EC2 instances.

Reasons:

* No server management required.
* No OS patching or instance scaling.
* Pay only for the CPU and memory used.
* Built-in integration with ALB and CloudWatch.

Fargate allows focus on application deployment instead of infrastructure maintenance.

---

## Why Application Load Balancer?

An Application Load Balancer (ALB) was used as the public entry point.

Reasons:

* Supports HTTP and HTTPS (Layer 7 routing).
* Performs health checks on ECS tasks.
* Distributes traffic across containers.
* Integrates directly with ECS target groups.
* Allows future scaling without changing the architecture.

Without ALB, ECS tasks would require public IP addresses, which is not recommended for secure environments.

---

## Why Private Subnets for ECS and RDS?

ECS tasks and RDS are deployed inside private subnets.

Reasons:

* Prevent direct internet access.
* Reduce attack surface.
* Enforce traffic flow through ALB.
* Follow AWS security best practices.

Only the ALB is exposed to the internet. The database and application containers are protected.

---

## Why NAT Gateway?

ECS tasks require outbound internet access to:

* Pull Docker images from ECR.
* Access external APIs if needed.

However, inbound internet access is not required.

The NAT Gateway allows:

* Outbound internet access.
* No inbound public access.

This maintains security while allowing required external connectivity.

---

## Why Amazon RDS (PostgreSQL)?

Amazon RDS was chosen instead of running a database inside a container.

Reasons:

* Managed database service.
* Automatic backups.
* Automated patching.
* High availability options.
* Better performance and reliability.
* Persistent storage independent of container lifecycle.

PostgreSQL was selected because:

* Strapi has strong support for PostgreSQL.
* It is ACID compliant.
* Provides strong relational integrity.
* Supports advanced indexing and JSON features.
* Widely used in production environments.

---

## Why Amazon ECR?

ECR is used as the private Docker registry.

Reasons:

* Secure image storage.
* Integrated with IAM.
* Seamless integration with ECS.
* No need for third-party Docker registry.

Images are tagged using Git commit SHA instead of using `latest`, ensuring immutable deployments.

---

## Why Terraform?

Terraform was used to provision infrastructure.

Reasons:

* Infrastructure as Code.
* Version-controlled infrastructure.
* Modular design.
* Reproducible environments.
* Automated provisioning through CI/CD.

Each AWS service is implemented as a reusable module, improving maintainability.

---

## Why GitHub Actions for CI/CD?

GitHub Actions automates:

* Docker image build.
* Image push to ECR.
* Terraform apply.
* ECS service update.

This ensures:

* No manual deployment steps.
* Automated infrastructure updates.
* Consistent deployments.
* Faster development workflow.

---

This architecture balances security, automation, scalability, and maintainability while remaining cost-effective.

---

# 4. Technology Stack

This project combines infrastructure, containerization, database management, and CI/CD automation. The following tools and services were used to design and deploy the system.

---

## Infrastructure Layer

### Amazon VPC

Used to create an isolated virtual network environment. It provides full control over IP addressing, subnets, route tables, and internet access.

### Public and Private Subnets

Public subnets host the Application Load Balancer and NAT Gateway.
Private subnets host ECS tasks and the RDS database to ensure security and isolation.

### Internet Gateway

Allows inbound and outbound internet connectivity for resources in public subnets.

### NAT Gateway

Allows resources in private subnets to access the internet for outbound traffic without exposing them publicly.

---

## Compute Layer

### Amazon ECS (Elastic Container Service)

Manages and orchestrates containerized applications.

### AWS Fargate

Serverless compute engine for ECS. It runs containers without requiring EC2 instance management.

---

## Application Layer

### Strapi

An open-source headless CMS used as the backend application.

### Docker

Used to containerize the Strapi application. Ensures consistent builds and environment across systems.

---

## Database Layer

### Amazon RDS (PostgreSQL)

Managed relational database service used to store application data.

PostgreSQL was selected due to:

* Strong support in Strapi
* ACID compliance
* Reliability in production environments

---

## Load Balancing

### Application Load Balancer (ALB)

Handles incoming HTTP traffic and routes it to ECS tasks. Performs health checks and supports future HTTPS configuration.

---

## Container Registry

### Amazon ECR (Elastic Container Registry)

Stores Docker images securely and integrates directly with ECS.

---

## Monitoring and Logging

### Amazon CloudWatch

Used for:

* Application logs
* ECS metrics (CPU, memory)
* Custom dashboard for monitoring

---

## Identity and Access Management

### AWS IAM

Used to:

* Assign execution roles to ECS tasks
* Avoid hardcoded credentials
* Follow the principle of least privilege

---

## Infrastructure as Code

### Terraform

Used to provision all AWS resources.

Key benefits:

* Modular design
* Version-controlled infrastructure
* Reproducible deployments
* Automated provisioning through CI/CD

---

## CI/CD

### GitHub Actions

Automates the deployment workflow:

1. Builds Docker image
2. Pushes image to ECR
3. Runs Terraform
4. Updates ECS service
5. Waits for service stabilization

This ensures continuous integration and deployment without manual intervention.

---

---

# 5. Networking Design

The networking layer is one of the most important parts of this project. It ensures that the application is accessible to users while keeping internal services secure and isolated.

A custom VPC was created to fully control networking components instead of using the default VPC.

---

## VPC Configuration

A custom VPC was created with a CIDR block similar to:

```
10.0.0.0/16
```

This CIDR range allows enough IP space for public and private subnets and future expansion.

Using a custom VPC provides:

* Better network control
* Isolation from other resources
* Production-style design

---

## Subnet Design

The VPC is divided into:

* 2 Public Subnets
* 2 Private Subnets

This design supports high availability across multiple Availability Zones.

---

### Public Subnets

Public subnets contain:

* Application Load Balancer (ALB)
* NAT Gateway

Public subnets are associated with a route table that has:

```
0.0.0.0/0 → Internet Gateway
```

This allows:

* ALB to receive traffic from users
* NAT Gateway to communicate with the internet

---

### Private Subnets

Private subnets contain:

* ECS Fargate tasks
* RDS PostgreSQL database

Private subnets are associated with a route table that has:

```
0.0.0.0/0 → NAT Gateway
```

This allows:

* ECS tasks to pull Docker images from ECR
* ECS tasks to access external services if needed

But it prevents:

* Direct inbound internet access

The database and containers remain isolated from public traffic.

---

## Internet Gateway

The Internet Gateway is attached to the VPC.

It allows:

* Inbound internet access to public subnets
* Outbound internet access from public subnets

Only resources in public subnets can directly use the Internet Gateway.

---

## NAT Gateway

The NAT Gateway is placed inside a public subnet.

It allows:

* Private subnets to access the internet for outbound traffic
* No inbound connections from the internet

This ensures:

* Secure internet access for ECS tasks
* No public exposure of application containers

---

## Security Groups

Security groups are used as virtual firewalls.

### ALB Security Group

* Allows inbound HTTP (port 80) from 0.0.0.0/0
* Allows outbound traffic to ECS

This allows users to access the application.

---

### ECS Security Group

* Allows inbound traffic only from ALB Security Group on port 1337
* Allows outbound traffic to RDS and NAT

This ensures:

* ECS is not publicly accessible
* Only ALB can communicate with ECS

---

### RDS Security Group

* Allows inbound traffic only from ECS Security Group on port 5432
* No public access

This ensures:

* Only the application can connect to the database
* Database is not exposed to the internet

---

## Traffic Isolation Summary

The networking design ensures:

* Only ALB is publicly accessible.
* ECS tasks do not have public IP addresses.
* RDS is fully private.
* All internal communication is controlled through security groups.
* Outbound internet access from private subnets is handled through NAT Gateway.

This design follows secure AWS networking best practices and mirrors real-world cloud environments.


---

# 6. Security Implementation

Security was a major consideration while designing this architecture. The goal was to ensure that only required services are publicly accessible, while internal components remain protected.

The design follows the principle of least privilege and layered security.

---

## Network-Level Security

### Database Is Not Publicly Accessible

The RDS PostgreSQL instance is deployed inside private subnets with:

* Public accessibility disabled
* No route to the Internet Gateway
* Access restricted through security groups

This ensures that the database cannot be accessed directly from the internet.

---

### ECS Tasks Do Not Have Public IPs

ECS Fargate tasks are deployed in private subnets with:

* `assign_public_ip = false`

This ensures that containers cannot be directly accessed from the internet. All traffic must pass through the Application Load Balancer.

---

### Load Balancer as the Only Entry Point

The Application Load Balancer is the only resource exposed to the internet.

Security group configuration:

* Allows inbound HTTP traffic on port 80 from all IP addresses
* Forwards traffic only to ECS target group

This ensures controlled public access.

---

## Security Group Isolation

Security groups are configured to enforce strict communication rules.

### ALB Security Group

* Inbound: HTTP (port 80) from 0.0.0.0/0
* Outbound: Allowed to ECS security group

---

### ECS Security Group

* Inbound: Port 1337 only from ALB security group
* Outbound: Allowed to RDS security group and NAT Gateway

This prevents direct internet traffic to containers.

---

### RDS Security Group

* Inbound: Port 5432 only from ECS security group
* No public access

This ensures that only the application can communicate with the database.

---

## IAM Roles and Permissions

IAM roles are used instead of storing credentials in code.

### ECS Task Execution Role

This role allows ECS to:

* Pull Docker images from ECR
* Send logs to CloudWatch
* Access required AWS services

No AWS credentials are hardcoded inside the application.

---

## Secrets Handling

Sensitive information such as:

* Database name
* Database username
* Database password
* AWS credentials

are handled using:

* GitHub Actions Secrets (for CI/CD)
* Terraform variables (marked sensitive)

These values are not stored in the repository.

---

## Immutable Image Deployments

Docker images are deployed using Git commit SHA tags instead of the `latest` tag.

Benefits:

* Prevents accidental overwriting
* Enables version tracking
* Makes deployments predictable
* Improves rollback capability

---

## Overall Security Summary

The security design ensures:

* Minimal public exposure
* Strict traffic flow control
* No direct database access
* No public container access
* Secure CI/CD credential management
* IAM-based access control

This layered approach improves system reliability and reduces the risk of unauthorized access.


---

# 7. CI/CD Pipeline Workflow

The deployment process in this project is fully automated using GitHub Actions. Every time code is pushed to the `main` branch, the pipeline builds the Docker image, updates the infrastructure if needed, and deploys the latest version of the application.

This eliminates manual deployment steps and ensures consistency across environments.

---

## Trigger

The workflow is triggered automatically when changes are pushed to the `main` branch.

This ensures:

* Continuous integration
* Continuous deployment
* Faster iteration
* Reduced human error

---

## Pipeline Stages

The CI/CD pipeline performs the following steps:

### 1. Checkout Source Code

The workflow pulls the latest code from the GitHub repository.

---

### 2. Configure AWS Credentials

AWS credentials are securely retrieved from GitHub Secrets and used to authenticate with AWS services.

No credentials are stored in the repository.

---

### 3. Build Docker Image

The Strapi application is built into a Docker image using the Dockerfile inside the `strapi-app` directory.

This ensures a consistent runtime environment.

---

### 4. Tag Docker Image with Git SHA

The image is tagged using the Git commit SHA instead of using `latest`.

Example format:

```
<account-id>.dkr.ecr.<region>.amazonaws.com/strapi-repo:<commit-sha>
```

Using commit SHA ensures:

* Immutable deployments
* Clear version tracking
* No image conflicts

---

### 5. Push Image to Amazon ECR

The Docker image is pushed to Amazon Elastic Container Registry (ECR).

ECR acts as a private image repository integrated with ECS.

---

### 6. Terraform Initialization

Terraform is initialized inside the `terraform` directory using the configured S3 backend.

This ensures:

* Remote state management
* Infrastructure consistency
* Team collaboration support

---

### 7. Terraform Apply

Terraform applies infrastructure changes using the newly built image URI.

If required:

* Task definition is updated
* ECS service is updated
* New deployment is triggered

Infrastructure and application updates happen in the same pipeline.

---

### 8. ECS Service Stabilization

The workflow waits until the ECS service becomes stable.

This ensures:

* The new task is running
* Health checks pass
* Deployment is successful

If the service does not stabilize, the workflow fails.

---

## Deployment Flow Summary

The complete automated flow is:

1. Developer pushes code to GitHub.
2. GitHub Actions builds a Docker image.
3. Image is pushed to ECR.
4. Terraform updates infrastructure.
5. ECS pulls the new image.
6. ALB routes traffic to healthy containers.
7. Application becomes live.

No manual AWS console steps are required during deployment.

---

## Benefits of This Pipeline

* Fully automated deployment
* Version-controlled infrastructure
* Immutable image strategy
* Reduced downtime
* Faster and reliable releases
* Clear separation between application and infrastructure

This CI/CD implementation demonstrates how modern cloud-native applications are deployed in a structured and automated way.

---

# 8. Terraform Module Design

The infrastructure in this project is implemented using a modular Terraform structure. Instead of placing all resources in a single file, each AWS service is separated into its own module.

This approach improves maintainability, readability, and reusability.

---

## Why Modular Terraform?

Using modules provides several advantages:

* Cleaner project structure
* Logical separation of responsibilities
* Easier debugging and updates
* Reusable infrastructure components
* Better scalability for future enhancements

If changes are required for a specific service (for example, ECS or RDS), they can be made inside that module without affecting other components.

---

## Root Module

The root module is located inside the `terraform` directory. It acts as the orchestrator and connects all individual modules together.

It passes:

* VPC ID to other modules
* Subnet IDs to ECS and RDS
* Security group IDs
* Image URI from CI/CD
* Database credentials
* IAM roles

The root module defines how all infrastructure components interact with each other.

---

## Module Breakdown

The `modules` directory contains separate modules for each AWS service.

```
terraform/
└── modules/
    ├── vpc/
    ├── security/
    ├── alb/
    ├── ecs/
    ├── rds/
    ├── ecr/
    └── iam/
```

Each module is responsible for a specific service.

---

### VPC Module

Responsible for:

* Creating the VPC
* Creating public and private subnets
* Creating Internet Gateway
* Creating NAT Gateway
* Creating route tables and associations

This module defines the entire networking foundation.

---

### Security Module

Responsible for:

* Creating ALB security group
* Creating ECS security group
* Creating RDS security group

It ensures controlled communication between components.

---

### ALB Module

Responsible for:

* Creating the Application Load Balancer
* Creating Target Group
* Creating Listener
* Configuring health checks

It defines the public entry point of the application.

---

### ECS Module

Responsible for:

* Creating ECS cluster
* Creating CloudWatch log group
* Creating Task Definition
* Creating ECS Service
* Registering service with ALB target group

This module runs the containerized Strapi application.

---

### RDS Module

Responsible for:

* Creating DB subnet group
* Creating PostgreSQL RDS instance
* Associating security group
* Enabling managed database configuration

This module provides persistent data storage.

---

### ECR Module

Responsible for:

* Creating ECR repository

It stores Docker images for the application.

---

### IAM Module

Responsible for:

* Creating ECS execution role
* Attaching required IAM policies

This module ensures secure access to ECR and CloudWatch without hardcoded credentials.

---

## Dependency Management

Terraform handles module dependencies through:

* Output variables
* Input variables
* Implicit resource references

For example:

* ECS depends on ALB target group
* ECS depends on IAM execution role
* RDS depends on VPC subnets
* Security groups depend on VPC ID

The root module connects these dependencies cleanly without circular references.

---

## Remote State Configuration

Terraform state is stored remotely in an S3 bucket.

Benefits:

* Centralized state storage
* Safe infrastructure tracking
* Avoids local state conflicts
* Supports collaboration

This ensures infrastructure consistency and prevents accidental drift.

---

# 9. Monitoring and Observability

Monitoring and logging are important to ensure that the application is running correctly and to quickly identify issues when they occur.

In this project, Amazon CloudWatch is used for logs, metrics, and dashboard monitoring.

---

## CloudWatch Logs

Each ECS task is configured to send container logs to CloudWatch Logs using the `awslogs` driver.

This allows:

* Viewing application startup logs
* Debugging container failures
* Monitoring runtime errors
* Tracking database connection issues

The log group is automatically created through Terraform and attached to the ECS task definition.

This ensures that:

* Logs are centralized
* Logs are retained for a defined number of days
* No manual logging configuration is required

---

## ECS Service Monitoring

Amazon ECS provides built-in metrics for:

* CPU utilization
* Memory utilization
* Running task count
* Network in and network out

These metrics help monitor:

* Application performance
* Resource usage
* Container health

---

## CloudWatch Dashboard

A custom CloudWatch dashboard is created using Terraform.

The dashboard displays:

* CPU utilization
* Memory utilization
* Running task count
* Network traffic

This provides a centralized visual view of the system health.

It allows quick detection of:

* High CPU usage
* Memory spikes
* Task crashes
* Network anomalies

---

## Application Health Checks

The Application Load Balancer performs health checks on the ECS service.

Health check configuration includes:

* HTTP protocol
* Specific port (1337)
* Defined path
* Healthy and unhealthy thresholds

If a container fails health checks:

* ALB stops routing traffic to it
* ECS replaces the failed task automatically

This improves reliability and availability.

---

## Service Stability in CI/CD

The GitHub Actions workflow includes a step that waits for the ECS service to become stable.

If:

* Tasks fail to start
* Image cannot be pulled
* Database connection fails

The deployment will fail automatically.

This prevents broken versions from being considered successfully deployed.

---

## Observability Summary

The monitoring setup ensures:

* Centralized logging
* Real-time performance metrics
* Automatic health detection
* Deployment validation
* Improved debugging capability

This makes the system easier to maintain and troubleshoot in real-world scenarios.

---

# 10. Challenges Faced and Solutions

During the implementation of this project, several real-world issues were encountered. Each issue required analysis, debugging, and proper resolution. This section documents the key challenges and how they were resolved.

---

## 1. Application Load Balancer Creation Failed

### Issue

While provisioning infrastructure, the Application Load Balancer failed to create with the error:

“This AWS account currently does not support creating load balancers.”

Even though service quotas showed that ALB was allowed, creation failed both via Terraform and AWS Console.

### Root Cause

The AWS account had a temporary service-level restriction on Elastic Load Balancing.

### Solution

* Contacted AWS Support.
* AWS removed the service block on the account.
* After removal, ALB creation succeeded.

This demonstrated the importance of distinguishing between infrastructure misconfiguration and account-level restrictions.

---

## 2. RDS Password Validation Error

### Issue

RDS instance creation failed with:

“MasterUserPassword is not a valid password.”

### Root Cause

The password contained unsupported special characters such as “@”.
RDS has stricter password rules than general systems.

### Solution

* Updated the password to use only allowed ASCII characters.
* Re-ran Terraform apply successfully.

This highlighted the importance of checking AWS service-specific constraints.

---

## 3. ECS Tasks Not Registering in Target Group

### Issue

The Application Load Balancer showed zero healthy targets.

### Root Cause

ECS tasks were failing to start, so no IP addresses were available to register in the target group.

### Solution

* Investigated ECS stopped tasks.
* Identified that containers were failing.
* Resolved underlying image pull issue (see next challenge).

This demonstrated structured debugging through ECS task logs and service events.

---

## 4. CannotPullContainerError

### Issue

ECS tasks failed with:

“CannotPullContainerError: image not found.”

The service attempted to pull:

repository:latest

But the image did not exist.

### Root Cause

The CI/CD pipeline was pushing Docker images using the Git commit SHA tag, while Terraform referenced the “latest” tag.

### Solution

* Modified Terraform to accept `image_uri` as a variable.
* Passed the SHA-based image URI from GitHub Actions.
* Removed dependency on the “latest” tag.

This resulted in immutable deployments and improved deployment reliability.

---

## 5. Terraform Variable Mismatch in CI/CD

### Issue

GitHub Actions failed with:

“Value for undeclared variable image_uri.”

### Root Cause

The root Terraform module did not declare all variables passed via CLI in the workflow.

### Solution

* Updated `variables.tf` in the root module.
* Declared all required variables including `image_uri`.
* Marked sensitive variables appropriately.

This emphasized the importance of matching CLI variables with Terraform declarations.

---

## 6. ECS Service Stabilization Failure in CI/CD

### Issue

The pipeline failed during the `aws ecs wait services-stable` step.

### Root Cause

ECS tasks were continuously failing due to the image pull issue.

### Solution

* Fixed image tagging strategy.
* Ensured correct image URI passed to Terraform.
* Verified successful container startup before rerunning pipeline.

This showed how CI/CD stabilization checks prevent broken deployments.

---

## Key Learnings

From these challenges, several key lessons were reinforced:

* Always check ECS task logs when services fail.
* Avoid using the “latest” Docker tag in production.
* Understand AWS service-specific restrictions.
* Use SHA-based immutable image deployments.
* Separate account-level issues from configuration issues.
* Validate infrastructure variables carefully.
* Debug systematically from logs and error messages.

These real troubleshooting experiences significantly improved understanding of AWS, Terraform, and CI/CD workflows.

---

# 11. Results and Final Outcome

After completing the infrastructure setup, debugging issues, and validating deployments, the system was successfully deployed and verified.

The final architecture is fully functional and follows secure cloud design principles.

---

## Application Deployment

* The Strapi application is successfully deployed using ECS Fargate.
* The application is accessible through the Application Load Balancer DNS endpoint.
* Health checks pass successfully.
* ECS service maintains the desired running task count.

The application can be accessed through:

```
http://<alb-dns-name>
```

---

## Database Connectivity

* The PostgreSQL RDS instance is running and available.
* The database is deployed inside private subnets.
* Public access is disabled.
* Strapi successfully connects to the database.
* Admin login and data persistence are verified.

This confirms proper internal communication between ECS and RDS.

---

## Networking Validation

* Public access is restricted to the Application Load Balancer.
* ECS tasks do not have public IP addresses.
* RDS is not publicly accessible.
* Private subnets route outbound traffic through NAT Gateway.
* Security groups strictly control traffic flow.

The network isolation is functioning as designed.

---

## CI/CD Automation

* GitHub Actions successfully builds Docker images.
* Images are pushed to Amazon ECR.
* Terraform automatically updates infrastructure.
* ECS service updates with new image revisions.
* Service stabilization is verified during deployment.

This confirms that the entire deployment process is automated.

---

## Monitoring and Logging

* ECS logs are available in CloudWatch.
* CPU and memory utilization are visible in the dashboard.
* Running task count is monitored.
* ALB health checks function correctly.

This ensures observability and operational visibility.

---

## Infrastructure as Code Validation

* All AWS resources are provisioned using Terraform.
* Infrastructure state is stored remotely in S3.
* Modules are structured and reusable.
* Changes are version-controlled.

The environment can be recreated consistently using Terraform.

---

## Overall Outcome

This project demonstrates:

* Secure multi-tier AWS architecture
* Containerized application deployment
* Private database configuration
* Automated CI/CD pipeline
* Modular Infrastructure as Code design
* Practical troubleshooting and debugging experience

The final setup reflects real-world cloud deployment practices and provides a strong foundation for further enhancements such as HTTPS, custom domain integration, and auto scaling.

---

