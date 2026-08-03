terraform {
  required_version = ">= 1.0"
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

# 1. Secure S3 Bucket for Loki Log Storage
resource "aws_s3_bucket" "loki_storage" {
  bucket        = var.bucket_name
  force_destroy = true # Allows you to easily delete the bucket later during teardown
}

# 2. Block all public access to the log bucket (Security Best Practice)
resource "aws_s3_bucket_public_access_block" "loki_storage_privacy" {
  bucket = aws_s3_bucket.loki_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. IAM Policy allowing Loki to Read/Write to this specific bucket
resource "aws_iam_policy" "loki_s3_policy" {
  name        = "NileK8sLokiS3StoragePolicy"
  description = "Allows local Loki instance to manage log blocks in S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.loki_storage.arn,
          "${aws_s3_bucket.loki_storage.arn}/*"
        ]
      }
    ]
  })
}