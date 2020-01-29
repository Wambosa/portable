variable "region" {
  default = "us-east-1"
}

variable "environment" {
  default = "lab"
}

provider "aws" {
  region = "${var.region}"
}
