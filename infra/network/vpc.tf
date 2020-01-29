resource "aws_eip" "example" {
  vpc = true
}

resource "aws_vpc" "example" {
  cidr_block           = "172.30.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "example-vpc"
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example"
  }
}

resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.example.id
  subnet_id     = aws_subnet.lambda_a_igw.id

  tags = {
    Name = "example lambda NAT"
  }
}

resource "aws_default_route_table" "example_internet_route" {
  default_route_table_id = aws_vpc.example.default_route_table_id

  route {
    gateway_id = aws_internet_gateway.example.id
    cidr_block = "0.0.0.0/0"
  }
}

resource "aws_route_table" "lambda_nat" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.example.id
  }

  tags = {
    Name = "example lambda NAT route"
  }
}

resource "aws_route_table_association" "lambda_a_igw" {
  subnet_id      = aws_subnet.lambda_a_igw.id
  route_table_id = aws_default_route_table.example_internet_route.id
}

resource "aws_route_table_association" "lambda_b_nat" {
  subnet_id      = aws_subnet.lambda_b_nat.id
  route_table_id = aws_route_table.lambda_nat.id
}

resource "aws_route_table_association" "lambda_c_nat" {
  subnet_id      = aws_subnet.lambda_c_nat.id
  route_table_id = aws_route_table.lambda_nat.id
}

resource "aws_route_table_association" "lambda_d_nat" {
  subnet_id      = aws_subnet.lambda_d_nat.id
  route_table_id = aws_route_table.lambda_nat.id
}
