provider "aws" {
    region = "us-east-1"
    profile = "${var.profile}"
}

variable "profile" {}


locals {
  env="${terraform.workspace}"
}

module "alb-module" {
  source = "./alb-listener-defaulttg"
  stack_name = var.stack_prefix
  env_suffix = local.env
  albsgs = var.albsgs
  albsubnetids = var.albsubnetids
  vpc_id = var.vpcid
}

module "ecs-asg-module" {
  source = "./ecs-asg-tg"
  alb_arn = module.alb-module.alb_arn
  listener_arn = module.alb-module.listener_arn
  stack_name = var.stack_prefix
  substack_prefix = var.substack_prefix
  env_suffix = local.env
  vpc_id = var.vpcid
  healthcheck_path = "/"
  listenerrule_paths = ["*"]
  amiid = var.amiid
  iamrole = var.instancerole
  instance_type = "i3.large"
  key_name = var.keyname
  securitygroupids = var.instancesgs
  desired = 0
  min = 0
  max = 0
  health_grace_period = 600
  asgsubnetids = var.asgsubnetids
  ecs_iam_role = var.ecs_iam_role
  task_role_arn = var.task_role_arn
  container_name = var.container_name
  ecs_desired = 0
  ecs_image = var.ecs_image
}