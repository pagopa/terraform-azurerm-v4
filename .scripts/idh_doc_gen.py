import yaml
import os
import sys
from pathlib import Path
from collections.abc import MutableMapping
from typing import Dict, List, Any, Optional

# Configuration
DEBUG = True
IDH_PRODUCT_CONFIG_FOLDER = "00_product_configs"
BASE_DIR = "./IDH"

def print_debug(msg: str, data: Any = None) -> None:
    """print_debug debug message if DEBUG is enabled."""
    if DEBUG:
        if data is not None:
            print(f"[DEBUG] {msg}", data)
        else:
            print(f"[DEBUG] {msg}")

def flatten_dict(d: MutableMapping, parent_key: str = '', sep: str = '.') -> Dict[str, Any]:
    """Flatten a nested dictionary structure.
    
    Args:
        d: Input dictionary to flatten
        parent_key: Parent key for nested dictionaries
        sep: Separator for nested keys
        
    Returns:
        Flattened dictionary with dot-separated keys
    """
    if not isinstance(d, MutableMapping):
        return {}
        
    items = []
    for k, v in d.items():
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
    """Dictionary that returns '-' for missing keys."""
    def __missing__(self, key: str) -> str:
        print_debug(f"Missing key in template: {key}")
        return "-"

def validate_directory(path: str, name: str = "directory") -> bool:
    """Validate if directory exists and is accessible."""
    if not os.path.isdir(path):
        print_debug(f"{name} does not exist: {path}")
        return False
    if not os.access(path, os.R_OK):
        print_debug(f"No read permissions for {name}: {path}")
        return False
    return True

def load_yaml_file(file_path: str) -> Optional[Dict]:
    """Safely load YAML content from file."""
    try:
        with open(file_path, 'r') as f:
            return yaml.safe_load(f)
    except yaml.YAMLError as e:
        print_debug(f"Invalid YAML in {file_path}: {e}")
    except Exception as e:
        print_debug(f"Error reading {file_path}: {e}")
    return None

def doc_generate() -> None:
    """Generate documentation from YAML configuration files."""
    print_debug("Starting documentation generation process")
    
    # Validate base directory
    if not validate_directory(BASE_DIR, "IDH directory"):
        print_debug("❌ Error: IDH directory not found or not accessible")
        return
        
    rootdir = f"{BASE_DIR}/{IDH_PRODUCT_CONFIG_FOLDER}"
    if not validate_directory(rootdir, "config directory"):
        print_debug(f"❌ Error: Config directory not found: {rootdir}")
        return
        
    print_debug(f"📂 Root directory set to: {rootdir}")
    config_files = {}
    print_debug("Initialized empty config_files dictionary")
    print_debug(f"Scanning directory: {rootdir}")
    try:
        for root, _, files in os.walk(rootdir):
            if not files:
                print_debug(f"No files found in directory: {root}")
                continue
                
            print_debug(f"Processing directory: {root}")
            
            # Extract platform and environment from path
            parts = [p for p in Path(root).relative_to(rootdir).parts if p != '.']
            platform = parts[-2] if len(parts) >= 2 else ""
            environment = parts[-1] if parts else ""
            print_debug(f"🔍 Extracted platform: '{platform}', environment: '{environment}'")
            
            for file in files:
                if not file.endswith(('.yml', '.yaml')):
                    print_debug(f"⏩ Skipping non-YAML file: {file}")
                    continue
                    
                file_path = os.path.join(root, file)
                print_debug(f"Processing YAML file: {file_path}")
                
                # Load and validate YAML
                yaml_content = load_yaml_file(file_path)
                if not yaml_content:
                    print_debug(f"⚠️  Warning: Skipping invalid YAML file: {file_path}")
                    continue
                    
                # Process module
                module_name = Path(file).stem
                print_debug(f"🔧 Processing module: {module_name}")
                
                if not isinstance(yaml_content, MutableMapping):
                    print_debug(f"⚠️  Warning: Invalid YAML structure in {file_path}, expected dictionary")
                    continue
                
                if module_name not in config_files:
                    config_files[module_name] = []
                    print_debug(f"➕ Created new entry for module: {module_name}")
                
                config = {
                    'platform': platform,
                    'environment': environment,
                    'idh_resources': yaml_content
                }
                config_files[module_name].append(config)
                print_debug(f"✅ Added config for {module_name} - Platform: {platform}, Environment: {environment}")
                
        print_debug("🏁 Finished processing all YAML files")
        print_debug(f"📊 Collected configurations for {len(config_files)} modules")
        
        if not config_files:
            print_debug("⚠️  Warning: No valid YAML configurations found")
            return
            
    except Exception as e:
        print_debug(f"Error during directory traversal: {e}")
        return


    # Generate main library content
    print_debug("📚 Generating main library content")
    lib_content = [
        "# 📚 IDH Available Modules\n",
        "| 📦 Module | 📄 Documentation |",
        "|-----------|------------------|"
    ]
    
    # Add module entries
    for module in sorted(config_files.keys()):
        module_readme = f"{module}/README.md"
        lib_content.append(f"| 📦 {module} | [📄 README]({module_readme}) |")
    
    str_idh_lib = "\n".join(lib_content) + "\n"

    # Process each module
    for module in sorted(config_files.keys()):
        print_debug(f"\nProcessing module: {module}")
        module_path = os.path.join(BASE_DIR, module)
        
        if not validate_directory(module_path, "module directory"):
            print_debug(f"Warning: Module directory not found: {module_path}")
            continue
            
        print_debug(f"Found module directory: {module_path}")
        
        # Process module documentation
        desc_file = os.path.join(module_path, "resource_description.info")
        if not os.path.isfile(desc_file):
            print_debug(f"⚠️  Warning: Description file not found: {desc_file}")
            continue
            
        try:
            with open(desc_file, 'r') as f:
                desc_template = f.read().strip()
                print_debug(f"📝 Loaded description template from {desc_file}")
        except Exception as e:
            print_debug(f"Error reading description file {desc_file}: {e}")
            continue
            
        # Generate module documentation
        module_docs = [
            f"# 📚 IDH {module} Resources\n",
            "| 🖥️ Platform | 🌍 Environment | 🔤 Name | 📝 Description |",
            "|-------------|---------------|---------|----------------|"
        ]
        
        # Add resource entries
        for config in config_files[module]:
            print_debug(f"Processing config - Platform: {config['platform']}, Environment: {config['environment']}")
            print_debug(f"Resources in config: {list(config['idh_resources'].keys())}")
            
            for resource_name, resource_data in sorted(config['idh_resources'].items()):
                try:
                    print_debug(f"Processing resource: {resource_name}")
                    flat_data = flatten_dict(resource_data, '', "_")
                    print_debug(f"Flattened resource data:", flat_data)
                    
                    description = desc_template.format_map(Default(flat_data))
                    print_debug(f"Formatted description: {description}")
                    
                    module_docs.append(
                        f"| {config['platform']} | {config['environment']} | "
                        f" {resource_name} | {description} |"
                    )
                except Exception as e:
                    print_debug(
                        f"Error processing resource {resource_name} in {module}: {e}",
                        file=sys.stderr
                    )
        
        # Write module documentation
        module_lib_file = os.path.join(module_path, "LIBRARY.md")
        module_content = "\n".join(module_docs) + "\n"
        
        try:
            with open(module_lib_file, 'w') as f:
                f.write(module_content)
            print_debug(f"✅ Successfully updated module library: {module_lib_file}")
        except Exception as e:
            print_debug(f"❌ Error writing module library {module_lib_file}: {e}")

    # Write main library file
    lib_file = os.path.join(BASE_DIR, "LIBRARY.md")
    try:
        with open(lib_file, 'w') as f:
            f.write(str_idh_lib)
        print_debug(f"📚 Updated main library file: {lib_file}")
    except Exception as e:
        print_debug(f"❌ Error writing main library file {lib_file}: {e}")
        return
    
    print_debug("✅ Documentation generation completed successfully! 🎉")

if __name__ == "__main__":
  doc_generate()
