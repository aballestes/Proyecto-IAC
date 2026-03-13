#!/usr/bin/env bash
# Regenera PLAN_TRABAJO.html desde el .md actualizado
BASE='/mnt/c/BACKUP SEPTIEMBRE/GIFHUB/PROYECTO IAAC'

# Verificar si pandoc está disponible
if command -v pandoc &> /dev/null; then
  pandoc "$BASE/PLAN_TRABAJO.md" \
    --from markdown \
    --to html5 \
    --standalone \
    --metadata title="Plan de Trabajo — IaC VMware vSphere" \
    --output "$BASE/PLAN_TRABAJO.html"
  echo "✅ HTML regenerado con pandoc"
else
  echo "⚠️  pandoc no disponible — el HTML no se regenera automáticamente"
  echo "Puedes instalar con: sudo apt install pandoc"
fi
