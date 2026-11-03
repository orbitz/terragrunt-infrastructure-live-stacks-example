# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT: PROD
# One root module holds the complete environment. Stategraph keeps the state (engine `stategraph` in
# `.stategraph/config.yml`), so there is no backend block. The `prod` stack in `.stategraph/config.yml` sets the
# account and region variables.
#
# The three components reference each other directly. Inside one root module, OpenTofu orders them and passes the
# outputs; no `depends_on` rule or remote state is necessary.
#
# DEMO: the component modules use `terraform_data` resources in place of AWS resources, so this root module needs no
# provider and no AWS credentials.
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.7"
}

locals {
  name = "${var.app_prefix}stateful-lambda-service"
}

module "db" {
  source = "../../modules/stateful-lambda-service/db"

  name          = "${local.name}-db"
  hash_key      = "Id"
  hash_key_type = "S"

  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region
}

module "role" {
  source = "../../modules/stateful-lambda-service/role"

  name               = "${local.name}-role"
  dynamodb_table_arn = module.db.arn

  aws_account_id = var.aws_account_id
}

# A `run` step in `.stategraph/config.yml` writes handler.zip in this directory before each plan and apply.
module "lambda_service" {
  source = "../../modules/stateful-lambda-service/service"

  name     = local.name
  runtime  = "nodejs22.x"
  handler  = "index.handler"
  zip_file = "${path.module}/handler.zip"
  memory   = 128
  timeout  = 3

  iam_role_arn        = module.role.arn
  dynamodb_table_name = module.db.name

  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region
}
