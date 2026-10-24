variable "aws_access_key" {
  description = "AWS access key for authentication"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key for authentication"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-north-1"
}

variable "app_image" {
  description = "Container image URI for the ECS service (nginx:latest initially, ECR ToDoAI image after promotion)"
  type        = string
  default     = "nginx:latest"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository that stores the application image"
  type        = string
  default     = "todoai"
}

variable "vpc_id" {
  description = "ID of the VPC where the ALB and ECS tasks will be deployed. If null, the account's default VPC is used."
  type        = string
  default     = null
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs in different AZs for the ALB and tasks. If null, the default subnets of the resolved VPC are used."
  type        = list(string)
  default     = null
}
