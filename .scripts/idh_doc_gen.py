import yaml
import os
from pathlib import Path
from collections.abc import MutableMapping

DEBUG = False

def print_debug(msg):
  if DEBUG:
    print(msg)

def flatten_dict(d: MutableMapping, parent_key: str = '',
               sep: str = '.') -> MutableMapping:
    # Inizializza una lista vuota per memorizzare le coppie chiave-valore appiattite
    items = []
    # Itera su tutte le coppie chiave-valore del dizionario
    for k, v in d.items():
        # Costruisce la nuova chiave combinando la chiave genitore con quella corrente
        new_key = parent_key + sep + k if parent_key else k
        # Se il valore è un altro dizionario (MutableMapping)
        if isinstance(v, MutableMapping):
            # Chiamata ricorsiva per appiattire il sotto-dizionario
            items.extend(flatten_dict(v, new_key, sep=sep).items())
        else:
            # Se il valore non è un dizionario, aggiunge la coppia chiave-valore
            items.append((new_key, v))
    # Converte la lista di tuple in un dizionario e lo restituisce
    return dict(items)

class Default(dict):
  def __missing__(self, key):
    return "-"

def doc_generate():
  rootdir = "./IDH/00_idh"
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
            config = {
              'platform': platform,
              'environment': environment,
              'idh_resources': yaml_content
            }
            config_files[Path(file).stem].append(config)


  str_idh_lib = ""
  saved_idh_lib = ""
  try:
    with open("./IDH/LIBRARY.md", "r") as idh_lib:
      saved_idh_lib = idh_lib.read()
  except:
    saved_idh_lib = ""
    print_debug("idh lib not found, creating new one")

  str_idh_lib = str_idh_lib + f"# IDH available modules\n"
  str_idh_lib = str_idh_lib + "|Module| Doc | \n"
  str_idh_lib = str_idh_lib + "|------|---------|\n"
  # genera la documentazione
  for module in sorted(config_files.keys()):
    print_debug(f"processing module {module}")
    str_idh_lib = str_idh_lib + f"|{module}|[README]({module}/README.md)|\n"
    if not os.path.exists(f"./IDH/{module}"):
      print_debug(f"folder {module} not found, skipping doc generation")
      continue

    str_module_lib = ""
    with open(f'./IDH/{module}/resource_description.info') as desc:
      desc_string = desc.read()
      str_module_lib = str_module_lib + f"# IDH {module} resources\n"
      str_module_lib = str_module_lib + "|Platform| Environment| Name | Description | \n"
      str_module_lib = str_module_lib + "|------|---------|----|---|\n"
      for config in sorted(config_files[module], key=lambda x: (x['platform'], x['environment'])):
        for resource_name in sorted(config['idh_resources'].keys()):
          # appiattisce il dizionario e wrappa con Default per restituire "-" se la chiave non esiste
          # usa "_" come separatore per evitare conflitti con la dot notation (non utilizzabile in modo safe)
          d = Default(flatten_dict(config['idh_resources'][resource_name], '', "_"))
          str_module_lib = str_module_lib + f"|{config['platform']}|{config['environment']}|{resource_name}| {desc_string.rstrip().format_map(d)} |\n"

      saved_module_lib = ""
      try:
        with open(f"./IDH/{module}/LIBRARY.md", "r") as r_module_lib:
          saved_module_lib = r_module_lib.read()
      except:
        saved_module_lib = ""
      if str_module_lib != saved_module_lib:
        print_debug(f"updating module {module} lib to file")
        print_debug(f"old: '{saved_module_lib}'")
        print_debug(f"new: '{str_module_lib}'")
        with open(f"./IDH/{module}/LIBRARY.md", "w") as module_lib:
          module_lib.write(str_module_lib)

  if str_idh_lib != saved_idh_lib:
    print_debug(f"updating idh lib to file")
    print_debug(f"old: '{saved_idh_lib}'")
    print_debug(f"new: '{str_idh_lib}'")
    with open("./IDH/LIBRARY.md", "w") as idh_lib:
      idh_lib.write(str_idh_lib)



if __name__ == "__main__":
  doc_generate()
