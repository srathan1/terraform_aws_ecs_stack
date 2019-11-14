**Terraform template for ecs stack**

*This terraform template works with v0.12+ and requires you to fill the variables in inputvars.tfvars file*

**Inorder to execute this terraform, run the following commands**
- terraform init
- terraform workspace new qa (qa can be replace with your workspace)
- terraform plan -var-file="inputvars.tfvars" 
- terraform apply -var-file="inputvars.tfvars"

**For more terraform info goto terraform.io**