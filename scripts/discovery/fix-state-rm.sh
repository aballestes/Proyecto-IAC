#!/usr/bin/env bash
cd '/mnt/c/BACKUP SEPTIEMBRE/GIFHUB/PROYECTO IAAC/terraform/environments/contingencia'
echo "=== Estado actual para NGINXPRX ==="
terraform state list | grep -i NGINXPRX
echo ""
echo "=== Removiendo entrada obsoleta NGINXPRXLIBPRD2PREP ==="
terraform state rm 'module.vms_contingencia["NGINXPRXLIBPRD2PREP"]'
echo "Exit: $?"
echo ""
echo "=== Estado después ==="
terraform state list | grep -i NGINXPRX
