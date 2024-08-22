## CloudFront with S3 Origin

This sample demonstrates how to set up a CloudFront distribution with an S3 bucket as its origin, following security best practices.

### Features

- Private S3 bucket with versioning and server-side encryption
- CloudFront distribution with Origin Access Control (OAC)
- HTTPS-only access with TLS 1.2
- CloudFront function for security headers
- S3 bucket policy allowing access only from CloudFront

### Usage

1. Initialize Terraform: ` terraform init`
2. Plan the Terraform execution: `terraform plan`
3. Apply the Terraform configuration: `terraform apply`
4. When finished, you can destroy the resources: `terraform destroy`

### Notes

- Ensure you have appropriate AWS credentials configured.
- The sample uses the default CloudFront certificate. For custom domains, modify the ACM certificate section in the configuration.
- Review and adjust security settings, cache behaviors, and other configurations to match your specific requirements.
- Always test thoroughly in a non-production environment before applying to production.