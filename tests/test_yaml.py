import os
import fnmatch
import yaml
from box import Box

CONFIG_DIR = './config'

def test_yaml_config_syntax():
  for _root, _dir, files in os.walk(CONFIG_DIR):
    for suffix in fnmatch.filter(files, '*.yml'):
      with open(f'{CONFIG_DIR}/{suffix}', 'r') as file:
        raw = file.read()
        Box(yaml.full_load(raw))
        print(raw)

  assert True
