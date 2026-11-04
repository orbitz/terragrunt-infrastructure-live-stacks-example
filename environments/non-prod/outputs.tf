# The same shape as `terragrunt stack output`: one object per component, with that component's outputs.
output "db" {
  description = "The outputs of the DynamoDB table: name, arn."
  value       = module.db
}

output "role" {
  description = "The outputs of the IAM role: name, arn."
  value       = module.role
}

output "lambda_service" {
  description = "The outputs of the Lambda function: function_url, function_arn, function_name."
  value       = module.lambda_service
}
