variable "aws_region" {
  type    = string
  default = "eu-south-1"
}

variable "cognito_user_pool_domain" {
  type    = string
  default = "sandbox"
}


variable "cognito_test_user" {
  type = object({
    username = string
    email    = string
  })
  default = {
    username = "testuser"
    email    = "testuser@sandbox.pagopa.it"
  }

}