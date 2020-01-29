'''
Handles sane configuration, and knows how to establish dependencies for related functions.
A context is unique to the class of problem that a group of functions are solving.
It will hold shared dependencies between all functions of the same problemspace.
'''

import os
import yaml
import boto3
from box import Box
from lib.rds import Aurora

class CustomContext:
  '''
  Interface for any configuration or service dependency.
  '''

  def __init__(self, aws_ctx=None, args=None):
    const_path = args.get('const_path') if args else './const.yml'
    const = load_const(const_path)
    env = load_env()
    var = dict()
    var.update(const)
    var.update(env)
    if args:
      var.update(args)
    self.var = Box(var)

    self.aws_context = aws_ctx

    self.s3 = boto3.client(
      's3',
      endpoint_url=self.var.get('s3_endpoint')
    )

    self.rds = None

  def __enter__(self):
    self.rds = Aurora(
      host=self.var.db_host,
      port=int(self.var.db_port),
      db=self.var.db_name,
      user=self.var.db_user,
      password=self.var.db_pass
    ).__enter__()
    return self

  def __exit__(self, _type, _value, _traceback):
    return self.rds.conn.close()


def load_env():
  '''
  Captures any environment variable(s)
  and creates a property in lowercase for it.

  Returns:
  dict: with properties equal to current environment.
  '''
  env = {}
  for name in os.environ:
    env[name.lower()] = os.environ.get(name)
  return env


def load_const(path='./const.yml'):
  '''
  Captures any variable(s) found in configuration file.

  Returns:
  dict: with properties equal to configuration file.
  '''
  raw = None
  const = {}
  try:
    with open(path, 'r') as file:
      raw = file.read()
  except (FileNotFoundError, IOError):
    print('No custom configuration file present for this function')

  if not raw is None:
    try:
      const = yaml.full_load(raw)
    except yaml.YAMLError as err:
      print('custom configuration file load error')
      print(str(err))
  return const
