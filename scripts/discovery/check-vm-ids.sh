#!/usr/bin/env bash
TF_DIR='/mnt/c/BACKUP SEPTIEMBRE/GIFHUB/PROYECTO IAAC/terraform/environments/contingencia'
cd "$TF_DIR"

echo "=== Revisando formato de ID en tfstate actual (VMs gestionadas) ==="
python3 << 'EOF'
import json

with open('terraform.tfstate') as f:
    state = json.load(f)

for resource in state.get('resources', []):
    if resource.get('type') == 'vsphere_virtual_machine':
        mod = resource.get('module', '')
        for inst in resource.get('instances', []):
            attrs = inst.get('attributes', {})
            print(f"Module: {mod}")
            print(f"  name: {attrs.get('name')}")
            print(f"  id: {attrs.get('id')}")
            print(f"  moid: {attrs.get('moid')}")
            print(f"  uuid: {attrs.get('uuid')}")
            print()
EOF
