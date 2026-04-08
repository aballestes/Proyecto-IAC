#!/usr/bin/env python3
"""
vm_inventory.py — Script de Discovery de VMs VMware vSphere
============================================================
Genera automáticamente el archivo terraform.tfvars con el inventario
completo de VMs de un vCenter, listo para ser importado con Terraform.

Prerequisitos:
  pip install pyVmomi pyvmomi-requests tabulate pyyaml

Uso:
  python3 vm_inventory.py \
    --host vcenter-cont.dominio.local \
    --user svc-ansible@vsphere.local \
    --password PASSWORD \
    --datacenter DC-Contingencia \
    --output terraform.tfvars.json

  # Exportar a formato CSV para revisión:
  python3 vm_inventory.py --host vcenter-prod.dominio.local ... --format csv

  # Exportar a formato Terraform HCL para pegar en tfvars:
  python3 vm_inventory.py --host vcenter-prod.dominio.local ... --format hcl
"""

import argparse
import json
import csv
import ssl
import sys
import getpass
import yaml
from datetime import datetime
from typing import Dict, List, Any

try:
    from pyVmomi import vim, vmodl
    from pyVim.connect import SmartConnect, Disconnect
except ImportError:
    print("ERROR: Instalar pyVmomi: pip install pyVmomi")
    sys.exit(1)


# =============================================================================
# Conexión a vCenter
# =============================================================================
def connect_vcenter(host: str, user: str, password: str, port: int = 443) -> Any:
    """Establece conexión SSL con vCenter (acepta certificados autofirmados)."""
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
    context.check_hostname = False
    context.verify_mode = ssl.CERT_NONE

    try:
        si = SmartConnect(
            host=host,
            user=user,
            pwd=password,
            port=port,
            sslContext=context
        )
        print(f"✓ Conectado a vCenter: {host}")
        return si
    except Exception as e:
        print(f"✗ Error conectando a {host}: {e}")
        sys.exit(1)


# =============================================================================
# Recolección de datos de VMs
# =============================================================================
def get_all_vms(si, datacenter_name: str = None) -> List[Dict]:
    """
    Recopila información de todas las VMs en el vCenter.
    Retorna lista de dicts con la configuración de cada VM.
    """
    content = si.RetrieveContent()
    vms_data = []

    # Construir mapa de portgroups una sola vez (eficiente)
    pg_map = build_portgroup_map(si)

    # Obtener todas las VMs via container view (más eficiente que traversal)
    container = content.viewManager.CreateContainerView(
        content.rootFolder,
        [vim.VirtualMachine],
        True
    )

    print(f"✓ Descubriendo VMs en {datacenter_name or 'todos los datacenters'}...")

    for vm in container.view:
        try:
            # Filtrar templates
            if vm.config is None or vm.config.template:
                continue

            # Filtrar por datacenter si se especificó
            if datacenter_name:
                dc = get_vm_datacenter(vm)
                if dc and dc.name != datacenter_name:
                    continue

            vm_info = extract_vm_info(vm, pg_map)
            if vm_info:
                vms_data.append(vm_info)

        except vmodl.fault.ManagedObjectNotFound:
            continue
        except Exception as e:
            print(f"  ⚠ Warning procesando VM: {e}")
            continue

    container.Destroy()
    print(f"✓ VMs descubiertas: {len(vms_data)}")
    return vms_data


def get_vm_datacenter(vm) -> Any:
    """Navega hacia arriba en la jerarquía para encontrar el datacenter."""
    obj = vm
    while obj and not isinstance(obj, vim.Datacenter):
        obj = obj.parent
    return obj


def build_portgroup_map(si) -> Dict[str, str]:
    """
    Construye un mapa {portgroupKey → nombre} consultando todos los
    dvPortgroups del vCenter. Resuelve IDs como 'dvportgroup-9552'
    al nombre real como 'PG-APP-CONT-VLAN100'.
    """
    content = si.RetrieveContent()
    pg_map = {}
    container = content.viewManager.CreateContainerView(
        content.rootFolder,
        [vim.dvs.DistributedVirtualPortgroup],
        True
    )
    for pg in container.view:
        try:
            pg_map[pg.key] = pg.name
        except Exception:
            continue
    container.Destroy()
    # También incluir portgroups de vSS (standard switch) por nombre de red
    container2 = content.viewManager.CreateContainerView(
        content.rootFolder,
        [vim.Network],
        True
    )
    for net in container2.view:
        try:
            if not isinstance(net, vim.dvs.DistributedVirtualPortgroup):
                pg_map[net.name] = net.name
        except Exception:
            continue
    container2.Destroy()
    print(f"✓ Portgroups mapeados: {len(pg_map)}")
    return pg_map


def extract_vm_info(vm, pg_map: Dict[str, str] = None) -> Dict:
    """Extrae configuración relevante de una VM."""
    try:
        config = vm.config
        hardware = config.hardware
        runtime = vm.runtime

        # Obtener IP principal
        ip_address = ""
        if vm.guest and vm.guest.ipAddress:
            ip_address = vm.guest.ipAddress

        # Obtener folder path
        folder_path = get_folder_path(vm)

        # Obtener cluster/host
        cluster_name = ""
        host_name = ""
        if runtime.host:
            host_name = runtime.host.name
            if hasattr(runtime.host, 'parent') and isinstance(runtime.host.parent, vim.ClusterComputeResource):
                cluster_name = runtime.host.parent.name

        # Obtener datastore principal
        datastore_name = ""
        if config.datastoreUrl:
            datastore_name = config.datastoreUrl[0].name if config.datastoreUrl else ""

        # Obtener portgroups de red (resolviendo IDs a nombres reales)
        networks = []
        for nic in hardware.device:
            if isinstance(nic, vim.vm.device.VirtualEthernetCard):
                if hasattr(nic.backing, 'port'):
                    # vDS portgroup — resolver key → nombre
                    pg_key = nic.backing.port.portgroupKey
                    pg_name = (pg_map or {}).get(pg_key, pg_key)
                    networks.append(pg_name)
                elif hasattr(nic.backing, 'deviceName'):
                    networks.append(nic.backing.deviceName)
                elif hasattr(nic.backing, 'network') and nic.backing.network:
                    net_name = getattr(nic.backing.network, 'name', str(nic.backing.network))
                    networks.append(net_name)

        # Obtener discos
        disks = []
        for device in hardware.device:
            if isinstance(device, vim.vm.device.VirtualDisk):
                disk_info = {
                    "label":   device.deviceInfo.label,
                    "size_gb": int(device.capacityInBytes / (1024 ** 3)),
                    "unit":    device.unitNumber,
                    "thin":    device.backing.thinProvisioned if hasattr(device.backing, 'thinProvisioned') else True
                }
                disks.append(disk_info)

        # Estado de VMware Tools
        tools_status = ""
        if vm.guest:
            tools_status = vm.guest.toolsStatus

        return {
            "name":           config.name,
            "guest_id":       config.guestId,
            "guest_full":     config.guestFullName,
            "num_cpus":       hardware.numCPU,
            "num_cores_per_socket": hardware.numCoresPerSocket,
            "memory_mb":      hardware.memoryMB,
            "power_state":    runtime.powerState,
            "ip_address":     ip_address,
            "folder":         folder_path,
            "cluster":        cluster_name,
            "host":           host_name,
            "datastore":      datastore_name,
            "networks":       networks,
            "disks":          disks,
            "tools_status":   tools_status,
            "firmware":       "efi" if hasattr(config.firmware, 'efi') or config.firmware == "efi" else "bios",
            "annotation":     config.annotation or "",
        }
    except Exception as e:
        print(f"  ⚠ Error extrayendo info de VM '{getattr(vm, 'name', 'unknown')}': {e}")
        return None


def get_folder_path(vm) -> str:
    """Construye el path del folder de la VM."""
    parts = []
    obj = vm.parent
    while obj and not isinstance(obj, vim.Datacenter):
        if isinstance(obj, vim.Folder) and obj.name != "vm":
            parts.append(obj.name)
        obj = obj.parent
    parts.reverse()
    return "/".join(parts) if parts else ""


# =============================================================================
# Exportadores
# =============================================================================
def export_json(vms: List[Dict], output_file: str):
    """Exporta a JSON estándar."""
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump({"vms": vms, "generated": datetime.now().isoformat(), "count": len(vms)}, f, indent=2)
    print(f"✓ JSON exportado: {output_file}")


def export_csv(vms: List[Dict], output_file: str):
    """Exporta a CSV para revisión humana."""
    if not vms:
        return
    fields = ["name", "guest_id", "guest_full", "num_cpus", "memory_mb",
              "power_state", "ip_address", "folder", "cluster", "datastore",
              "tools_status", "firmware", "annotation"]
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=fields, extrasaction='ignore')
        w.writeheader()
        w.writerows(vms)
    print(f"✓ CSV exportado: {output_file}")


def export_terraform_hcl(vms: List[Dict], output_file: str, env_var_name: str = "vms_contingencia"):
    """
    Genera bloque HCL para pegar directamente en terraform.tfvars.
    Detecta automáticamente disco de SO (disk0) y discos de datos adicionales.
    """
    lines = [
        f"# Generado automáticamente por vm_inventory.py",
        f"# Fecha: {datetime.now().isoformat()}",
        f"# Total VMs: {len(vms)}",
        f"",
        f"{env_var_name} = {{"
    ]

    for vm in vms:
        # Separar disco de SO y discos de datos
        os_disk_gb = 60
        data_disks = []
        for i, disk in enumerate(vm.get("disks", [])):
            if i == 0:
                os_disk_gb = disk["size_gb"]
            else:
                data_disks.append(disk)

        # Nombre del portgroup (usar el primero, simplificado)
        network_str = ""
        if vm.get("networks"):
            nets = [f'"{n}"' for n in vm["networks"]]
            network_str = f"[{', '.join(nets)}]"

        # Data disks HCL
        data_disk_str = "[]"
        if data_disks:
            disk_lines = []
            for d in data_disks:
                disk_lines.append(
                    f'      {{ size_gb = {d["size_gb"]}, thin_provisioned = {"true" if d.get("thin", True) else "false"} }}'
                )
            data_disk_str = "[\n" + ",\n".join(disk_lines) + "\n    ]"

        lines.extend([
            f'',
            f'  # Power: {vm["power_state"]} | IP: {vm["ip_address"]} | Host: {vm["host"]}',
            f'  # Tools: {vm["tools_status"]} | SO: {vm["guest_full"]}',
            f'  "{vm["name"]}" = {{',
            f'    num_cpus             = {vm["num_cpus"]}',
            f'    num_cores_per_socket = {vm["num_cores_per_socket"]}',
            f'    memory_mb            = {vm["memory_mb"]}',
            f'    guest_id             = "{vm["guest_id"]}"',
            f'    firmware             = "{vm["firmware"]}"',
            f'    os_disk_gb           = {os_disk_gb}',
            f'    thin                 = true',
        ])

        if vm.get("datastore"):
            lines.append(f'    datastore            = "{vm["datastore"]}"')

        if network_str:
            lines.append(f'    networks             = {network_str}')

        if vm.get("folder"):
            lines.append(f'    folder               = "{vm["folder"]}"')

        lines.extend([
            f'    data_disks           = {data_disk_str}',
            f'  }}',
        ])

    lines.append("}")

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("\n".join(lines))

    print(f"✓ HCL Terraform exportado: {output_file}")
    print(f"  → Copiar el contenido de '{env_var_name}' en el terraform.tfvars correspondiente")
    print(f"  → Luego ejecutar: terraform import para cada VM")


def generate_import_script(vms: List[Dict], datacenter: str, env: str, output_file: str):
    """
    Genera script bash con comandos terraform import para todas las VMs.
    Ahorra horas de trabajo manual.
    """
    lines = [
        "#!/bin/bash",
        f"# Script de importación Terraform — {env}",
        f"# Generado: {datetime.now().isoformat()}",
        f"# Total VMs: {len(vms)}",
        f"# ADVERTENCIA: Ejecutar desde el directorio del entorno Terraform",
        f"# Ejemplo: cd terraform/environments/{env}",
        f"",
        f'set -e  # Detener en error',
        f'echo "Iniciando importación de {len(vms)} VMs en {env}..."',
        f""
    ]

    for vm in vms:
        vm_name = vm["name"]
        # Path de la VM en vCenter: /Datacenter/vm/Folder/VMname
        folder = vm.get("folder", "")
        if folder:
            vm_path = f"/{datacenter}/vm/{folder}/{vm_name}"
        else:
            vm_path = f"/{datacenter}/vm/{vm_name}"

        lines.extend([
            f'echo "Importando: {vm_name}"',
            f'terraform import \\',
            f'  \'module.vms_{env}["{vm_name}"].vsphere_virtual_machine.vm\' \\',
            f'  "{vm_path}" || echo "WARNING: Falló import de {vm_name}"',
            f""
        ])

    lines.append('echo "Importación completada. Revisa el estado con: terraform plan"')

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("\n".join(lines))

    import os
    try:
        os.chmod(output_file, 0o755)
    except PermissionError:
        print(f"⚠ No se pudo marcar como ejecutable el script {output_file}. Ejecutar con 'bash {output_file}' o ajustar permisos manualmente si es necesario.")
    print(f"✓ Script de importación generado: {output_file}")


# =============================================================================
# Main
# =============================================================================
def main():
    parser = argparse.ArgumentParser(
        description="Discovery de VMs VMware → Genera inventario Terraform/Ansible"
    )
    parser.add_argument("--host",       required=True, help="FQDN o IP del vCenter")
    parser.add_argument("--user",       required=True, help="Usuario vCenter")
    parser.add_argument("--password",   default=None,  help="Password vCenter (si se omite, se solicita de forma segura)")
    parser.add_argument("--port",       type=int, default=443)
    parser.add_argument("--datacenter", default=None, help="Filtrar por datacenter")
    parser.add_argument("--env",        default="contingencia", help="Nombre del entorno (contingencia/produccion)")
    parser.add_argument("--output",     default="vm-inventory", help="Nombre base para archivos de salida")
    parser.add_argument("--format",     choices=["all", "json", "csv", "hcl"], default="all")
    args = parser.parse_args()

    # Si no se paso password, pedir de forma segura (no queda en historial)
    if not args.password:
        args.password = getpass.getpass(f"Password para {args.user}@{args.host}: ")

    # Conectar
    si = connect_vcenter(args.host, args.user, args.password, args.port)

    try:
        # Descubrir VMs
        vms = get_all_vms(si, args.datacenter)

        if not vms:
            print("No se encontraron VMs. Verificar permisos y filtros.")
            return

        # Estadísticas rápidas
        powered_on  = sum(1 for v in vms if v["power_state"] == "poweredOn")
        powered_off = sum(1 for v in vms if v["power_state"] == "poweredOff")
        tools_ok    = sum(1 for v in vms if v["tools_status"] == "guestToolsRunning")

        print(f"\n{'='*50}")
        print(f"  RESUMEN DE INVENTARIO — {args.datacenter or 'TODOS'}")
        print(f"{'='*50}")
        print(f"  Total VMs:          {len(vms)}")
        print(f"  Encendidas:         {powered_on}")
        print(f"  Apagadas:           {powered_off}")
        print(f"  VMware Tools OK:    {tools_ok}")
        print(f"  Tools con issues:   {len(vms) - tools_ok}")
        print(f"{'='*50}\n")

        # Exportar en formatos solicitados
        if args.format in ("all", "json"):
            export_json(vms, f"{args.output}.json")

        if args.format in ("all", "csv"):
            export_csv(vms, f"{args.output}.csv")

        if args.format in ("all", "hcl"):
            var_name = f"vms_{args.env}"
            export_terraform_hcl(vms, f"{args.output}.tfvars.hcl", var_name)

        # Siempre generar script de importación
        generate_import_script(
            vms,
            args.datacenter or "DC",
            args.env,
            f"import-{args.env}.sh"
        )

        print(f"\n✅ Discovery completado. Archivos generados con prefijo: {args.output}")
        print(f"\nPRÓXIMOS PASOS:")
        print(f"  1. Revisar {args.output}.csv para clasificar VMs")
        print(f"  2. Copiar sección HCL de {args.output}.tfvars.hcl a terraform.tfvars del entorno")
        print(f"  3. Ejecutar: bash import-{args.env}.sh  (en el directorio del entorno Terraform)")
        print(f"  4. Verificar: terraform plan (debe mostrar 0 cambios si los valores son correctos)")

    finally:
        Disconnect(si)


if __name__ == "__main__":
    main()
