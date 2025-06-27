terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

variable "context" {
  description = "This variable contains Radius recipe context."
  type        = any
}

variable "bucket" {
  description = "The name of your S3 bucket. Must follow AWS S3 naming conventions."
  type        = string
  default     = "mys3bucket"
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket
}

output "result" {
  value = {
    values = {
      bucket_name = aws_s3_bucket.bucket.bucket
    }
    resources = [
      "/planes/aws/aws/accounts/817312594854/regions/us-west-2/providers/AWS.s3/bucket/${aws_s3_bucket.bucket.id}"
    ]
  }
}
