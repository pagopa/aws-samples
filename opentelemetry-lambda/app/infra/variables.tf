variable "aws_region" {
  description = "The AWS region to deploy the resources in."
  type        = string
  default     = "eu-central-1"
}

variable "ecr_repository_name" {
  description = "The name of the ECR repository to store the Lambda container image."
  type        = string
  default     = "s3-bucket-lister-lambda"
}

variable "lambda_function_name" {
  description = "The name of the Lambda function."
  type        = string
  default     = "S3BucketLister"
}

variable "image_tag" {
  description = "The tag for the Docker image in ECR (e.g., 'latest')."
  type        = string
  default     = "v10"
}