#!/usr/bin/env bash
TF_DIR='/mnt/c/BACKUP SEPTIEMBRE/GIFHUB/PROYECTO IAAC/terraform/environments/contingencia'
cd "$TF_DIR"

echo "=== Atributos completos de NGINXPRXLIBPRD2PREP en backup ==="
python3 << 'EOF'
import json

with open('terraform.tfstate.backup') as f:
    state = json.load(f)

for resource in state.get('resources', []):
    mod = resource.get('module', '')
    rtype = resource.get('type', '')
    if 'NGINXPRXLIBPRD2PREP' in mod and rtype == 'vsphere_virtual_machine':
        for inst in resource.get('instances', []):
            attrs = inst.get('attributes', {})
            print(f"Module: {mod}")
            print(f"Type: {rtype}")
            for k, v in sorted(attrs.items()):
                if v is not None and v != '' and v != [] and v != {}:
                    print(f"  {k}: {v}")
            print()
EOF
