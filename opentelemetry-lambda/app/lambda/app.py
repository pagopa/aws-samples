import boto3
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    This function lists all S3 buckets in the AWS account
    and logs the list to CloudWatch.
    """
    try:
        # Create an S3 client
        s3 = boto3.client('s3')

        # List all buckets
        response = s3.list_buckets()

        # Extract bucket names
        buckets = [bucket['Name'] for bucket in response['Buckets']]

        # Log the bucket names to CloudWatch
        logger.info(f"Successfully found {len(buckets)} S3 buckets.")
        logger.info("Bucket List:")
        for bucket_name in buckets:
            logger.info(f"- {bucket_name}")

        return {
            'statusCode': 200,
            'body': f'Successfully listed {len(buckets)} buckets. Check CloudWatch logs for details.'
        }

    except Exception as e:
        # Log any errors
        logger.error(f"Error listing S3 buckets: {str(e)}")
        return {
            'statusCode': 500,
            'body': f'Error listing S3 buckets: {str(e)}'
        }
