###############################################################################
# MODULE: ecs - networking: security groups, ALB, target group, listener      #
###############################################################################

resource "aws_security_group" "alb" {
  name        = "SG_${var.alb_name}"
  description = "Security group for the ECS Application Load Balancer"
  vpc_id      = local.resolved_vpc_id

  tags = merge(local.common_tags, { Name = "SG_${var.alb_name}" })
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP from internet"
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound"
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group" "tasks" {
  name        = "SG_${var.service_name}_tasks"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = local.resolved_vpc_id

  tags = merge(local.common_tags, { Name = "SG_${var.service_name}_tasks" })
}

resource "aws_security_group_rule" "tasks_ingress_http" {
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  description              = "HTTP from ALB only"
  security_group_id        = aws_security_group.tasks.id
}

resource "aws_security_group_rule" "tasks_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound (image pull, npm build leftovers)"
  security_group_id = aws_security_group.tasks.id
}

resource "aws_lb" "this" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.resolved_public_subnet_ids

  enable_deletion_protection = false

  tags = merge(local.common_tags, { Name = var.alb_name })

  lifecycle {
    precondition {
      condition     = length(local.resolved_public_subnet_ids) >= 2
      error_message = "ECS ALB requires at least 2 public subnets in different AZs. Pass var.public_subnet_ids explicitly or ensure the default VPC has at least 2 default subnets."
    }
  }
}

resource "aws_lb_target_group" "this" {
  name        = var.target_group_name
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = local.resolved_vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = var.health_check_path
    matcher             = var.health_check_matcher
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }

  tags = merge(local.common_tags, { Name = var.target_group_name })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = merge(local.common_tags, { Name = "${var.alb_name}-http" })
}
