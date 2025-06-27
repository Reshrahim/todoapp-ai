terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}
variable "context" {
  description = "This variable contains Radius recipe context."
  type = any
}

provider "aws" {
  region = "us-west-2"
  assume_role_with_web_identity {
    role_arn = "arn:aws:iam::817312594854:role/re-irsa"
    web_identity_token_file = "/var/run/secrets/eks.amazonaws.com/serviceaccount/token"
  }
}

variable "model_id" {
  description = "Bedrock foundation model ID"
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

# Ensure uniqueness
resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  model_arn   = "arn:aws:bedrock:us-west-2::foundation-model/${var.model_id}"
  user_name   = "bedrock-user-${random_id.suffix.hex}"
  policy_name = "BedrockUserPolicy-${random_id.suffix.hex}"
}

# IAM user
resource "aws_iam_user" "bedrock_user" {
  name = local.user_name
}

# Policy to allow Bedrock model access
resource "aws_iam_policy" "bedrock_policy" {
  name        = local.policy_name
  description = "Policy to allow Bedrock model invocation"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      Resource = local.model_arn
    }]
  })
}

# Attach policy to user
resource "aws_iam_user_policy_attachment" "attach_policy" {
  user       = aws_iam_user.bedrock_user.name
  policy_arn = aws_iam_policy.bedrock_policy.arn
}

# Create access keys for the user
resource "aws_iam_access_key" "bedrock_user_key" {
  user = aws_iam_user.bedrock_user.name
}

output "result" {
  value = {
    values = {
      model = var.model_id
      region   = "us-west-2"
      access_key_id     = aws_iam_access_key.bedrock_user_key.id
      secret_access_key = aws_iam_access_key.bedrock_user_key.secret
    }
    resources = {
        "planes/aws/aws/accounts/817312594854/regions/us-west-2/providers/AWS.iam/policy/${aws_iam_policy.bedrock_policy.name}",

    }
  }
}