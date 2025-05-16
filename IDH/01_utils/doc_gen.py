import yaml
import os
from pathlib import Path
from collections.abc import MutableMapping


def flatten_dict(d: MutableMapping, parent_key: str = '',
                 sep: str = '.') -> MutableMapping:
  items = []
  for k, v in d.items():
    new_key = parent_key + sep + k if parent_key else k
    if isinstance(v, MutableMapping):
      items.extend(flatten_dict(v, new_key, sep=sep).items())
    else:
      items.append((new_key, v))
  return dict(items)

class Default(dict):
  def __missing__(self, key):
    return "-"

def doc_generate():
  rootdir = f"./IDH/00_idh"
  config_files = {}
  for root, _, files in os.walk(rootdir):
    for file in files:
      if file.endswith('.yml'):
        file_path = os.path.join(root, file)
        parts = root.split(os.sep)
        # Ottieni i nomi delle cartelle di primo e secondo livello
        platform = parts[-2] if len(parts) >= 2 else ""
        environment = parts[-1] if len(parts) >= 1 else ""

        with open(file_path, 'r') as f:
          yaml_content = yaml.safe_load(f)
          if yaml_content:
            if config_files.get(Path(file).stem) is None:
              config_files[Path(file).stem] = []
            a = {
              'platform': platform,
              'environment': environment,
              'idh_resources': yaml_content
            }
            config_files[Path(file).stem].append(a)

  for module in config_files.keys():
    with open(f"./IDH/{module}/LIBRARY.md", "w") as l:
      with open(f'./IDH/{module}/resource_description.info') as desc:
        desc_string = desc.read()
        l.write(f"# IDH {module} resources\n")
        l.write("|Platform| Environment| Name | Description | \n")
        l.write("|------|---------|----|---|\n")
        for config in config_files[module]:
          for resource_name in config['idh_resources'].keys():
            d = Default(flatten_dict(config['idh_resources'][resource_name], '', "|"))
            l.write(f"|{config['platform']}|{config['environment']}|{resource_name}| {desc_string.format_map(d)}|\n")



if __name__ == "__main__":
  doc_generate()
