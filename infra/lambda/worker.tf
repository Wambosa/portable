resource "aws_lambda_function" "worker" {
  filename         = "${path.module}/.build/worker.zip"
  source_code_hash = data.archive_file.worker.output_base64sha256
  function_name    = "etl-worker"
  role             = data.aws_iam_role.example_lambda.arn
  handler          = "main.handler"
  runtime          = "python3.7"
  layers           = ["${data.aws_lambda_layer_version.etl.arn}"]
  memory_size      = 128
  timeout          = 30

  environment {
    variables = {
      REGION       = var.region
      READ_QUEUE   = data.aws_sqs_queue.worker.name
      DB_HOST      = data.aws_rds_cluster.example.endpoint
      DB_PORT      = 3306
      DB_USER      = var.rds_user
      DB_PASS      = var.rds_pass
      S3_ENDPOINT  = "https://s3.${var.region}.amazonaws.com"
      SQS_ENDPOINT = "https://sqs.${var.region}.amazonaws.com"
    }
  }

  vpc_config {
    subnet_ids         = data.aws_subnet_ids.example.ids
    security_group_ids = ["${data.aws_security_group.example_lambda.id}"]
  }
}

data "archive_file" "worker" {
  type        = "zip"
  source_dir  = "${path.module}/.build/worker"
  output_path = "${path.module}/.build/worker.zip"
}

resource "aws_lambda_event_source_mapping" "worker" {
  event_source_arn = data.aws_sqs_queue.worker.arn
  enabled          = true
  function_name    = aws_lambda_function.worker.arn
  batch_size       = 1
}

resource "aws_lambda_function_event_invoke_config" "worker" {
  function_name          = aws_lambda_function.worker.function_name
  maximum_retry_attempts = 0
}
