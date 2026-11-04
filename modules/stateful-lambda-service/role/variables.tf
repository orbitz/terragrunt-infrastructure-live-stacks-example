variable "name" {
  description = "The name of the IAM role and of its inline policy."
  type        = string
}

variable "assume_role_policy" {
  description = "The assume role policy of the IAM role."
  type        = string
}

variable "policy" {
  description = "The inline policy of the IAM role."
  type        = string
}

variable "aws_account_id" {
  description = "The ID of the AWS account. The module uses it only to make the ARN."
  type        = string
}
