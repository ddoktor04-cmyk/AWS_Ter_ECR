###############################################################################
# MODULE: ecs - outputs                                                       #
###############################################################################

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.this.arn
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.this.name
}

output "task_definition_arn" {
  description = "ARN of the current task definition revision"
  value       = aws_ecs_task_definition.this.arn
}

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer in front of ECS"
  value       = aws_lb.this.dns_name
}

output "alb_url" {
  description = "Full HTTP URL of the Application Load Balancer"
  value       = "http://${aws_lb.this.dns_name}"
}

output "alb_zone_id" {
  description = "Canonical hosted zone ID of the ALB (for Route53 alias records)"
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.this.arn
}

output "security_group_alb_id" {
  description = "ID of the security group attached to the ALB"
  value       = aws_security_group.alb.id
}

output "security_group_tasks_id" {
  description = "ID of the security group attached to ECS tasks"
  value       = aws_security_group.tasks.id
}

output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.task_execution.arn
}

output "task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.task.arn
}
