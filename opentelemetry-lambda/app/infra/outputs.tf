output "ecr_repository_url" {
  description = "The URL of the ECR repository."
  value       = aws_ecr_repository.s3_lister_repo.repository_url
}

output "lambda_function_name" {
  description = "The name of the created Lambda function."
  value       = aws_lambda_function.s3_bucket_lister.function_name
}

output "lambda_iam_role_arn" {
  description = "The ARN of the IAM role for the Lambda function."
  value       = aws_iam_role.lambda_exec_role.arn
}
