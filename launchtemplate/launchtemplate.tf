variable "env_suffix" {}
variable "stack_name" {}
variable "substack_prefix" {}
variable "amiid" {}
variable "iamrole" {}
variable "instance_type" {}
variable "key_name" {}
variable "securitygroupids" {
    type = list(string)
}

resource "aws_launch_template" "launchtemplate" {
    name = "${var.stack_name}-${var.substack_prefix}-LT-${var.env_suffix}"
    image_id = var.amiid
    iam_instance_profile {
        name = var.iamrole
    }
    instance_type = var.instance_type
    key_name = var.key_name
    monitoring {
        enabled = true
    }
    vpc_security_group_ids = var.securitygroupids
    user_data = base64encode(file("./launchtemplate/userdata-ecs.xml"))
}

output "launch_template" {
  value = aws_launch_template.launchtemplate
}
