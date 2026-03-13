#!/usr/bin/env bash
TF_DIR='/mnt/c/BACKUP SEPTIEMBRE/GIFHUB/PROYECTO IAAC/terraform/environments/contingencia'
cd "$TF_DIR"

echo "=== Importando NGINXPRXLIBPRDHA al tfstate ==="
echo "Ruta: /IBM/vm/Discovered virtual machine/NGINXPRXLIBPRDHA"
echo ""

terraform import \
  'module.vms_contingencia["NGINXPRXLIBPRDHA"].vsphere_virtual_machine.vm' \
  '/IBM/vm/Discovered virtual machine/NGINXPRXLIBPRDHA'

echo ""
echo "Exit code: $?"
echo ""
echo "=== Estado NGINXPRXLIBPRDHA después del import ==="
terraform state list | grep NGINXPRXLIBPRDHA
