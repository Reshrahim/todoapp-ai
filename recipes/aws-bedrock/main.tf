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

locals {
  model_arn = "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.model_id}"
}

resource "aws_iam_role" "bedrock_runtime_role" {
  name = "BedrockRuntimeAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "bedrock_model_policy" {
  name        = "BedrockModelAccessPolicy"
  description = "Grants access to the specified Bedrock model"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = local.model_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_model_policy" {
  role       = aws_iam_role.bedrock_runtime_role.name
  policy_arn = aws_iam_policy.bedrock_model_policy.arn
}

output "bedrock_model_arn" {
  description = "The fully constructed ARN for the specified Bedrock model"
  value       = local.model_arn
}

output "iam_role_arn" {
  description = "IAM Role ARN with permissions to invoke the Bedrock model"
  value       = aws_iam_role.bedrock_runtime_role.arn
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