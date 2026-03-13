#!/usr/bin/env bash
CSV="/mnt/c/BACKUP SEPTIEMBRE/GIFHUB/PROYECTO IAAC/scripts/discovery/inventario_datacenter_contingencia.csv"
printf "%-30s %-10s %-12s %-8s %s\n" "VM_Name" "OS" "IP" "Estado" "Folder/Datastore"
echo "$(printf '%.0s-' {1..90})"
tail -n +2 "$CSV" | while IFS=';' read -r name guest_id guest_full cpus mem power ip folder cluster datastore rest; do
  name=$(echo "$name" | tr -d '"' | tr -d $'\r' | xargs)
  guest_full=$(echo "$guest_full" | tr -d '"' | tr -d $'\r' | xargs)
  ip=$(echo "$ip" | tr -d '"' | tr -d $'\r' | xargs)
  power=$(echo "$power" | tr -d '"' | tr -d $'\r' | xargs)
  datastore=$(echo "$datastore" | tr -d '"' | tr -d $'\r' | xargs)

  if echo "$guest_full" | grep -qi "windows"; then os="Windows"
  else os="Linux"; fi

  printf "%-30s %-10s %-16s %-12s %s\n" "$name" "$os" "$ip" "$power" "$datastore"
done | sort
