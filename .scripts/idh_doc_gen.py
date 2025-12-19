import yaml
import os
import sys
from pathlib import Path
from collections.abc import MutableMapping
from typing import Dict, List, Any, Optional

DEBUG = False
BASE_DIR = "./IDH"
IDH_PRODUCT_CONFIG_FOLDER = "00_product_configs"

def print_debug(msg: str, data: Any = None, level: str = "INFO") -> None:
  print(f"[{level}] {msg}", data if data is not None else "")

def flatten_dict(d: MutableMapping, parent_key: str = '', sep: str = '.') -> Dict[str, Any]:
    if not isinstance(d, MutableMapping):
        return {}

    items = []
    for k, v in sorted(d.items()):  # Ensure order
        if not isinstance(k, str):
            print_debug(f"Skipping non-string key: {k}")
            continue

        new_key = f"{parent_key}{sep}{k}" if parent_key else k

        if isinstance(v, MutableMapping):
            items.extend(flatten_dict(v, new_key, sep).items())
        else:
            items.append((new_key, v))

    return dict(items)

class Default(dict):
    def __missing__(self, key: str) -> str:
        print_debug(f"Missing key in template: {key}", level="INFO")
        return "-"

def validate_directory(path: str, name: str = "directory") -> bool:
    if not os.path.isdir(path):
        print_debug(f"{name} does not exist: {path}", level="ERROR")
        return False
    if not os.access(path, os.R_OK):
        print_debug(f"No read permissions for {name}: {path}", level="ERROR")
        return False
    return True

def load_yaml_file(file_path: str) -> Optional[Dict]:
    try:
        with open(file_path, 'r') as f:
            return yaml.safe_load(f)
    except Exception as e:
        print_debug(f"Error reading {file_path}: {e}", level="WARN")
        return None

def append_platform_header(module_docs: List[str], platform: str) -> None:
      module_docs.append(f"## {platform}")
      module_docs.append("| Product  | Environment | Tier | Description |")
      module_docs.append("|:-------------:|:----------------:|:---------:|:----------------|")
      print_debug(f"Added platform header for {platform}")

def doc_generate() -> None:
    print_debug("Starting documentation generation")

    if not validate_directory(BASE_DIR, "IDH directory"):
        return

    rootdir = f"{BASE_DIR}/{IDH_PRODUCT_CONFIG_FOLDER}"
    if not validate_directory(rootdir, "config directory"):
        return

    config_files = {}
    print_debug("Walking through configuration directory")
    for root, dirs, files in os.walk(rootdir):
        dirs.sort()
        files = sorted([f for f in files if f.endswith(('.yml', '.yaml'))])

        if not files:
            continue

        parts = [p for p in Path(root).relative_to(rootdir).parts if p != '.']
        platform = parts[-2] if len(parts) >= 2 else "All"
        environment = parts[-1] if parts else "All"

        print_debug(f"Processing path: {root} → Platform: {platform}, Environment: {environment}")

        for file in files:
            file_path = os.path.join(root, file)
            print_debug(f"Loading YAML file: {file_path}")
            yaml_content = load_yaml_file(file_path)
            if not yaml_content or not isinstance(yaml_content, MutableMapping):
                print_debug(f"Invalid or empty YAML: {file_path}")
                continue

            module_name = Path(file).stem
            config = {
                'platform': platform,
                'environment': environment if environment != "common" else "All", #convert "common" folder name to "All"
                'idh_resources': yaml_content
            }
            config_files.setdefault(module_name, []).append(config)
            print_debug(f"Added config for module: {module_name}")

    lib_content = [
        "# IDH Available Modules\n",
        "| Module | Documentation |",
        "|-----------|------------------|"
    ]

    for module in sorted(config_files.keys()):
        module_readme = f"{module}/README.md"
        lib_content.append(f"| {module} | [README]({module_readme}) |")

    str_idh_lib = "\n".join(lib_content) + "\n"

    for module in sorted(config_files.keys()):
        print_debug(f"Generating documentation for module: {module}")
        module_path = os.path.join(BASE_DIR, module)
        if not validate_directory(module_path, "module directory"):
            print_debug(f"Skipping missing module directory: {module_path}", level="WARN")
            continue

        desc_file = os.path.join(module_path, "resource_description.info")
        if not os.path.isfile(desc_file):
            print_debug(f"Missing description file: {desc_file}", level="ERROR")
            continue

        try:
            with open(desc_file, 'r') as f:
                desc_template = f.read().strip()
                print_debug(f"Loaded description template for module {module}")
        except:
            continue

        module_docs = [f"# IDH {module} Resources\n"]

        last_platform = None
        last_environment = None
        for config in sorted(config_files[module], key=lambda x: (x['platform'], x['environment'])):
            print_debug(f"Internal processing for platform={config['platform']} env={config['environment']}")
            if last_platform is None:
                # first entry, set the last_platform
                append_platform_header(module_docs, config['platform'])
                last_platform = config['platform']
            if last_environment is None:
                last_environment = config['environment']
            if  config['platform'] != last_platform:
                # add a platform separator
                append_platform_header(module_docs, config['platform'])
                last_platform = config['platform']
            if config['environment'] != last_environment:
                module_docs.append("|---|---|---|---|")
            for resource_name in sorted(config['idh_resources'].keys()):
                resource_data = config['idh_resources'][resource_name]
                flat_data = flatten_dict(resource_data, '', "_")
                description = desc_template.format_map(Default(flat_data))
                module_docs.append(
                    f"| {config['platform']} | {config['environment']} |  {resource_name} | {description} |"
                )


        module_lib_file = os.path.join(module_path, "LIBRARY.md")
        with open(module_lib_file, 'w') as f:
            f.write("\n".join(module_docs) + "\n")
        print_debug(f"Module documentation written to: {module_lib_file}")

    lib_file = os.path.join(BASE_DIR, "LIBRARY.md")
    with open(lib_file, 'w') as f:
        f.write(str_idh_lib)
    print_debug(f"Main library index written to: {lib_file}")

    print_debug("Documentation generation completed successfully!")

if __name__ == "__main__":
    doc_generate()
