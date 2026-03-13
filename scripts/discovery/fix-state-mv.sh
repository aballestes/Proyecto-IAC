#!/usr/bin/env bash
cd '/mnt/c/BACKUP SEPTIEMBRE/GIFHUB/PROYECTO IAAC/terraform/environments/contingencia'
terraform state mv \
  'module.vms_contingencia["NGINXPRXLIBPRD2PREP"]' \
  'module.vms_contingencia["NGINXPRXLIBPRDHA"]'
echo "Exit: $?"
