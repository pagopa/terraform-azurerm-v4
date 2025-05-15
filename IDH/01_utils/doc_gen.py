import yaml
import os
from pathlib import Path

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
              'idh_resources': list(yaml_content.keys())
            }
            config_files[Path(file).stem].append(a)

  for module in config_files.keys():
    with open(f"./IDH/{module}/LIBRARY.md", "w") as l:
      l.write(f"# IDH {module} resources\n")
      l.write("|Platform| Environment| Name |\n")
      l.write("|------|---------|----|\n")
      for config in config_files[module]:
        print(config)
        l.write(f"|{config['platform']}|{config['environment']}|{config['idh_resources']}|\n")



if __name__ == "__main__":
  doc_generate()
