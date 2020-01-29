resource "aws_sqs_queue" "worker" {
  name                       = "pending-worker"
  max_message_size           = 2048
  message_retention_seconds  = 1209600
  visibility_timeout_seconds = 600
  redrive_policy             = data.template_file.worker_redrive.rendered
  depends_on                 = ["aws_sqs_queue.worker_deadletter"]
}

resource "aws_sqs_queue" "worker_deadletter" {
  name                      = "pending-worker-deadletter"
  message_retention_seconds = 1209600
}

data "template_file" "worker_redrive" {
  template = "${file("${path.module}/redrive/policy.json")}"

  vars = {
    region      = var.region
    account_id  = data.aws_caller_identity.current.account_id
    queue_name  = "pending-worker-deadletter"
    max_receive = 3
  }
}
