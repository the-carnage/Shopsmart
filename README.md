# ShopSmart Deployment Guide

ShopSmart runs as one production container.

1. Build React client.
2. Copy built client files into server public folder during image build.
3. Serve API and frontend from Express on port 5001.

---

## Quick Start (Local)

```bash
docker build -t shopsmart:local .
docker run --rm -p 5001:5001 shopsmart:local
```

Open: http://localhost:5001

---

## EC2 Pull and Run

Use these commands on your EC2 machine after Docker is installed:

```bash
aws ecr get-login-password --region <aws-region> \
| docker login --username AWS --password-stdin <account-id>.dkr.ecr.<aws-region>.amazonaws.com

docker pull <account-id>.dkr.ecr.<aws-region>.amazonaws.com/<repo-name>:latest

docker stop shopsmart || true
docker rm shopsmart || true
docker run -d --name shopsmart --restart unless-stopped -p 80:5001 \
  <account-id>.dkr.ecr.<aws-region>.amazonaws.com/<repo-name>:latest
```

App URL from browser: http://<ec2-public-ip>

---

## Section 1 - Amazon ECR: Container Registry (3 Marks)

### 1.1 ECR Repo Setup

Create repository:

```bash
aws ecr create-repository --repository-name shopsmart --region <aws-region>
```

Set GitHub variable:

1. ECR_REPOSITORY=shopsmart

### 1.2 Image Pushed

Image push is automated in GitHub Actions workflow:

1. .github/workflows/deploy-ecs.yml
2. Login to ECR
3. Build image from root Dockerfile
4. Push image to ECR

### 1.3 Tagging Strategy

Workflow produces these tags:

1. sha-<commit-sha> (immutable)
2. latest (default branch)
3. <branch-name>

---

## Section 2 - Amazon ECS: Container Orchestration (3 Marks)

### 2.1 ECS Cluster

Create ECS cluster (EC2 launch type or Fargate), then set GitHub variable:

1. ECS_CLUSTER=<cluster-name>

### 2.2 Task Definition

Task definition file:

1. infra/ecs/task-definition.json

Container name must remain:

1. shopsmart-app

### 2.3 Service Running

Create ECS service once, then CI/CD keeps it updated.

Set GitHub variable:

1. ECS_SERVICE=<service-name>

---

## Section 3 - CI/CD: GitHub Actions -> ECR -> ECS (4 Marks)

### 3.1 Dockerfile

Root Dockerfile is multi-stage:

1. client-build stage builds React app
2. server-build stage installs server production dependencies
3. final stage runs Node server with static frontend

### 3.2 Workflow File

Deployment workflow:

1. .github/workflows/deploy-ecs.yml

### 3.3 Build and Push

Pipeline actions used:

1. aws-actions/amazon-ecr-login
2. docker/metadata-action
3. docker/build-push-action

### 3.4 Full Automation

On push to main branch:

1. Assume AWS role from GitHub OIDC
2. Build image
3. Push image to ECR
4. Inject image into ECS task definition
5. Deploy task definition to ECS service
6. Wait for service stability

---

## Required GitHub Configuration

### Secrets

1. AWS_ROLE_TO_ASSUME

### Variables

1. AWS_REGION
2. ECR_REPOSITORY
3. ECS_CLUSTER
4. ECS_SERVICE

---

## Submission Checklist

1. ECR repo exists and contains pushed image tags
2. ECS cluster, task definition, and service are created
3. GitHub workflow succeeds and deploys latest image automatically
4. App opens from ECS/EC2 endpoint and API health route returns status ok
