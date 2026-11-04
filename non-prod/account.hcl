# Set account-wide variables. These are automatically pulled in by the root root.hcl configuration.
# DEMO: the account ID has a default, because the demo modules use it only to make the ARNs.
locals {
  account_name   = "non-prod"
  aws_account_id = get_env("EX_NON_PROD_ACCOUNT_ID", "123456789012")
}
