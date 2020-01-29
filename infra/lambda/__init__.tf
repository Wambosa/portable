data "aws_caller_identity" "current" {}

data "aws_iam_role" "example_lambda" {
  name = "example-lambda"
}

data "aws_vpc" "example" {
  filter {
    name   = "tag:Name"
    values = ["example-vpc"]
  }
}

data "aws_subnet_ids" "example" {
  vpc_id = data.aws_vpc.example.id

  tags = {
    For = "lambda"
  }
}

data "aws_security_group" "example_lambda" {
  filter {
    name   = "tag:Name"
    values = ["example-lambda"]
  }
}

data "aws_rds_cluster" "example" {
  cluster_identifier = "etl-example"
}

data "aws_sqs_queue" "worker" {
  name = "pending-worker"
}

data "aws_lambda_layer_version" "etl" {
  layer_name = "etl"
}
