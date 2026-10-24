# Project Context: Terraform AWS (ECS Fargate + ECR)

System context for AI coding agents (opencode, aider, cursor, etc.).
Read this first before proposing any change to the repository.

---

## 1. What this repo is

Infrastructure-as-Code for AWS, written in Terraform, in the **`eu-north-1`**
region (Stockholm). The stack deploys the **ToDoAI** web app
(https://github.com/macnaer/ToDoAI) as an ECS Fargate service behind an
internet-facing ALB, with the container image stored in ECR.

| Module | State prefix | What it builds |
|--------|--------------|----------------|
| `ecr`  | `module.ecr` | ECR repository `todoai` (MUTABLE tags, scan on push) |
| `ecs`  | `module.ecs` | ECS cluster + Fargate service + task definition + ALB (HTTP :80) + IAM roles + CloudWatch log group |

The root module (`main.tf`) contains **no inline resources** — only `module`
blocks that call into `./modules/<name>`. Anything new at root level must also
be wrapped in a module.

> Historical note: this project previously also contained `ec2`, `alb` and
> `s3-static-website` modules. They were removed to minimize AWS cost. No EC2,
> S3 or legacy ALB resources should remain in the account.

## 2. Project layout

```.
.
├── AGENTS.md                    # this file (system context)
├── README.md                    # human-facing docs
├── opencode.json                # opencode config + skills paths
├── versions.tf                  # Terraform >= 1.3, hashicorp/aws ~> 6.0
├── providers.tf                 # AWS provider (region + access/secret)
├── main.tf                      # module "ecr" + module "ecs"
├── variables.tf                 # all root-level inputs (incl. sensitive creds)
├── outputs.tf                   # aggregated outputs from both modules
├── terraform.tfvars             # REAL secrets - gitignored
├── terraform.tfvars.example     # template - committed
└── modules/
    ├── ecr/                     # ECR repository
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── ecs/                     # ECS Fargate + ALB + IAM + logs
        ├── main.tf              # cluster, log group, VPC/subnet resolution
        ├── iam.tf               # task execution + task roles
        ├── network.tf           # security groups, ALB, target group, listener
        ├── service.tf           # task definition + service
        ├── variables.tf
        └── outputs.tf
```

Each `modules/<name>/main.tf` starts with a banner:

```hcl
# MODULE: <name>
# Address prefix in state/plan:  module.<name>
# Provisions: <one-line summary>
```

## 3. Hard-coded defaults (used unless overridden in `terraform.tfvars`)

| Variable | Default | Used by |
|----------|---------|---------|
| `aws_region`           | `eu-north-1` | provider |
| `ecr_repository_name`  | `todoai` | `ecr` |
| `app_image`            | `nginx:latest` (tfvars overrides with the ECR ToDoAI image) | `ecs` |
| `cluster_name`         | `ecs-cmd521` | `ecs` |
| `service_name`         | `todoai` | `ecs` |
| `container_name/port`  | `app` / `80` | `ecs` |
| `cpu` / `memory`       | `256` / `512` (Fargate) | `ecs` |
| `desired_count`        | `1` | `ecs` |
| `alb_name`             | `alb-ecs-cmd521` | `ecs` |
| `target_group_name`    | `tg-ecs-cmd521` (`target_type = "ip"`) | `ecs` |
| `health_check_path`    | `/` (`200-399`) | `ecs` |
| `vpc_id` / `public_subnet_ids` | `null` → default VPC + default subnets | `ecs` |

## 4. Coding conventions

- **Language:** all code, comments, variable names, descriptions, READMEs in
  **English** (regardless of the human conversation language).
- **Indentation:** 2 spaces. Run `terraform fmt -recursive` after every change.
- **Naming:** `snake_case` for variables, locals, resources.
- **Tagging:** every resource gets `merge(local.common_tags, { Name = "..." })`
  with `Project = "CMD521"`, `Environment = "dev"`, `ManagedBy = "Terraform"`.
- **Sensitive vars:** `aws_access_key`, `aws_secret_key` — `sensitive = true`,
  only ever set in `terraform.tfvars` (gitignored).
- **Descriptions:** every `variable`, `output`, `locals` block has a `description`.
- **No inline resources at root.** Wrap everything in `modules/<name>/`.
- **No hardcoded credentials anywhere.**

## 5. Module-specific notes

### 5.1 `ecr`
- `force_delete = true` (demo convenience — deletes images with the repo).
- `image_tag_mutability = "MUTABLE"` so `:latest` can be re-pushed.

### 5.2 `ecs`
- Fargate launch type, `awsvpc`, tasks get `assign_public_ip = true`
  (needed for image pulls from Docker Hub/ECR in public subnets).
- VPC resolution mirrors the removed `alb` module:
  - `vpc_id == null` → `data "aws_vpc" "default" { default = true }`
  - `public_subnet_ids == null` → default-per-AZ subnets
- `aws_lb` and `aws_ecs_service` have `lifecycle.precondition` requiring
  `length(local.resolved_public_subnet_ids) >= 2`.
- Deployment circuit breaker with rollback is enabled.
- Task images: start with `nginx:latest`, then
  `"<account>.dkr.ecr.eu-north-1.amazonaws.com/todoai:latest"`.

## 6. Required workflow for any change

1. Read this file and the relevant module's `*.tf` first.
2. Present a plan (resources to add/modify/destroy, risks) and get explicit
   user approval.
3. Make the change.
4. `terraform fmt -recursive`.
5. `terraform init -input=false` (if providers/modules changed).
6. `terraform validate` — must succeed.
7. `terraform plan` — show the diff to the user.
8. Only on explicit approval → `terraform apply`.
9. Never auto-commit. Never auto-push unless the user explicitly asked.

## 7. PowerShell 5.1 gotchas (this is a Windows env)

- Use `-target module.x` (space-separated) when applying a single module.
- All `cd` workdir via the tool's `workdir` parameter, not `Set-Location`.
- Quote any path containing spaces. `key_Student.txt` lives in the **repo
  parent directory's working tree root**, not inside `cmd521_terraform/`.

## 8. Security baseline (non-negotiable)

- `terraform.tfstate*`, all `*.tfvars` (except `*.example*`), `*.pem`,
  `key_Student.txt` — must stay in `.gitignore` (root `.gitignore` covers all).
- AWS credentials — only in `terraform.tfvars`, never in `.tf` files, never in git.
- ALB security group allows HTTP 80 from `0.0.0.0/0` — demo only.
- Tasks allow egress all — required for image pulls.
- Do not store long-lived AWS keys on remote build hosts; pass them per
  session and `docker logout` afterwards.

## 9. What NOT to do

- Don't reintroduce EC2/S3/legacy ALB modules — cost minimization is a goal.
- Don't put inline `resource`/`data` blocks at root — wrap in a module.
- Don't add credentials anywhere except `terraform.tfvars`.
- Don't commit `*.tfstate`, `*.tfvars`, `.terraform/`, keys.
- Don't claim a change works without `terraform validate` + `plan`.

## 10. When unsure

Ask the user before implementing, never guess. If a request is ambiguous,
present 2–3 options with a recommended default.
