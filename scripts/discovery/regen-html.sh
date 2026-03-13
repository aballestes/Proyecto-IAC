#!/usr/bin/env bash
# Sincroniza PLAN_TRABAJO.html desde PLAN_TRABAJO.md
# Uso: wsl bash "scripts/discovery/regen-html.sh"
SCRIPT='/mnt/c/BACKUP SEPTIEMBRE/GIFHUB/PROYECTO IAAC/scripts/discovery/md-to-html.py'
python3 "$SCRIPT"
