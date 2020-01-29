'''
This is a super thin wrapper that is used in the aws environment.
'''

from func import run
from context import CustomContext

def handler(event, aws_ctx):
  '''
  Is meant to be called from aws lambda as the handler script for an sqs event.
  '''
  print(event)
  with CustomContext(aws_ctx) as custom_context:
    return run(event['Records'][0]['body'], custom_context)
