###############################################################################
# MODULE: ecs                                                                 #
# Address prefix in state/plan:  module.ecs                                   #
# Provisions:  ECS Fargate cluster + ALB (HTTP :80) + service running         #
#              var.app_image (nginx by default, ECR image after promotion)    #
###############################################################################

locals {
  common_tags = merge(
    var.tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

###############################################################################
# Data sources: resolve VPC and public subnets                               #
# Defaults to the account's default VPC and its default-per-AZ subnets       #
# if not explicitly provided via module inputs                               #
###############################################################################

data "aws_vpc" "default" {
  count   = var.vpc_id == null ? 1 : 0
  default = true
}

data "aws_subnets" "default" {
  count = var.public_subnet_ids == null ? 1 : 0

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

locals {
  resolved_vpc_id = (
    var.vpc_id != null
    ? var.vpc_id
    : data.aws_vpc.default[0].id
  )
  resolved_public_subnet_ids = (
    var.public_subnet_ids != null
    ? var.public_subnet_ids
    : data.aws_subnets.default[0].ids
  )
}

###############################################################################
# ECS cluster and CloudWatch Logs group                                      #
###############################################################################

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = merge(local.common_tags, { Name = var.cluster_name })
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.service_name}"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, { Name = "/ecs/${var.service_name}" })
}
