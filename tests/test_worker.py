import sys
sys.path.append('./tests')
sys.path.append('./src/func')

from worker import run

from context import (
  VoidContext,
  DiffDelimiterContext
)

json_event = '''
{
  "bucket": "nothing",
  "key": "here"
}
'''

def test_worker_understands_json_event():
  assert run(json_event, VoidContext())


def test_worker_honors_configured_delimiter():
  assert run(json_event, DiffDelimiterContext())
