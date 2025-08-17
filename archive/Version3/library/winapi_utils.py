import os
import json

REGISTRY_FILE = 'winapi_id_registry.json'

def load_registry():
    if os.path.exists(REGISTRY_FILE):
        with open(REGISTRY_FILE, 'r') as f:
            return json.load(f)
    return {}

def save_registry(reg):
    with open(REGISTRY_FILE, 'w') as f:
        json.dump(reg, f, indent=2)

def get_or_assign_id(reg, html_id, next_id):
    if html_id in reg:
        return reg[html_id], next_id
    reg[html_id] = next_id
    return next_id, next_id+1
