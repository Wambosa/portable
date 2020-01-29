'''
Here we implement our own poller.
This is the equilvalent sqs-to-lambda integration AWS does under the hood.
'''
import time
import traceback

import boto3
import configargparse
from box import Box

from func import run
from context import CustomContext

def main(args):
  '''
  The entry point for local runs or container runs
  '''
  args = remove_blank_args(args)

  while True:
    sqs = boto3.client(
      'sqs',
      endpoint_url=args.sqs_endpoint
    )
    read_url = sqs.get_queue_url(QueueName=args.read_queue)['QueueUrl']
    res = sqs.receive_message(
      QueueUrl=read_url,
      MaxNumberOfMessages=args.poll_batch_size,
    )

    for message in res.get('Messages', []):
      event = message['Body']

      with CustomContext(None, args) as custom_context:
        print(event)
        try:
          run(event, custom_context)
          sqs.delete_message(QueueUrl=read_url, ReceiptHandle=message['ReceiptHandle'])
        except Exception as e:
          traceback.print_tb(e.__traceback__)

    time.sleep(args.poll_interval)

def remove_blank_args(args):
  '''
  We want the argument behaviour to emulate aws lambda and aws ECS.
  So if a value is unset, we want it to not exist as a key starting out.
  A downstream step will populate any missing values to sane default values.
  '''
  clean = {}
  for prop in args:
    if not args[prop] is None:
      clean[prop] = args[prop]
  return Box(clean)

if __name__ == '__main__':
  P = configargparse.ArgumentParser()

  P.add_argument('--read_queue', env_var='READ_QUEUE', type=str)
  P.add_argument('--poll_batch_size', type=int, default=1)
  P.add_argument('--poll_interval', type=int, default=15)

  P.add_argument('--region', type=str, env_var='AWS_DEFAULT_REGION', default='us-east-1')
  P.add_argument('--const_path', type=str, default='./const.yml')

  P.add_argument('--s3_endpoint', env_var='S3_ENDPOINT', type=str, default='http://localhost:4572')
  P.add_argument('--sqs_endpoint', env_var='SQS_ENDPOINT', type=str, default='http://localhost:4576')

  P.add_argument('--db_host', env_var='DB_HOST', type=str, default='localhost')
  P.add_argument('--db_port', env_var='DB_PORT', type=int, default=3306)
  P.add_argument('--db_name', env_var='DB_NAME', type=str, default='activity')
  P.add_argument('--db_user', env_var='DB_USER', type=str, default='root')
  P.add_argument('--db_pass', env_var='DB_PASS', type=str, default='password')

  P.add_argument('--newline', type=str)
  P.add_argument('--delimiter', type=str)
  P.add_argument('--insert_statement', type=str)

  main(P.parse_args(namespace=Box()))
