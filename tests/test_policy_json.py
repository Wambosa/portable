import os
import re
import fnmatch
import json

INFRA_DIR = './infra'

def test_policy_json_syntax():
  for root, _dir, files in os.walk(INFRA_DIR):
    for suffix in fnmatch.filter(files, '*.json'):
      if not '.terraform' in root:
        path = f'{root}/{suffix}'
        with open(path, 'r') as file:
          print(f'testing json: {path}')
          raw = file.read()
          # we use a template language that json does not support (in terraform)
          # expand the template to a json valid value
          json.loads(re.sub(r'\$\{\w{1,}\}', '1', raw))

  assert True
