resource "aws_rds_cluster" "example" {
  cluster_identifier        = "etl-example"
  engine                    = "aurora"
  master_username           = var.rds_user
  master_password           = var.rds_pass
  backup_retention_period   = 1
  engine_mode               = "serverless"
  skip_final_snapshot       = false
  final_snapshot_identifier = "etl-example-pre-delete"
  db_subnet_group_name      = "example-aurora-subnet"
  vpc_security_group_ids    = ["${data.aws_security_group.example_rds.id}"]

  scaling_configuration {
    auto_pause               = true
    max_capacity             = 2
    min_capacity             = 1
    seconds_until_auto_pause = 300
  }

  lifecycle {
    ignore_changes = [
      "engine_version",
    ]
  }
}
