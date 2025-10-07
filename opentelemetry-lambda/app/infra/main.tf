terraform {
  required_version = "~> 1.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


provider "aws" {
  region = var.aws_region
}

# --- ECR Repository ---
# Creates a repository in ECR to store the Docker image for the Lambda.
resource "aws_ecr_repository" "s3_lister_repo" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# --- IAM Role and Policy for Lambda ---
# Creates an IAM role that the Lambda function will assume.
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.lambda_function_name}-role"

  # The trust policy that grants AWS Lambda the permission to assume this role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Creates an IAM policy with the necessary permissions for the Lambda function.
resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.lambda_function_name}-policy"
  description = "IAM policy for S3 lister Lambda function"

  # The policy document grants permissions to write to CloudWatch Logs and list S3 buckets.
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "s3:ListAllMyBuckets"
        ],
        Effect   = "Allow",
        Resource = "*" # This action does not support resource-level permissions
      },
      {
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# Attaches the policy to the Lambda execution role.
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# --- Lambda Function ---
# Creates the Lambda function from the Docker image in ECR.
resource "aws_lambda_function" "s3_bucket_lister" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_exec_role.arn
  package_type  = "Image"
  timeout       = 30 # seconds

  # Enable Active Tracing with AWS X-Ray
  tracing_config {
    mode = "Active"
  }

  # The image URI is constructed from the ECR repository URL and the image tag.
  image_uri = "${aws_ecr_repository.s3_lister_repo.repository_url}:${var.image_tag}"

  # Ensures the IAM role and policy are created before the Lambda function.
  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attach
  ]

  environment {
    variables = {
      AWS_LAMBDA_EXEC_WRAPPER = "/opt/otel-instrument"
      #OTEL_TRACES_EXPORTER    = "otlp"
      # OTEL_METRICS_EXPORTER   = "none"
      #OTEL_PROPAGATORS        = "tracecontext,baggage"
      OTEL_RESOURCE_ATTRIBUTES = "service.name=${var.lambda_function_name},service.version=1.0.0"
      #OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4318"
    }
  }
}

# --- CloudWatch Log Group ---
# Defines a log group for the Lambda function's output.
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.s3_bucket_lister.function_name}"
  retention_in_days = 14
}
