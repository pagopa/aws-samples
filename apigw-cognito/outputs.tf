output "api_invoke_url" {
  value = "${aws_api_gateway_deployment.main.invoke_url}${aws_api_gateway_stage.main.stage_name}${aws_api_gateway_resource.root.path}"
}

output "cognito_user_pool_client_id" {
  value       = aws_cognito_user_pool_client.client.id
  description = "The ID of the Cognito User Pool Client"
}

output "cognito_user_pool_domain" {
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com"
  description = "The domain name of the Cognito User Pool"
}

output "cognito_signin_url" {
  value = "https://${var.cognito_user_pool_domain}.auth.${var.aws_region}.amazoncognito.com/login?response_type=token&client_id=${aws_cognito_user_pool_client.client.id}&redirect_uri=${var.cognito_callback_url}"
}


output "test_user_password" {
  value     = random_password.test_user_password.result
  sensitive = true
}