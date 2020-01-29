import sys
from box import Box

sys.path.append('./tests/mock')

from mock.rds import Rds
from mock.s3 import DiffDelimiterS3


class DiffDelimiterContext:

  def __init__(self):
    self.var = Box({
      'insert_statement': '...',
      'delimiter': '!',
      'newline': '\n'
    })

    self.aws_context = None

    self.s3 = DiffDelimiterS3()

    self.rds = Rds()
