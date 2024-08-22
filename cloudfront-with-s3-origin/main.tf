# Configure the AWS provider
provider "aws" {
  region = "us-east-1"  # Change this to your desired region
}

# Create a random pet name for the S3 bucket
resource "random_pet" "bucket_name" {
  length    = 3
  separator = "-"
  prefix    = "website"
}

# S3 Bucket
resource "aws_s3_bucket" "content_bucket" {
  bucket = random_pet.bucket_name.id
}

# Block public access to the bucket
resource "aws_s3_bucket_public_access_block" "content_bucket_public_access_block" {
  bucket = aws_s3_bucket.content_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning on the bucket
resource "aws_s3_bucket_versioning" "content_bucket_versioning" {
  bucket = aws_s3_bucket.content_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for the bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "content_bucket_encryption" {
  bucket = aws_s3_bucket.content_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "content_bucket_oac" {
  name                              = "content-bucket-oac"
  description                       = "OAC for S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.content_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.content_bucket_oac.id
    origin_id                = "S3Origin"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    function_association {
      event_type   = "viewer-response"
      function_arn = aws_cloudfront_function.security_headers.arn
    }
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true  # Use this for *.cloudfront.net domain
    # For custom domain, use ACM certificate and modify as needed
    # acm_certificate_arn = "arn:aws:acm:us-east-1:your-account-id:certificate/your-certificate-id"
    # ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Enable WAF if needed
  # web_acl_id = aws_waf_web_acl.example_waf.id
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "content_bucket_policy" {
  bucket = aws_s3_bucket.content_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.content_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}

# Optional: CloudFront Function for security headers
resource "aws_cloudfront_function" "security_headers" {
  name    = "security-headers"
  runtime = "cloudfront-js-1.0"
  comment = "Add security headers"
  publish = true
  code    = <<-EOT
    function handler(event) {
      var response = event.response;
      var headers = response.headers;
      
      headers['strict-transport-security'] = { value: 'max-age=63072000; includeSubdomains; preload'};
      headers['x-content-type-options'] = { value: 'nosniff'};
      headers['x-frame-options'] = { value: 'DENY'};
      headers['x-xss-protection'] = { value: '1; mode=block'};
      
      return response;
    }
  EOT
}

# Outputs
output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "s3_bucket_name" {
  value = aws_s3_bucket.content_bucket.id
}