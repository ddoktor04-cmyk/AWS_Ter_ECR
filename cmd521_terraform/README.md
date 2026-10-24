# Terraform - AWS ECS Fargate + ECR (ToDoAI)

Deploys the [ToDoAI](https://github.com/macnaer/ToDoAI) web app (React + Vite,
static files served by `vite preview` inside the container) to AWS:

- **`modules/ecr`** - ECR repository `todoai` for the application image.
- **`modules/ecs`** - ECS cluster, Fargate service (1 task, 256 CPU / 512 MiB),
  task definition, IAM roles, CloudWatch log group, internet-facing ALB
  (HTTP :80, `target_type = ip`).

Region: **`eu-north-1`** (Stockholm). Cost profile: 1 Fargate task + 1 ALB.

## 1. Prerequisites

| Tool | Version |
|------|---------|
| Terraform | >= 1.3 |
| AWS access | EC2/ECR/ECS/IAM rights for the Student user |

## 2. Credentials

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
notepad terraform.tfvars   # fill in aws_access_key / aws_secret_key
```

`terraform.tfvars` is gitignored. Never commit it.

## 3. Deploy

```powershell
terraform init
terraform plan
terraform apply
```

Useful outputs: `ecs_alb_url`, `ecr_repository_url`.

## 4. Application image workflow

1. `terraform apply` with `app_image = "nginx:latest"` - smoke-test the stack.
2. Build the app image (on a Linux host with Docker):

   ```bash
   git clone https://github.com/macnaer/ToDoAI.git
   cd ToDoAI
   docker build --provenance=false -t todoai:latest .
   ```

3. Push to ECR:

   ```bash
   aws ecr get-login-password --region eu-north-1 | \
     docker login --username AWS --password-stdin <account>.dkr.ecr.eu-north-1.amazonaws.com
   docker tag todoai:latest <account>.dkr.ecr.eu-north-1.amazonaws.com/todoai:latest
   docker push <account>.dkr.ecr.eu-north-1.amazonaws.com/todoai:latest
   ```

4. Set `app_image = "<account>.dkr.ecr.eu-north-1.amazonaws.com/todoai:latest"`
   in `terraform.tfvars` and `terraform apply` - ECS rolls a new task
   definition revision; the deployment circuit breaker rolls back on failure.

## 5. Layout

```
cmd521_terraform/
├── main.tf / variables.tf / outputs.tf / providers.tf / versions.tf
├── terraform.tfvars.example
└── modules/
    ├── ecr/   # main.tf, variables.tf, outputs.tf
    └── ecs/   # main.tf, iam.tf, network.tf, service.tf, variables.tf, outputs.tf
```

## 6. Notes

- Default VPC + default subnets are used when `vpc_id` / `public_subnet_ids`
  are omitted; the ALB and service require at least 2 default subnets (AZs).
- The ECS task security group only accepts port 80 from the ALB security group.
- This project intentionally contains **no EC2, no S3, no legacy ALB** - cost
  minimization was an explicit requirement.
