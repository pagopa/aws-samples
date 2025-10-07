# OpenTelemetry AWS Lambda Sample

This project demonstrates how to instrument AWS Lambda functions with OpenTelemetry for distributed tracing and observability. The sample includes a Python Lambda function that lists S3 buckets and sends traces to AWS X-Ray using the OpenTelemetry SDK.

## Architecture

The project consists of:

- **Lambda Function**: A Python function that lists S3 buckets in your AWS account
- **OpenTelemetry Instrumentation**: Automatic tracing of AWS SDK calls (boto3/botocore)
- **AWS X-Ray Integration**: Traces are exported to AWS X-Ray for visualization
- **Container-based Deployment**: Lambda function packaged as a Docker container
- **Infrastructure as Code**: Terraform configuration for deploying all AWS resources

## Features

- ✅ Automatic instrumentation of AWS SDK calls
- ✅ Custom OpenTelemetry configuration
- ✅ AWS X-Ray tracing integration
- ✅ Container-based Lambda deployment
- ✅ Infrastructure provisioning with Terraform
- ✅ CloudWatch Logs integration

## Project Structure

```
opentelemetry-lambda/
├── app/
│   ├── lambda/
│   │   ├── app.py              # Lambda function code
│   │   ├── Dockerfile          # Container image definition
│   │   ├── requirements.txt    # Python dependencies
│   │   ├── adot-config.yaml   # OpenTelemetry Collector config
│   │   └── Makefile           # Local build and test commands
│   └── infra/
│       ├── main.tf            # Main Terraform configuration
│       ├── variables.tf       # Input variables
│       └── outputs.tf         # Output values
└── README.md                  # This file
```

## Prerequisites

- **AWS CLI** configured with appropriate credentials
- **Terraform** (~> 1.13.0)
- **Podman** or **Docker** for building container images
- **AWS Account** with permissions for:
  - Lambda
  - ECR
  - IAM
  - CloudWatch
  - X-Ray
  - S3 (ListAllMyBuckets)

## Quick Start

### 1. Build and Test Locally

Navigate to the Lambda directory and build the container:

```bash
cd app/lambda
make build
```

Test the function locally:

```bash
# Run the container locally
make run

# In another terminal, invoke the function
make call
```

### 2. Deploy to AWS

#### Step 1: Build and Push Container Image

```bash
# Build the container
cd app/lambda
make build

# Tag and push to ECR (replace with your account ID and region)
aws ecr get-login-password --region eu-central-1 | podman login --username AWS --password-stdin <account-id>.dkr.ecr.eu-central-1.amazonaws.com

# Create ECR repository (if it doesn't exist)
aws ecr create-repository --repository-name s3-bucket-lister-lambda --region eu-central-1

# Tag and push the image
podman tag s3-bucket-lister-lambda:latest <account-id>.dkr.ecr.eu-central-1.amazonaws.com/s3-bucket-lister-lambda:v10
podman push <account-id>.dkr.ecr.eu-central-1.amazonaws.com/s3-bucket-lister-lambda:v10
```

#### Step 2: Deploy Infrastructure

```bash
cd app/infra

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 3. Test the Deployed Function

```bash
# Invoke the Lambda function
aws lambda invoke --function-name S3BucketLister --payload '{}' response.json

# Check the response
cat response.json

# View logs in CloudWatch
aws logs tail /aws/lambda/S3BucketLister --follow
```

### 4. View Traces in X-Ray

1. Open the [AWS X-Ray Console](https://console.aws.amazon.com/xray/)
2. Navigate to "Traces"
3. You should see traces from your Lambda function showing:
   - Lambda execution spans
   - S3 API call spans
   - Timing and performance metrics

## Configuration

### OpenTelemetry Configuration

The OpenTelemetry configuration is defined in `adot-config.yaml`:

```yaml
exporters:
  awsxray:
    region: eu-central-1
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
service:
  pipelines:
    traces:
      exporters:
        - awsxray
      receivers:
        - otlp
```

### Lambda Environment Variables

The function is configured with these OpenTelemetry environment variables:

- `AWS_LAMBDA_EXEC_WRAPPER`: `/opt/otel-instrument` - Enables auto-instrumentation
- `OTEL_RESOURCE_ATTRIBUTES`: Service name and version for trace identification

### Terraform Variables

You can customize the deployment by modifying variables in `variables.tf`:

- `aws_region`: AWS region for deployment (default: eu-central-1)
- `ecr_repository_name`: ECR repository name (default: s3-bucket-lister-lambda)
- `lambda_function_name`: Lambda function name (default: S3BucketLister)
- `image_tag`: Docker image tag (default: v10)

## Observability Features

### Automatic Instrumentation

The project uses the AWS OpenTelemetry Python instrumentation to automatically trace:

- **Lambda runtime**: Function invocation, cold starts, duration
- **AWS SDK calls**: S3 ListBuckets API calls with request/response details
- **HTTP requests**: Any outbound HTTP calls made by the function

### Trace Information

Each trace includes:

- **Service information**: Function name, version, runtime
- **Timing data**: Execution duration, cold start indicators
- **AWS metadata**: Request IDs, account information
- **Error tracking**: Exception details and stack traces (if errors occur)

## Troubleshooting

### Common Issues

1. **Container build fails**:
   - Ensure Podman/Docker is running
   - Check internet connectivity for downloading dependencies

2. **ECR push fails**:
   - Verify AWS CLI is configured with correct permissions
   - Check that ECR repository exists and you have push permissions

3. **Lambda deployment fails**:
   - Verify Terraform has appropriate AWS permissions
   - Check that the container image exists in ECR with the specified tag

4. **No traces in X-Ray**:
   - Ensure X-Ray service is enabled in your AWS account
   - Check Lambda function has X-Ray tracing enabled
   - Verify IAM permissions include X-Ray write permissions

### Logs and Debugging

- **Lambda logs**: Available in CloudWatch Logs at `/aws/lambda/S3BucketLister`
- **Build logs**: Check Podman/Docker output during container build
- **Terraform logs**: Use `TF_LOG=DEBUG terraform apply` for detailed logs

## Cleanup

To remove all created resources:

```bash
cd app/infra
terraform destroy
```

To remove the ECR repository and images:

```bash
aws ecr delete-repository --repository-name s3-bucket-lister-lambda --force --region eu-central-1
```

## Further Reading

- [AWS OpenTelemetry Documentation](https://aws-otel.github.io/docs/)
- [OpenTelemetry Python Instrumentation](https://opentelemetry-python-contrib.readthedocs.io/)
- [AWS X-Ray Developer Guide](https://docs.aws.amazon.com/xray/latest/devguide/)
- [AWS Lambda Container Images](https://docs.aws.amazon.com/lambda/latest/dg/images-create.html)

## Contributing

This project is part of the PagoPA AWS samples collection. Contributions and improvements are welcome!

## License

This project is licensed under the MIT License - see the LICENSE file for details.