
---

# Deploy Strapi on AWS using ECS Fargate with Terraform and GitHub Actions (CI/CD)

## Task Title

Deploy a Strapi application on AWS using ECS Fargate, fully managed with Terraform and automated using GitHub Actions CI/CD pipeline.
Enable CloudWatch Monitoring for logging and metrics collection.

---

## Overview

The objective of this project is to deploy a production-ready Strapi application on AWS without using manual console operations.

The complete infrastructure is provisioned using Terraform.
The deployment process is fully automated using GitHub Actions.
Monitoring and logging are configured using AWS CloudWatch.

No manual `terraform apply` is executed in production.
All deployments happen automatically when code is pushed to the main branch.

---

## Approach

We followed these steps:

1. Containerized the Strapi application using Docker.
2. Created modular Terraform code for infrastructure provisioning.
3. Configured AWS ECS Fargate to run the container.
4. Used Amazon ECR to store Docker images.
5. Used Amazon RDS (PostgreSQL) as the database.
6. Implemented GitHub Actions for CI/CD automation.
7. Enabled CloudWatch Logs and Metrics for monitoring.

All infrastructure components are created and managed through Terraform.

---

## Architecture Overview

The architecture consists of the following components:

* Amazon ECR – Stores the Docker image of Strapi
* Amazon ECS (Fargate) – Runs the Strapi container
* Amazon RDS (PostgreSQL) – Stores application data
* Security Groups – Controls network access
* Default VPC and Subnets – Provides networking
* CloudWatch Logs – Stores container logs
* CloudWatch Metrics – Monitors CPU, memory, network, and task count
* GitHub Actions – Automates build and deployment

Flow:

Developer Push → GitHub Actions → Build Docker Image → Push to ECR → Terraform Apply → ECS Deployment → CloudWatch Monitoring

---

## Repository Structure

```
strapi-ecs-ec2-terraform/
│
├── strapi-app/                # Strapi application
│   ├── Dockerfile
│   └── config/
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── security/
│       ├── ecr/
│       ├── rds/
│       └── ecs/
│
└── .github/workflows/
    └── deploy.yml
```

---

## Terraform Modules Explanation

### 1. Security Module

* Creates ECS Security Group
* Allows inbound traffic on port 1337
* Creates RDS Security Group
* Allows PostgreSQL (5432) access only from ECS

Purpose: Secure communication between ECS and RDS.

---

### 2. ECR Module

* Creates an Amazon ECR repository
* Stores Docker images built by GitHub Actions

Purpose: Central image registry for ECS deployments.

---

### 3. RDS Module

* Creates PostgreSQL database instance
* Uses db.t3.micro instance
* Configures subnet group
* Attaches security group

Purpose: Persistent database storage for Strapi.

---

### 4. ECS Module

Creates:

* ECS Cluster
* ECS Task Definition (Fargate)
* ECS Service
* CloudWatch Log Group

Task Definition includes:

* CPU: 512
* Memory: 1024
* awsvpc networking
* Environment variables for database connection
* awslogs configuration for CloudWatch logging

Service configuration:

* Fargate launch type
* Public subnet
* assign_public_ip = true
* Desired count = 1

Purpose: Run and manage the Strapi container.

---

## GitHub Actions Workflow Explanation

Workflow file: `.github/workflows/deploy.yml`

Trigger:

* Push to main branch

Steps:

1. Checkout repository
2. Configure AWS credentials
3. Login to Amazon ECR
4. Build Docker image
5. Tag image with Git commit SHA
6. Push image to ECR
7. Run `terraform init`
8. Run `terraform apply`
9. Wait for ECS service to stabilize
10. Fetch and print public IP

This ensures:

* Infrastructure provisioning
* Container deployment
* Fully automated CI/CD pipeline

No manual deployment is required.
<img width="1893" height="880" alt="Screenshot 2026-02-19 132014" src="https://github.com/user-attachments/assets/d55dacc8-acca-4e33-b366-e9a2b689f0fd" />

<img width="1889" height="973" alt="Screenshot 2026-02-19 131944" src="https://github.com/user-attachments/assets/fb4b564b-8aad-4148-9e8d-54e0cbdb3b9f" />

---

## Monitoring and Logging

CloudWatch Log Group:

/ecs/strapi-akash

Configured in ECS task definition using:

* logDriver = awslogs
* awslogs-stream-prefix = ecs

This captures container logs.

CloudWatch Metrics Enabled:

* CPUUtilized
* MemoryUtilized
* RunningTaskCount
* NetworkRxBytes (Network In)
* NetworkTxBytes (Network Out)

These metrics confirm:

* Application health
* Resource usage
* Network traffic
* Task availability

Monitoring ensures production readiness and observability.
<img width="1904" height="788" alt="Screenshot 2026-02-19 143459" src="https://github.com/user-attachments/assets/3f0aec45-bd03-4c67-bc1a-6793c7fb9da6" />
<img width="1917" height="822" alt="Screenshot 2026-02-19 144303" src="https://github.com/user-attachments/assets/9031a659-efb9-4700-b948-9e8fe8b1044f" />

---

## Final Result

* Strapi application deployed successfully on ECS Fargate
* Infrastructure fully managed with Terraform
* CI/CD automated using GitHub Actions
* Logging configured with CloudWatch
* Metrics monitored through CloudWatch Container Insights
* No manual console deployment

This implementation demonstrates Infrastructure as Code, containerization, CI/CD automation, and production-level monitoring using AWS services.

---
