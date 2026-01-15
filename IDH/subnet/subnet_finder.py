import ipaddress
import json
import sys
import os
import time
import tempfile
from pathlib import Path

def get_auto_offset(vnet_key: str, subnet_name: str, existing_subnets: list[str]) -> int:
    """
    Determina l'offset automatico usando un file di registro temporaneo.
    """
    tmp_dir = Path(tempfile.gettempdir())
    registry_file = tmp_dir / f"tf_subnet_registry_{vnet_key}.json"
    lock_dir = tmp_dir / f"tf_subnet_registry_{vnet_key}.lock"

    max_retries = 50
    for _ in range(max_retries):
        try:
            os.mkdir(lock_dir)
            break
        except FileExistsError:
            time.sleep(0.5)
    else:
        return 0

    try:
        registry = {}
        if registry_file.exists():
            try:
                with open(registry_file, 'r') as f:
                    registry = json.load(f)
            except Exception:
                registry = {}

        now = time.time()
        registry = {name: ts for name, ts in registry.items() if now - ts < 60}
        
        registry[subnet_name] = now

        with open(registry_file, 'w') as f:
            json.dump(registry, f)

        new_subnets = sorted([name for name in registry.keys() if name not in existing_subnets])
        
        if subnet_name in new_subnets:
            return new_subnets.index(subnet_name)
        return 0

    finally:
        try:
            if os.path.exists(lock_dir):
                os.rmdir(lock_dir)
        except Exception:
            pass

def find_next_available_cidr(used_cidrs: list[str], desired_subnet_size: str, starting_cidr: str, offset: int = 0) -> str:
    """
    Trova il CIDR disponibile non in conflitto con quelli esistenti, applicando un offset.

    Args:
        used_cidrs: Lista di CIDR già in uso (es. ["10.0.0.0/24", "10.0.1.0/24"])
        desired_subnet_size: Dimensione della subnet desiderata (es. "/24" o "/28")
        starting_cidr: CIDR di partenza per la ricerca
        offset: Numero di CIDR disponibili da saltare

    Returns:
        str: Il CIDR disponibile con la dimensione richiesta
    """
    # Converti la dimensione della subnet in un intero (es. "/24" -> 24)
    desired_prefix = int(desired_subnet_size)

    # Converti tutti i CIDR in uso in oggetti IPv4Network
    used_networks = [ipaddress.IPv4Network(cidr) for cidr in used_cidrs]

    # Parti dal range specificato
    start_network = ipaddress.IPv4Network(starting_cidr)

    found_count = 0
    # Itera attraverso tutte le possibili subnet della dimensione desiderata
    for candidate in start_network.subnets(new_prefix=desired_prefix):
        # Verifica se la subnet candidata si sovrappone con qualche rete esistente
        is_overlapping = any(
            candidate.overlaps(used_network)
            for used_network in used_networks
        )

        if not is_overlapping:
            if found_count == offset:
                return str(candidate), str(candidate[4]), str(candidate[-2])  # Restituisci il CIDR disponibile e i primi/ultimi IP utilizzabili (esclude ip riservati da Azure)
            found_count += 1

    raise ValueError(f"Nessun CIDR disponibile trovato nel range {starting_cidr} con dimensione /{desired_prefix} e l'offset {offset}")


def main(query):
  used_subnets = json.loads(query.get('used_subnets', '{}'))
  subnet_name = query.get('subnet_name')
  vnet_key = query.get('vnet_key', 'default_vnet')
  desired_prefix = query['desired_prefix']
  starting_cidr = query['starting_cidr']

  # 1. Se la subnet esiste già, restituisci il suo CIDR attuale
  if subnet_name in used_subnets:
      cidr = used_subnets[subnet_name]
      network = ipaddress.IPv4Network(cidr)
      print(json.dumps({
          "cidr": str(network),
          "first": str(network[4]),
          "last": str(network[-2])
      }))
      return

  # 2. Se è una nuova subnet, calcola l'offset automaticamente
  offset = 0
  if subnet_name:
      offset = get_auto_offset(vnet_key, subnet_name, list(used_subnets.keys()))

  used_cidrs = list(used_subnets.values())
  target_cidr, first_ip, last_ip = find_next_available_cidr(used_cidrs, desired_prefix, starting_cidr, offset)
  print(json.dumps({
      "cidr": target_cidr,
      "first": first_ip,
      "last": last_ip
  }))


if __name__ == "__main__":
  input_data = sys.stdin.read()
  if not input_data:
      sys.exit(0)
  query = json.loads(input_data)
  main(query)
