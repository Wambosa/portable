resource "aws_lambda_layer_version" "etl" {
  filename            = "${path.module}/.build/etl.zip"
  layer_name          = "etl"
  source_code_hash    = "${data.archive_file.etl.output_base64sha256}"
  compatible_runtimes = ["python3.7"]
}

data "archive_file" "etl" {
  type        = "zip"
  source_dir  = "${path.module}/.build/layer"
  output_path = "${path.module}/.build/etl.zip"
}
