resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "172.30.0.0/20"
  availability_zone = "${var.region}a"

  tags = {
    Name = "example-vpc-${var.region}a"
    For  = "public"
  }
}

resource "aws_subnet" "b" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "172.30.16.0/20"
  availability_zone = "${var.region}b"

  tags = {
    Name = "example-vpc-${var.region}b"
    For  = "public"
  }
}

resource "aws_subnet" "c" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "172.30.32.0/20"
  availability_zone = "${var.region}c"

  tags = {
    Name = "example-vpc-${var.region}c"
    For  = "public"
  }
}

resource "aws_subnet" "d" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "172.30.48.0/20"
  availability_zone = "${var.region}d"

  tags = {
    Name = "example-vpc-${var.region}d"
    For  = "public"
  }
}

resource "aws_subnet" "lambda_a_igw" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "172.30.64.0/20"
  availability_zone = "${var.region}a"

  tags = {
    Name = "example-${var.region}a-igw"
  }
}

resource "aws_subnet" "lambda_b_nat" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "172.30.80.0/20"
  availability_zone = "${var.region}b"

  tags = {
    Name = "example-${var.region}b-nat"
    For  = "lambda"
  }
}

resource "aws_subnet" "lambda_c_nat" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "172.30.96.0/20"
  availability_zone = "${var.region}c"

  tags = {
    Name = "example-${var.region}c-nat"
    For  = "lambda"
  }
}

resource "aws_subnet" "lambda_d_nat" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "172.30.112.0/20"
  availability_zone = "${var.region}d"

  tags = {
    Name = "example-${var.region}d-nat"
    For  = "lambda"
  }
}

resource "aws_db_subnet_group" "aurora" {
  name       = "example-aurora-subnet"
  subnet_ids = ["${aws_subnet.aurora_a.id}", "${aws_subnet.aurora_c.id}", "${aws_subnet.aurora_d.id}"]

  tags = {
    Name = "Generic RDS Aurora subnet"
  }
}

resource "aws_subnet" "aurora_a" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "172.30.176.0/24"
  availability_zone = "${var.region}a"

  tags = {
    For = "aurora"
  }
}

resource "aws_subnet" "aurora_c" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "172.30.192.0/24"
  availability_zone = "${var.region}c"

  tags = {
    For = "aurora"
  }
}

resource "aws_subnet" "aurora_d" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "172.30.208.0/24"
  availability_zone = "${var.region}d"

  tags = {
    For = "aurora"
  }
}
