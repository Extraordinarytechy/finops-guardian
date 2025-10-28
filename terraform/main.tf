provider "aws" {
  region = "us-east-1"
}

# --- 1. IAM Role and Policies (Least Privilege) ---

resource "aws_iam_role" "lambda_role" {
  name = "FinOpsGuardianLambdaRole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Project = "FinOps-Guardian"
  }
}

# Policy to allow basic Lambda execution (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for Cost Explorer and SES
resource "aws_iam_role_policy" "lambda_custom" {
  name = "FinOpsGuardianLambdaPolicy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "ce:GetCostAndUsage",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = "ses:SendEmail",
        Resource = "*"
      }
    ]
  })
}

# --- 2. The Lambda Function ---

# We need the zip file from the ../lambda directory
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../Lambda/cost_reporter.py"
  output_path = "../Lambda/cost_reporter.zip"
}

resource "aws_lambda_function" "cost_reporter" {
  function_name = "FinOpsGuardian"
  role          = aws_iam_role.lambda_role.arn
  handler       = "cost_reporter.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60
  
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SENDER_EMAIL    = var.sender_email
      RECIPIENT_EMAIL = var.recipient_email
    }
  }

  tags = {
    Project = "FinOps-Guardian"
  }
}

# --- 3. The Automation Trigger ---

resource "aws_cloudwatch_event_rule" "daily_trigger" {
  name                = "TriggerFinOpsGuardianDaily"
  description         = "Triggers the cost reporter lambda every day at 12:00 PM UTC"
  # Runs at 12:00 PM UTC every day
  schedule_expression = "cron(0 12 * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_trigger.name
  target_id = "InvokeLambda"
  arn       = aws_lambda_function.cost_reporter.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_reporter.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_trigger.arn
}