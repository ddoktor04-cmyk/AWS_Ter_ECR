###############################################################################
# MODULE: ecs - IAM roles                                                     #
###############################################################################

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Execution role: used by the ECS agent to pull images and write logs.
# AmazonECSTaskExecutionRolePolicy covers ecr:GetAuthorizationToken,
# layer downloads and logs:PutLogEvents for any log group.
resource "aws_iam_role" "task_execution" {
  name               = "${var.service_name}-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json

  tags = merge(local.common_tags, { Name = "${var.service_name}-exec" })
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task role: permissions for the application running inside the container.
# ToDoAI is fully client-side, so no extra policies are attached.
resource "aws_iam_role" "task" {
  name               = "${var.service_name}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json

  tags = merge(local.common_tags, { Name = "${var.service_name}-task" })
}
