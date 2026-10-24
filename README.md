# AWS_Ter_ECR — ToDoAI on ECS Fargate + ECR

Terraform stack that deploys the [ToDoAI](https://github.com/macnaer/ToDoAI) web app
(React + Vite, container image built from source) to AWS ECS Fargate behind an
Application Load Balancer. The container image lives in Amazon ECR.

**Live site:** http://alb-ecs-cmd521-2125570947.eu-north-1.elb.amazonaws.com

## Lab checklist

| # | Task | How it was done |
|---|------|-----------------|
| 1 | Terraform project + keys | `cmd521_terraform/` with modules `ecr` + `ecs`; `key2.pem` / `key_Student.txt` gitignored |
| 2 | ECS with nginx | `terraform apply` with `app_image = "nginx:latest"` |
| 3 | Docker image from GitHub | built `macnaer/ToDoAI` on build server `172.14.50.148` (`docker build --provenance=false`) |
| 4 | ECR repository | `modules/ecr` → repo `todoai` (MUTABLE tags, scan on push) |
| 5 | Push image to ECR | `docker login` + `docker push .../todoai:latest` |
| 6 | Update ECS to new image | `app_image` → ECR URI, `terraform apply -target module.ecs` (circuit breaker + rollback on) |
| 7 | Push everything to git | this repository, secrets stay local |

Detailed documentation: [cmd521_terraform/README.md](cmd521_terraform/README.md)

## Architecture

```
Internet ──► ALB (HTTP :80) ──► ECS Fargate task (ToDoAI image) ──► ECR repo "todoai"
                                     │
                                     └── logs ──► CloudWatch "/ecs/todoai"
```

- Region: `eu-north-1` (Stockholm), account `989346119941`
- Fargate task: 256 CPU / 512 MiB, 1 task, public IP, health check `/`
- Cost profile: 1 Fargate task + 1 ALB (no EC2, no S3 — old modules removed deliberately)

## Repository layout

```
.
├── README.md                     # this file
├── .gitignore                    # keys, tfvars, state — never committed
└── cmd521_terraform/
    ├── main.tf                   # module "ecr" + module "ecs"
    ├── variables.tf / outputs.tf / providers.tf / versions.tf
    ├── terraform.tfvars.example  # template; real terraform.tfvars is gitignored
    └── modules/
        ├── ecr/                  # ECR repository
        └── ecs/                  # cluster, ALB, service, task def, IAM, logs
```

## Quick start

```powershell
cd cmd521_terraform
Copy-Item terraform.tfvars.example terraform.tfvars   # fill AWS keys + region
terraform init
terraform plan
terraform apply
```

Outputs: `ecs_alb_url`, `ecr_repository_url`.

## Updating the application image

```bash
# on the build host (Docker + AWS CLI required)
git clone https://github.com/macnaer/ToDoAI.git && cd ToDoAI
docker build --provenance=false -t todoai:latest .
aws ecr get-login-password --region eu-north-1 | \
  docker login --username AWS --password-stdin <account>.dkr.ecr.eu-north-1.amazonaws.com
docker tag todoai:latest <account>.dkr.ecr.eu-north-1.amazonaws.com/todoai:latest
docker push <account>.dkr.ecr.eu-north-1.amazonaws.com/todoai:latest
```

Then set `app_image = "<account>.dkr.ecr.eu-north-1.amazonaws.com/todoai:latest"`
in `terraform.tfvars` and run `terraform apply -target module.ecs`.
ECS rolls a new task definition revision; on failure the circuit breaker rolls back.

## Security notes

- `key2.pem`, `key_Student.txt`, `terraform.tfvars`, `*.tfstate` are gitignored.
- ALB accepts HTTP :80 from anywhere — demo only.
- ECS task security group accepts port 80 only from the ALB security group.
