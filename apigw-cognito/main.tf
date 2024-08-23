terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.64.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}


# Cognito user pool 
resource "aws_cognito_user_pool" "main" {
  name = "my-user-pool"

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = var.cognito_user_pool_domain
  user_pool_id = aws_cognito_user_pool.main.id
}

/*
resource "aws_cognito_resource_server" "resource" {
  identifier = "https://${var.cognito_user_pool_domain}.pagopa.it"
  name       = "My API"

  scope {
    scope_name        = "read"
    scope_description = "Read access"
  }

  scope {
    scope_name        = "write"
    scope_description = "Write access"
  }

  user_pool_id = aws_cognito_user_pool.main.id
}
*/

resource "aws_cognito_user_pool_client" "client" {
  name         = "my-app-client"
  user_pool_id = aws_cognito_user_pool.main.id

  allowed_oauth_flows_user_pool_client = true

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]


  allowed_oauth_flows  = ["code", "implicit"]
  allowed_oauth_scopes = ["email", "openid"]

  callback_urls = [var.cognito_callback_url]
  logout_urls   = ["https://sandbx.pagopa.it/logout"] # Update with your app's logout URL

  supported_identity_providers = ["COGNITO"]

  #generate_secret = true

}

## Not recommended for 

resource "random_password" "test_user_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_cognito_user" "test_user" {
  user_pool_id = aws_cognito_user_pool.main.id
  username     = "testuser@sandbox.pagopa.it"

  attributes = {
    email          = "testuser@sandbox.pagopa.it"
    email_verified = true
  }

  password = random_password.test_user_password.result
}

# Create a Lambda Function
resource "aws_lambda_function" "hello_world" {
  function_name = "hello_world_function"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"

  # Basic "Hello World" Lambda function code
  filename = "./lambda/lambda.zip"

  source_code_hash = filebase64sha256("./lambda/lambda.zip")

  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# Attach the AWSLambdaBasicExecutionRole policy to the IAM role
resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create an API Gateway V2 (HTTP API)
resource "aws_apigatewayv2_api" "api" {
  name          = "auth-api"
  protocol_type = "HTTP"
}

# Create a Lambda Integration
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  connection_type    = "INTERNET"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.hello_world.invoke_arn

  payload_format_version = "2.0"
}

# Create a Route
resource "aws_apigatewayv2_route" "route" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "GET /{proxy+}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_authorizer.id
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Create a Stage
resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "prod"
  auto_deploy = true
}

# Create a Cognito Authorizer
resource "aws_apigatewayv2_authorizer" "cognito_authorizer" {
  api_id           = aws_apigatewayv2_api.api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  name = "cognito-authorizer"
  jwt_configuration {
    audience = [aws_cognito_user_pool_client.client.id]
    issuer   = "https://${aws_cognito_user_pool.main.endpoint}"
  }
}
