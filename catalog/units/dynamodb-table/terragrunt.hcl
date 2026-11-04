include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  repo_root = dirname(find_in_parent_folders("root.hcl"))
}

terraform {
  source = "${local.repo_root}/modules/stateful-lambda-service/db"
}

inputs = {
  # Required inputs
  name          = values.name
  hash_key      = values.hash_key
  hash_key_type = values.hash_key_type

  # Optional inputs
  billing_mode = try(values.billing_mode, "PAY_PER_REQUEST")
}
