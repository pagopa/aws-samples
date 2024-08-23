variable "aws_region" {
  type    = string
  default = "eu-south-1"
}

variable "cognito_user_pool_domain" {
  type    = string
  default = "sandbox"
}

variable "cognito_callback_url" {
  type    = string
  default = "https://037hui4csc.execute-api.eu-south-1.amazonaws.com/prod"
}