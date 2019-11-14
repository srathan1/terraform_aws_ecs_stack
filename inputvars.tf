variable "albsgs" {
    type = list(string)
}
variable "albsubnetids" {
    type = list(string)
}
variable "instancesgs" {
    type = list(string)
}
variable "asgsubnetids" {
    type = list(string)
}
variable "vpcid" {}
variable "stack_prefix" {}
variable "substack_prefix" {}
variable "amiid" {}
variable "instancerole" {}
variable "keyname" {}
variable "ecs_iam_role" {}
variable "task_role_arn" {}
variable "container_name" {}
variable "ecs_image" {}