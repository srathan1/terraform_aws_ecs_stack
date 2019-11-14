variable "stack_name" {}
variable "env_suffix" {}
variable "albsgs" {
  type = list(string)
}
variable "albsubnetids" {
  type = list(string)
}
variable "vpc_id" {}

resource "aws_alb" "alb-resource" {
  name            = "${var.stack_name}-${var.env_suffix}"
  internal        = true
  security_groups = var.albsgs
  subnets         = var.albsubnetids

  enable_deletion_protection = false
  idle_timeout = 360

  tags = {
    Environment = var.env_suffix
  }
}

resource "aws_alb_target_group" "default-tg" {
  depends_on = [aws_alb.alb-resource]
  name     = "${var.stack_name}-${var.env_suffix}-Default"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  deregistration_delay = 60
  slow_start = 180
  health_check {
    protocol = "HTTP"
    interval = 30
    timeout =29
    path = "/"
    healthy_threshold = 2
    unhealthy_threshold = 10
  }
}

resource "aws_alb_listener" "http-listener" {
  depends_on = [aws_alb_target_group.default-tg]
  load_balancer_arn = aws_alb.alb-resource.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.default-tg.arn
    type             = "forward"
  }
}

output "defaulttg_arn" {
  value = aws_alb_target_group.default-tg.arn
}

output "listener_arn" {
  value = aws_alb_listener.http-listener.arn
}

output "alb_arn" {
  value = aws_alb.alb-resource.arn
}