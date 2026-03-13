#!/bin/bash
# Script de importación Terraform — contingencia
# Generado: 2026-03-03T14:54:43.943209
# Total VMs: 28
# ADVERTENCIA: Ejecutar desde el directorio del entorno Terraform
# Ejemplo: cd terraform/environments/contingencia

set -e  # Detener en error
echo "Iniciando importación de 28 VMs en contingencia..."

echo "Importando: NGINXPRXLIBPRD2PREP"
terraform import \
  'module.vms_contingencia["NGINXPRXLIBPRD2PREP"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/NGINXPRXLIBPRD2PREP" || echo "WARNING: Falló import de NGINXPRXLIBPRD2PREP"

echo "Importando: NGIPRUP02MRPREP"
terraform import \
  'module.vms_contingencia["NGIPRUP02MRPREP"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/NGIPRUP02MRPREP" || echo "WARNING: Falló import de NGIPRUP02MRPREP"

echo "Importando: NGINXATALLAPREP"
terraform import \
  'module.vms_contingencia["NGINXATALLAPREP"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/NGINXATALLAPREP" || echo "WARNING: Falló import de NGINXATALLAPREP"

echo "Importando: VROPSPREP"
terraform import \
  'module.vms_contingencia["VROPSPREP"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/VROPSPREP" || echo "WARNING: Falló import de VROPSPREP"

echo "Importando: SAGSNLC"
terraform import \
  'module.vms_contingencia["SAGSNLC"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/SAGSNLC" || echo "WARNING: Falló import de SAGSNLC"

echo "Importando: AWPC"
terraform import \
  'module.vms_contingencia["AWPC"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/AWPC" || echo "WARNING: Falló import de AWPC"

echo "Importando: SAAC"
terraform import \
  'module.vms_contingencia["SAAC"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/SAAC" || echo "WARNING: Falló import de SAAC"

echo "Importando: POSTIBDREALPREP"
terraform import \
  'module.vms_contingencia["POSTIBDREALPREP"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/POSTIBDREALPREP" || echo "WARNING: Falló import de POSTIBDREALPREP"

echo "Importando: POSTIBDOFFPREP"
terraform import \
  'module.vms_contingencia["POSTIBDOFFPREP"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/POSTIBDOFFPREP" || echo "WARNING: Falló import de POSTIBDOFFPREP"

echo "Importando: POSTIBDNIXPREP"
terraform import \
  'module.vms_contingencia["POSTIBDNIXPREP"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/POSTIBDNIXPREP" || echo "WARNING: Falló import de POSTIBDNIXPREP"

echo "Importando: NGIPRUP01MRPREP"
terraform import \
  'module.vms_contingencia["NGIPRUP01MRPREP"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/NGIPRUP01MRPREP" || echo "WARNING: Falló import de NGIPRUP01MRPREP"

echo "Importando: LT"
terraform import \
  'module.vms_contingencia["LT"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/LT" || echo "WARNING: Falló import de LT"

echo "Importando: MGORACLEC"
terraform import \
  'module.vms_contingencia["MGORACLEC"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/MGORACLEC" || echo "WARNING: Falló import de MGORACLEC"

echo "Importando: SG_vDSM_0_21"
terraform import \
  'module.vms_contingencia["SG_vDSM_0_21"].vsphere_virtual_machine.vm' \
  "/IBM/vm/SG/SG_vDSM_0_21" || echo "WARNING: Falló import de SG_vDSM_0_21"

echo "Importando: SG_vSSM_0_17"
terraform import \
  'module.vms_contingencia["SG_vSSM_0_17"].vsphere_virtual_machine.vm' \
  "/IBM/vm/SG/SG_vSSM_0_17" || echo "WARNING: Falló import de SG_vSSM_0_17"

echo "Importando: POSTIAPPREP"
terraform import \
  'module.vms_contingencia["POSTIAPPREP"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/POSTIAPPREP" || echo "WARNING: Falló import de POSTIAPPREP"

echo "Importando: VAULTC"
terraform import \
  'module.vms_contingencia["VAULTC"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/VAULTC" || echo "WARNING: Falló import de VAULTC"

echo "Importando: SG_vSCM_0_2"
terraform import \
  'module.vms_contingencia["SG_vSCM_0_2"].vsphere_virtual_machine.vm' \
  "/IBM/vm/SG/SG_vSCM_0_2" || echo "WARNING: Falló import de SG_vSCM_0_2"

echo "Importando: VCSAC"
terraform import \
  'module.vms_contingencia["VCSAC"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/VCSAC" || echo "WARNING: Falló import de VCSAC"

echo "Importando: PVWAC"
terraform import \
  'module.vms_contingencia["PVWAC"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/PVWAC" || echo "WARNING: Falló import de PVWAC"

echo "Importando: SG_vSCM_0_1"
terraform import \
  'module.vms_contingencia["SG_vSCM_0_1"].vsphere_virtual_machine.vm' \
  "/IBM/vm/SG/SG_vSCM_0_1" || echo "WARNING: Falló import de SG_vSCM_0_1"

echo "Importando: FRC"
terraform import \
  'module.vms_contingencia["FRC"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/FRC" || echo "WARNING: Falló import de FRC"

echo "Importando: EX3"
terraform import \
  'module.vms_contingencia["EX3"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/EX3" || echo "WARNING: Falló import de EX3"

echo "Importando: ADCONNETC"
terraform import \
  'module.vms_contingencia["ADCONNETC"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/ADCONNETC" || echo "WARNING: Falló import de ADCONNETC"

echo "Importando: ADC"
terraform import \
  'module.vms_contingencia["ADC"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/ADC" || echo "WARNING: Falló import de ADC"

echo "Importando: vSOMC"
terraform import \
  'module.vms_contingencia["vSOMC"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/vSOMC" || echo "WARNING: Falló import de vSOMC"

echo "Importando: PSMC"
terraform import \
  'module.vms_contingencia["PSMC"].vsphere_virtual_machine.vm' \
  "/IBM/vm/Discovered virtual machine/PSMC" || echo "WARNING: Falló import de PSMC"

echo "Importando: SG_vSSM_0_19"
terraform import \
  'module.vms_contingencia["SG_vSSM_0_19"].vsphere_virtual_machine.vm' \
  "/IBM/vm/SG/SG_vSSM_0_19" || echo "WARNING: Falló import de SG_vSSM_0_19"

echo "Importación completada. Revisa el estado con: terraform plan"