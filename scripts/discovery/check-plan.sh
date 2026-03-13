#!/usr/bin/env bash
cd '/mnt/c/BACKUP SEPTIEMBRE/GIFHUB/PROYECTO IAAC/terraform/environments/contingencia'
terraform plan 2>&1 | grep -E "Plan:|will be created|will be destroyed|must be replaced|# vsphere|# module"
