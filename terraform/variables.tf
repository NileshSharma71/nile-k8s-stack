variable "aws_region" {
  type        = string
  default     = "ap-south-1"
  description = "The AWS region where storage infrastructure will live"
}

variable "bucket_name" {
  type        = string
  # S3 bucket names must be globally unique across all of AWS. 
  # Change "nilesh" to something else if this name is already taken!
  default     = "nile-k8s-loki-logs-nilesh"
  description = "The name of the S3 bucket for Loki cold storage"
}