'''
Business logic should the same entry signature run(event, context)
In order for all wrapper types to be compatible.
'''

import json


def run(event, context):
  '''
  Business logic lives here.
  '''
  work = json.loads(event)
  bucket = work['bucket']
  key = work['key']
  records = []

  print(f'download: s3://{bucket}/{key}')
  file = context.s3.get_object(Bucket=bucket, Key=key)
  raw = file['Body'].read()

  for line in raw.decode('utf-8').split(context.var.newline):
    records.append(tuple(line.split(context.var.delimiter)))

  insert_statement = context.var.insert_statement

  print(f'insert records: {len(records)}')
  res = context.rds.executemany(insert_statement, records)

  print(res)
  print('done')
  return True
