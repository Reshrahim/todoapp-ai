terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
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

# Ensure uniqueness
resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  # Fixed ARN format - removed double colon, added account ID wildcard
  model_arn   = "arn:aws:bedrock:${var.context.aws.region}:*:foundation-model/${var.context.resource.properties.model}"
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
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ],
        Resource = [
          local.model_arn
        ]
      },
      {
        Effect   = "Allow",
        Action   = [
          "bedrock:ListFoundationModels",
          "bedrock:GetFoundationModel"
        ],
        Resource = "*"
      }
    ]
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
      model = var.context.resource.properties.model
      region   = var.context.aws.region
    }
    secrets = {
      access_key_id     = aws_iam_access_key.bedrock_user_key.id
      secret_access_key = aws_iam_access_key.bedrock_user_key.secret
    }
  }
}
