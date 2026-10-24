###############################################################################
# MODULE: ecr                                                                 #
# Address prefix in state/plan:  module.ecr                                   #
# Provisions:  ECR repository for the application container image             #
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

resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = merge(local.common_tags, { Name = var.repository_name })
}
