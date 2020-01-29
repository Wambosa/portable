resource "aws_security_group" "example_lambda" {
  lifecycle {
    create_before_destroy = true
  }

  name        = "example-lambda"
  description = "lambda network group"
  vpc_id      = aws_vpc.example.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow all outbound traffic"
  }

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow all return traffic to internal lambda instances"
  }

  tags = {
    Name = "example-lambda"
  }
}

resource "aws_security_group" "example_rds" {
  name        = "example-rds"
  description = "Allow inbound traffic from the local vpc"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.example_lambda.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  tags = {
    Name = "example-rds"
  }
}
