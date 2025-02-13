# AWS API Gateway with Lambda and Cognito Authentication

This project sets up a serverless REST API using AWS services. The infrastructure is managed using Terraform and includes the following components:

- **API Gateway (HTTP API)**: Serves as the entry point for HTTP requests.
- **AWS Lambda Function**: Processes incoming requests and returns a simple "Hello, World!" response.
- **AWS Cognito User Pool**: Provides authentication for the API using JSON Web Tokens (JWT).
- **Terraform**: Infrastructure as Code (IaC) tool to provision and manage AWS resources.


## Output example

```
api_endpoint = "https://<apigw-api-id>.execute-api.eu-south-1.amazonaws.com/prod"
cognito_signin_url = "https://sandbox.auth.eu-south-1.amazoncognito.com/login?response_type=token&client_id=<cognito-client-id>&redirect_uri=https://<apigw-api-id>.execute-api.eu-south-1.amazonaws.com/prod"
cognito_user_pool_client_id = "<cognito-client-id>"
cognito_user_pool_domain = "https://sandbox.auth.eu-south-1.amazoncognito.com"
test_user = {
  "email" = "testuser@sandbox.pagopa.it"
  "username" = "testuser"
}
```

## Cognito Login example with curl

```:bash
curl --location --request POST 'https://cognito-idp.eu-south-1.amazonaws.com' \
--header 'X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth' \
--header 'Content-Type: application/x-amz-json-1.1' \
--data-raw '{
   "AuthParameters" : {
      "USERNAME" : "testuser",
      "PASSWORD" : "<testuser-password>"
   },
   "AuthFlow" : "USER_PASSWORD_AUTH",
   "ClientId" : "<cognito-client-id>"
}'
```

## Api call with Bearer token

```:bash
curl --request GET \
  --url https://<apigw-api-id>.execute-api.eu-south-1.amazonaws.com/prod/api \
  --header 'Authorization: Bearer <access-token>'
```

Note: the access token comes form the login step.
