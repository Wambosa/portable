resource "aws_iam_role" "example_lambda" {
  name               = "example-lambda"
  assume_role_policy = "${file("./policy/assume_role_lambda.json")}"
}

resource "aws_iam_policy" "example_lambda" {
  name        = "example-lambda"
  description = "give lambda access to the resources required"
  policy      = "${file("./policy/example_lambda.json")}"
}

resource "aws_iam_role_policy_attachment" "example_lambda" {
  role       = aws_iam_role.example_lambda.name
  policy_arn = aws_iam_policy.example_lambda.arn
}
