awslocal s3 mb s3://raw-data
awslocal sqs create-queue --queue-name pending-worker
