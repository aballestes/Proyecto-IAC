#!/usr/bin/env python3
"""
get-portgroups.py — Resuelve IDs de dvPortgroups a nombres reales
==================================================================
Conecta al vCenter y genera un mapa portgroupKey → nombre real.
Útil para reemplazar IDs como 'dvportgroup-9552' por 'PG-APP-CONT-VLAN100'
en el terraform.tfvars.

Uso:
  python3 get-portgroups.py --host <IP_VCENTER> --user <USUARIO>@vsphere.local
"""

import argparse
import ssl
import sys
import getpass
import json

try:
    from pyVmomi import vim
    from pyVim.connect import SmartConnect, Disconnect
except ImportError:
    print("ERROR: pip install pyVmomi")
    sys.exit(1)


def connect_vcenter(host, user, password, port=443):
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
    context.check_hostname = False
    context.verify_mode = ssl.CERT_NONE
    try:
        si = SmartConnect(host=host, user=user, pwd=password, port=port, sslContext=context)
        print(f"✓ Conectado a: {host}")
        return si
    except Exception as e:
        print(f"✗ Error: {e}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host",     required=True)
    parser.add_argument("--user",     required=True)
    parser.add_argument("--password", default=None)
    parser.add_argument("--port",     type=int, default=443)
    args = parser.parse_args()

    if not args.password:
        args.password = getpass.getpass(f"Password para {args.user}@{args.host}: ")

    si = connect_vcenter(args.host, args.user, args.password, args.port)
    content = si.RetrieveContent()

    pg_map = {}

    # Método 1: dvPortgroups (vDS)
    try:
        container = content.viewManager.CreateContainerView(
            content.rootFolder, [vim.dvs.DistributedVirtualPortgroup], True
        )
        dvpg_count = 0
        for pg in container.view:
            try:
                pg_map[pg.key] = pg.name
                dvpg_count += 1
            except Exception as e:
                print(f"  ⚠ dvPG error: {e}")
        container.Destroy()
        print(f"  → dvPortgroups (vDS) encontrados: {dvpg_count}")
    except Exception as e:
        print(f"  ⚠ Error buscando dvPortgroups: {e}")

    # Método 2: Todas las redes (vim.Network incluye vSS y vDS)
    try:
        container2 = content.viewManager.CreateContainerView(
            content.rootFolder, [vim.Network], True
        )
        net_count = 0
        for net in container2.view:
            try:
                key = getattr(net, 'key', net.name)
                pg_map[key]  = net.name
                pg_map[net.name] = net.name  # también por nombre
                net_count += 1
            except Exception as e:
                print(f"  ⚠ Network error: {e}")
        container2.Destroy()
        print(f"  → Redes (vim.Network) encontradas: {net_count}")
    except Exception as e:
        print(f"  ⚠ Error buscando Networks: {e}")

    # Método 3: Buscar vSwitch en cada host directamente
    try:
        host_container = content.viewManager.CreateContainerView(
            content.rootFolder, [vim.HostSystem], True
        )
        host_count = 0
        for host in host_container.view:
            try:
                if host.config and host.config.network:
                    for pg in host.config.network.portgroup:
                        pg_map[pg.spec.name] = pg.spec.name
                    host_count += 1
            except Exception:
                continue
        host_container.Destroy()
        print(f"  → Hosts escaneados (vSS portgroups): {host_count}")
    except Exception as e:
        print(f"  ⚠ Error buscando vSS portgroups: {e}")

    Disconnect(si)

    print(f"\n{'='*60}")
    print(f"  PORTGROUPS ENCONTRADOS: {len(pg_map)}")
    print(f"{'='*60}")
    for key, name in sorted(pg_map.items()):
        print(f"  {key:<35} → {name}")

    # Guardar JSON para uso posterior
    out = "portgroup-map.json"
    with open(out, "w") as f:
        json.dump(pg_map, f, indent=2)
    print(f"\n✓ Mapa guardado en: {out}")
    print(f"\nIDs usados en terraform.tfvars que necesitas mapear:")
    ids_en_tfvars = [
        "dvportgroup-9552", "dvportgroup-29589", "dvportgroup-8556",
        "dvportgroup-9547", "dvportgroup-29593", "dvportgroup-9548",
        "dvportgroup-9546", "dvportgroup-9577", "dvportgroup-9576",
        "dvportgroup-15557", "dvportgroup-29590", "dvportgroup-29591",
        "dvportgroup-9553", "dvportgroup-9545", "dvportgroup-9544",
        "dvportgroup-29589"
    ]
    print(f"  {'ID':<35} → NOMBRE REAL")
    print(f"  {'-'*60}")
    for id_ in sorted(set(ids_en_tfvars)):
        nombre = pg_map.get(id_, "❌ NO ENCONTRADO")
        print(f"  {id_:<35} → {nombre}")


if __name__ == "__main__":
    main()
