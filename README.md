# ShopSmart

ShopSmart now uses a single production container:

1. Build React client with Vite.
2. Copy client build output into backend as static files.
3. Serve both API and frontend from Express.

This is implemented in the root `Dockerfile` and `server/src/app.js`.

## Local Docker Run

```bash
docker build -t shopsmart:local .
docker run --rm -p 5001:5001 shopsmart:local
```

Open `http://localhost:5001`.

## EC2 Pull and Run (Docker)

After provisioning Docker on EC2:

```bash
aws ecr get-login-password --region <aws-region> \
| docker login --username AWS --password-stdin <account-id>.dkr.ecr.<aws-region>.amazonaws.com

docker pull <account-id>.dkr.ecr.<aws-region>.amazonaws.com/<repo-name>:latest

docker stop shopsmart || true
docker rm shopsmart || true
docker run -d --name shopsmart --restart unless-stopped -p 80:5001 \
	<account-id>.dkr.ecr.<aws-region>.amazonaws.com/<repo-name>:latest
```

## Section 1 -- Amazon ECR: Container Registry (3 Marks)

### 1.1 ECR Repo Setup

Create a private ECR repo (example):

```bash
aws ecr create-repository --repository-name shopsmart --region <aws-region>
```

Set GitHub repository variable:

1. `ECR_REPOSITORY=shopsmart`

### 1.2 Image Pushed

Image push is handled by GitHub Actions workflow:

1. `.github/workflows/deploy-ecs.yml`
2. Uses `aws-actions/amazon-ecr-login@v2`
3. Builds with root `Dockerfile`
4. Pushes image to ECR

### 1.3 Tagging Strategy

Tags generated automatically:

1. `sha-<commit>` (immutable)
2. `latest` (default branch)
3. `<branch-name>`

Configured in `docker/metadata-action` in the deploy workflow.

## Section 2 -- Amazon ECS: Container Orchestration (3 Marks)

### 2.1 ECS Cluster

Create ECS cluster (EC2 or Fargate). Set GitHub variable:

1. `ECS_CLUSTER=<your-cluster-name>`

### 2.2 Task Definition

Task definition template is included at:

1. `infra/ecs/task-definition.json`

Container name in task definition is `shopsmart-app` and must match workflow variable `CONTAINER_NAME`.

### 2.3 Service Running

Create ECS service once, then CI/CD updates it automatically. Set GitHub variable:

1. `ECS_SERVICE=<your-service-name>`

Workflow uses `amazon-ecs-deploy-task-definition` with `wait-for-service-stability: true`.

## Section 3 -- CI/CD Pipeline: GitHub Actions -> ECR -> ECS (4 Marks)

### 3.1 Dockerfile

Root `Dockerfile` is multi-stage:

1. Stage `client-build`: `npm run build` in `client`
2. Stage `server-build`: install production dependencies in `server`
3. Final stage: copy `client/dist` to `server/public`, run Node server

### 3.2 Workflow File

Workflow path:

1. `.github/workflows/deploy-ecs.yml`

### 3.3 Build & Push

Implemented with:

1. `docker/build-push-action@v6`
2. ECR login via AWS action
3. Tag/label generation via metadata action

### 3.4 Full Automation

On every push to `main`, pipeline does all steps end-to-end:

1. Authenticate to AWS (OIDC role)
2. Build image
3. Push image to ECR
4. Render ECS task definition with new image
5. Deploy updated task definition to ECS service

## Required GitHub Repo Configuration

### Secrets

1. `AWS_ROLE_TO_ASSUME`

### Variables

1. `AWS_REGION`
2. `ECR_REPOSITORY`
3. `ECS_CLUSTER`
4. `ECS_SERVICE`

## Notes

1. Existing `ci.yml` can continue for test/build checks.
2. Deployment automation is isolated in `deploy-ecs.yml`.
