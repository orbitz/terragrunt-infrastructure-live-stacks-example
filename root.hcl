# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform/OpenTofu that provides extra tools for working with multiple modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract the variables we need for easy access
  account_id = local.account_vars.locals.aws_account_id
  aws_region = local.region_vars.locals.aws_region
}

# DEMO: the modules use `terraform_data` resources in place of AWS resources, so no AWS provider is generated. The
# modules use the account ID and the region only to make the ARNs.
inputs = {
  aws_account_id = local.account_id
  aws_region     = local.aws_region
}

# DEMO: keep the state of each unit in a local file, in place of an S3 bucket. The file is
# `<stack directory>/<unit path>/terraform.tfstate`. The `.terragrunt-stack/` part is removed from the path, so the
# state is not in the generated directory, and you can delete that directory without losing the state.
remote_state {
  backend = "local"
  config = {
    path = "${get_parent_terragrunt_dir()}/${replace(path_relative_to_include(), ".terragrunt-stack/", "")}/terraform.tfstate"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Configure what repositories to search when you run 'terragrunt catalog'
catalog {
  urls = [
    "https://github.com/gruntwork-io/terragrunt-infrastructure-catalog-example",
    "https://github.com/gruntwork-io/terraform-aws-utilities",
    "https://github.com/gruntwork-io/terraform-kubernetes-namespace"
  ]
}

