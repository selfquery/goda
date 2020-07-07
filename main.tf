# localstack provider
provider "aws" {
  region     = "us-east-1"
  access_key = "123"
  secret_key = "xyz"

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  s3_force_path_style         = true

  endpoints {
    apigateway     = "http://localstack:4566"
    cloudformation = "http://localstack:4566"
    cloudwatch     = "http://localstack:4566"
    dynamodb       = "http://localstack:4566"
    es             = "http://localstack:4566"
    firehose       = "http://localstack:4566"
    iam            = "http://localstack:4566"
    kinesis        = "http://localstack:4566"
    lambda         = "http://localstack:4566"
    route53        = "http://localstack:4566"
    redshift       = "http://localstack:4566"
    s3             = "http://localstack:4566"
    secretsmanager = "http://localstack:4566"
    ses            = "http://localstack:4566"
    sns            = "http://localstack:4566"
    sqs            = "http://localstack:4566"
    ssm            = "http://localstack:4566"
    stepfunctions  = "http://localstack:4566"
    sts            = "http://localstack:4566"
  }

}

# iam role for lambda service
resource "aws_iam_role" "iam_service" {
  name = "iam_service"

  assume_role_policy = <<EOF
    {
    "Version": "2012-10-17",
    "Statement": [
        {
        "Action": "sts:AssumeRole",
        "Principal": {
            "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
        }
    ]
    }
    EOF
}

# lambda function
resource "aws_lambda_function" "service" {
  filename      = "service.zip"
  function_name = "service"
  handler       = "service"
  role          = "aws_iam_role.iam_service.arn"

  source_code_hash = "filebase64sha256('service.zip')"

  runtime     = "go1.x"
  memory_size = 128
  timeout     = 1

  environment {
    variables = {
      foo = "bar"
    }
  }
}

# give api gateway access to lambda function
resource "aws_lambda_permission" "service" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.service.arn}"
  principal     = "apigateway.amazonaws.com"
}

# api gateway
resource "aws_api_gateway_resource" "service" {
  rest_api_id = "${aws_api_gateway_rest_api.service.id}"
  parent_id   = "${aws_api_gateway_rest_api.service.root_resource_id}"
  path_part   = "service"
}

resource "aws_api_gateway_rest_api" "service" {
  name = "service"
}

# api gateway GET method
resource "aws_api_gateway_method" "service" {
  rest_api_id   = "${aws_api_gateway_rest_api.service.id}"
  resource_id   = "${aws_api_gateway_resource.service.id}"
  http_method   = "GET"
  authorization = "NONE"
}

# api gateway POST method
resource "aws_api_gateway_integration" "service" {
  rest_api_id             = "${aws_api_gateway_rest_api.service.id}"
  resource_id             = "${aws_api_gateway_resource.service.id}"
  http_method             = "${aws_api_gateway_method.service.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.service.arn}/invocations"
}

# define api gateway url
resource "aws_api_gateway_deployment" "service_v1" {
  depends_on = [
    aws_api_gateway_integration.service
  ]
  rest_api_id = "${aws_api_gateway_rest_api.service.id}"
  stage_name  = "v1"
}
