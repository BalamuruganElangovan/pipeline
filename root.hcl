locals {
  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  function_vars = read_terragrunt_config(find_in_parent_folders("function.hcl"))
  account_vars  = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  s3_backend_region  = local.region_vars.locals.aws_region
  aws_region         = local.region_vars.locals.aws_region
  account_name       = local.account_vars.locals.account_name
  function_name      = local.function_vars.locals.function_name
  aws_account_id     = local.account_vars.locals.aws_account_id
  iam_role           = "arn:aws:iam::${local.aws_account_id}:role/terraform_execution_role"

}


# Generate an AWS provider block
generate "provider" {
  path      = "provider.gen.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
  default_tags {
    tags = {
      Account  = "${local.account_name}"
      Region   = "${local.aws_region}"
      Function = "${local.function_name}"
    }
  }
}
EOF
}

generate "terraform_overrides" {
  path      = "terraform.gen.tf"
  if_exists = "skip"
  contents  = <<EOF
terraform {
  required_version = "1.3.7"
    required_providers {
        aws = {
        source = "hashicorp/aws"
        version = "4.52.0"
        }
}
}
EOF
}



# terraform {

#   before_hook "tflint_run" {
#     commands = ["plan"]
#     execute  = ["tflint", "--config=${find_in_parent_folders(".tflint.hcl")}", "--no-color"]
#   }

#   before_hook "tfsec" {
#     commands = ["plan"]
#     execute  = ["tfsec", "--config-file", "${find_in_parent_folders(".tfsec.yml")}", "--no-color"]
#   }

# }

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "terraform-state-${local.aws_account_id}-${local.aws_region}"
    key            = "aws/${path_relative_to_include()}/terraform.tfstate"
    region         = "${local.s3_backend_region}"
    dynamodb_table = "terraform-state-${local.aws_account_id}-${local.aws_region}"
    # role_arn       = "${local.iam_role}"
  }
  generate = {
    path      = "backend.gen.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = {
  aws_account_id = local.aws_account_id
  aws_region     = local.aws_region
  account_name   = local.account_name
  function_name  = local.function_name

  tags = {
    Account  = local.account_name
    Region   = local.aws_region
    Function = local.function_name
  }
}