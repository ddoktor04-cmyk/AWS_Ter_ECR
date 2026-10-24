###############################################################################
# MODULE: ecs                                                                 #
# Inputs for the ECS Fargate service behind an internet-facing ALB            #
###############################################################################

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "CMD521"
}

variable "environment" {
  description = "Environment name (dev/staging/prod) applied as a tag"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "ID of the VPC where the ALB and ECS tasks will be deployed. If null, the account's default VPC is used."
  type        = string
  default     = null
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs in different AZs for the ALB and tasks. If null, the default subnets of the resolved VPC are used (one per AZ)."
  type        = list(string)
  default     = null
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "ecs-cmd521"
}

variable "service_name" {
  description = "Name of the ECS service (also used for IAM roles, log group and task family)"
  type        = string
  default     = "todoai"
}

variable "container_name" {
  description = "Name of the container inside the task definition"
  type        = string
  default     = "app"
}

variable "app_image" {
  description = "Container image URI for the service (nginx:latest initially, ECR ToDoAI image after promotion)"
  type        = string
  default     = "nginx:latest"
}

variable "container_port" {
  description = "Port the container listens on and the target group forwards to"
  type        = number
  default     = 80
}

variable "cpu" {
  description = "Fargate task CPU units (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of tasks the service should keep running"
  type        = number
  default     = 1
}

variable "alb_name" {
  description = "Name of the Application Load Balancer in front of the ECS service"
  type        = string
  default     = "alb-ecs-cmd521"
}

variable "target_group_name" {
  description = "Name of the ALB target group (ip target type, Fargate)"
  type        = string
  default     = "tg-ecs-cmd521"
}

variable "health_check_path" {
  description = "HTTP path used by the ALB to perform health checks"
  type        = string
  default     = "/"
}

variable "health_check_matcher" {
  description = "HTTP response codes the ALB considers healthy"
  type        = string
  default     = "200-399"
}

variable "log_retention_days" {
  description = "Retention period in days for the ECS CloudWatch log group"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Additional tags applied to every resource that supports tagging"
  type        = map(string)
  default     = { ManagedBy = "Terraform" }
}
