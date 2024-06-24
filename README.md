## Hello World Spring Boot Application

This repository provides a simple "Hello World" application built with Spring Boot and packaged for deployment using Docker Compose. It also includes infrastructure as code (IaC) options for deployment to AWS using Terraform.

### Features

* Spring Boot application with a basic REST endpoint responding with "Hello World"
* Docker Compose configuration for local development with two profiles:
    * `default`: uses an in-memory H2 database
    * `postgresql`: uses a PostgreSQL database (requires additional configuration)
* IaC scripts (Python) for building and deploying the application to AWS
* Terraform configuration for infrastructure provisioning on AWS

### Prerequisites

* Docker Engine
* Docker Compose (optional, recommended)
* Python 3 (for IaC scripts)
* AWS CLI (for Terraform deployment)

### Local Development with Docker Compose

1. Build the Docker image:

```bash
docker-compose build
```

2. Run the application in detached mode with the postgresql profile:

```bash
docker-compose up -d
```

3. Access the application:

  * http://localhost:8080/hello/{username}

4. To run the application with the `postgresql` profile, you'll need to configure the connection details. PostgreSQL environment variables are defined in the `compose.yaml` file. You can edit this file to adjust connection settings for your local PostgreSQL instance.

**Note:** Refer to the application code for additional configuration options related to connecting to PostgreSQL.


### Building and Deploying to AWS

**Important:** Before proceeding, run `aws configure` to set up your AWS credentials.

1. Navigate to the `iac` directory.

2. Initialize a pipenv environment and install the needed dependencies:

```bash
pipenv shell
pipenv install
```

3. Build the Docker image and push the image to AWS ECR:

```bash
python3 build_and_push.py
```

4. Deploy the infraestructure and the application to AWS:

```bash
python3 deploy.py
```

This script utilizes Terraform to provision the following infrastructure on AWS:

* **VPC (Virtual Private Cloud):** A logically isolated network segment within your AWS cloud account. The VPC provides a private address space for your application resources.
* **Subnets:** Subdivisions within the VPC that can be public or private. Public subnets allow inbound internet traffic, while private subnets are hidden from the public internet.
* **Security Groups:** Act as firewalls, controlling inbound and outbound traffic to your application resources. The IaC scripts will create security groups to allow necessary traffic for the application to function.
* **ECR (Elastic Container Registry):** A container image registry service that allows you to store, manage, and deploy Docker container images for use in AWS. The IaC scripts will create an ECR repository to store the Docker image of your application.
* **ECS Cluster (Elastic Container Service):** A service for managing and running containerized applications on AWS. The IaC scripts will provision an ECS cluster to orchestrate the deployment of your application containers.
* **ECS Services:** Define how your containerized application runs on the ECS cluster. The IaC scripts will create an ECS service to run your application containers with the desired scaling configuration.
* **Application Load Balancer (ALB)** A highly available load balancer that distributes incoming traffic across your ECS tasks. The IaC scripts will create an Application Load Balancer with target groups pointing to your ECS service instances running in multiple Availability Zones for fault tolerance..

**Note:** This script assumes a basic Terraform configuration is already present in the `iac` directory. You'll need to customize it for your specific AWS environment, including VPC configuration, subnet placement, and security group rules.




