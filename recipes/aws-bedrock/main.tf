terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS Region for deploying resources"
  type        = string
  default     = "us-west-2"
}

variable "model_id" {
  description = "The Bedrock foundation model ID (e.g., 'anthropic.claude-3-sonnet-20240229-v1:0')"
  type        = string
  default = "anthropic.claude-3-sonnet-20240229-v1:0"
}
variable "iam_user_name" {
  description = "IAM user name to attach Bedrock model permissions to"
  type        = string
  default = "reshmarahim.abdul"
}


locals {
  model_arn = "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.model_id}"
}

resource "aws_iam_user_policy" "bedrock_access" {
  name = "AllowBedrockModelInvoke"
  user = var.iam_user_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ],
        Resource = local.model_arn
      }
    ]
  })
}


output "result" {
  value = {
    values = {
      model = var.model_id
      region   = var.aws_region
    }
  }
  sensitive = true
}