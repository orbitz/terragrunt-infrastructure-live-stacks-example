# ---------------------------------------------------------------------------------------------------------------------
# IAM ROLE THAT LETS THE LAMBDA FUNCTION USE THE DYNAMODB TABLE
# The `catalog/units/lambda-iam-role-to-dynamodb` Terragrunt unit uses this module. The unit sets
# `assume_role_policy`, and the stack file sets `policy`.
#
# DEMO STAND-IN: this module does not create an IAM role. A `terraform_data` resource keeps the role name and the
# policy documents in the state, and the outputs have the same shape as the outputs of a real role. Thus the
# repository plans and applies without AWS credentials and without network access to a provider registry.
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.7"
}

resource "terraform_data" "role" {
  input = {
    name = var.name
    arn  = "arn:aws:iam::${var.aws_account_id}:role/${var.name}"

    assume_role_policy = var.assume_role_policy
    policy             = var.policy
  }
}
