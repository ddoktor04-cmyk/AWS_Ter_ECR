output "ecr_repository_url" {
  description = "Full URI of the ECR repository for the application image"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.ecr.repository_arn
}

output "ecr_registry_id" {
  description = "AWS account ID that owns the ECR registry (used for docker login)"
  value       = module.ecr.registry_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

output "ecs_task_definition_arn" {
  description = "ARN of the current ECS task definition revision"
  value       = module.ecs.task_definition_arn
}

output "ecs_alb_dns_name" {
  description = "Public DNS name of the ALB in front of the ECS service"
  value       = module.ecs.alb_dns_name
}

output "ecs_alb_url" {
  description = "Full HTTP URL of the ALB in front of the ECS service"
  value       = module.ecs.alb_url
}
