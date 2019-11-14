variable "alb_arn" {}
variable "env_suffix" {}
variable "stack_name" {}
variable "substack_prefix" {}
variable "healthcheck_path" {}
variable "vpc_id" {}
variable "listenerrule_paths" {
  type = list(string)
}
variable "listener_arn" {}
variable "amiid" {}
variable "iamrole" {}
variable "instance_type" {}
variable "key_name" {}
variable "securitygroupids" {
    type = list(string)
}
variable "desired" {}
variable "min" {}
variable "max" {}
variable "health_grace_period" {}
variable "asgsubnetids" {
  type = list(string)
}
variable "ecs_iam_role" {}
variable "task_role_arn" {}
variable "container_name" {}
variable "ecs_desired" {}
variable "ecs_image" {}


module "launch-template" {
  source = "../launchtemplate"
  stack_name = var.stack_name
  env_suffix = var.env_suffix
  substack_prefix = var.substack_prefix
  amiid = var.amiid
  iamrole = var.iamrole
  instance_type = var.instance_type
  key_name = var.key_name
  securitygroupids = var.securitygroupids
}


resource "aws_ecs_cluster" "ecs-cluster" {
  name = "ecs-cluster-${var.stack_name}-${var.substack_prefix}-${var.env_suffix}"
}

resource "aws_alb_target_group" "target_group_res" {
  name     = "${var.env_suffix}-${var.stack_name}-${var.substack_prefix}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  deregistration_delay = 60
  slow_start = 180
  health_check {
    protocol = "HTTP"
    interval = 30
    timeout =29
    path = var.healthcheck_path
    healthy_threshold = 2
    unhealthy_threshold = 10
  }
}

data "template_file" "ecs-container" {
  template = "${file("./ecs-asg-tg/ecs-container.tpl.json")}"
  vars = {
    image = "${var.ecs_image}"
    container_name = "${var.container_name}"
  }
}


resource "aws_ecs_task_definition" "ecs-taskdef" {
  family                = "taskdef-${var.stack_name}-${var.substack_prefix}-${var.env_suffix}"
  container_definitions = "${data.template_file.ecs-container.rendered}"
  network_mode = "bridge"
  requires_compatibilities = ["EC2"]
  task_role_arn = "${var.task_role_arn}"
}

resource "aws_ecs_service" "ecs-service" {
  depends_on      = [aws_alb_listener_rule.listener-rule]
  name            = "ecs-service-${var.env_suffix}"
  cluster         = "${aws_ecs_cluster.ecs-cluster.arn}"
  task_definition = "${aws_ecs_task_definition.ecs-taskdef.arn}"
  desired_count   = "${var.ecs_desired}"
  iam_role        = "${var.ecs_iam_role}"
  health_check_grace_period_seconds = 100

  load_balancer {
    target_group_arn  = "${aws_alb_target_group.target_group_res.arn}"
    container_name = "${var.container_name}"
    container_port = 80
  }
}

resource "aws_alb_listener_rule" "listener-rule" {
  for_each  = toset (var.listenerrule_paths)
  listener_arn = var.listener_arn
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.target_group_res.arn
  }

  condition {
    field  = "path-pattern"
    values = ["*${each.key}*"]
  }
}

resource "aws_autoscaling_group" "asg-resource" {
    name = "${var.env_suffix}-ASG-${var.stack_name}-${var.substack_prefix}"
    target_group_arns = [aws_alb_target_group.target_group_res.arn]
    launch_template {
      id = module.launch-template.launch_template.id
      version = "$Latest"
    }
    min_size = var.min
    max_size = var.max
    default_cooldown = var.health_grace_period + 100 # slightly more than HC grace period so unhealthy instances scale down first
    health_check_grace_period = var.health_grace_period
    health_check_type = "ELB"
    desired_capacity = var.desired
    termination_policies = ["OldestInstance"]
    vpc_zone_identifier = var.asgsubnetids # Public subnets
    enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances" ]

    tag {
        key   = "Environment"
        value = var.env_suffix
        propagate_at_launch = true
    }
    
    tag {
      key = "EcsClusterName"
      value = "${aws_ecs_cluster.ecs-cluster.name}"
      propagate_at_launch = true
    }

    tag {
        key   = "Name"
        value = "${var.env_suffix} - ${var.stack_name}  ${var.substack_prefix}"
        propagate_at_launch = true
    }

    lifecycle {
      create_before_destroy = true
    }
}