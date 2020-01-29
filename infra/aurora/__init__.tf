data "aws_vpc" "example" {
  filter {
    name   = "tag:Name"
    values = ["example-vpc"]
  }
}

data "aws_security_group" "example_rds" {
  filter {
    name   = "tag:Name"
    values = ["example-rds"]
  }
}
