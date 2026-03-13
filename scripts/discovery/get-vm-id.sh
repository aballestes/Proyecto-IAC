#!/usr/bin/env bash
TF_DIR='/mnt/c/BACKUP SEPTIEMBRE/GIFHUB/PROYECTO IAAC/terraform/environments/contingencia'
cd "$TF_DIR"

echo "=== Buscando ID de NGINXPRX en terraform.tfstate.backup ==="
python3 << 'EOF'
import json

with open('terraform.tfstate.backup') as f:
    state = json.load(f)

for resource in state.get('resources', []):
    mod = resource.get('module', '')
    if 'NGINXPRX' in mod:
        for inst in resource.get('instances', []):
            attrs = inst.get('attributes', {})
            print(f"Module: {mod}")
            print(f"  name: {attrs.get('name')}")
            print(f"  id: {attrs.get('id')}")
            print(f"  uuid: {attrs.get('uuid')}")
            print()
EOF
