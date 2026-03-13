#!/usr/bin/env python3
"""
md-to-html.py — Sincroniza el markdown embebido en PLAN_TRABAJO.html
desde PLAN_TRABAJO.md. Ejecutar desde la raiz del proyecto.
"""
import sys, os, re

BASE      = '/mnt/c/BACKUP SEPTIEMBRE/GIFHUB/PROYECTO IAAC'
MD_FILE   = os.path.join(BASE, 'PLAN_TRABAJO.md')
HTML_FILE = os.path.join(BASE, 'PLAN_TRABAJO.html')

START_MARKER = "        const markdownContent = `"
END_MARKER   = "`;\n\n        // Configure marked options"

def escape_js_template(text):
    # Preservar backticks ya escapados
    text = text.replace("\\`", "\x01")
    # Escapar backticks nuevos
    text = text.replace("`", "\\`")
    # Restaurar los ya escapados
    text = text.replace("\x01", "\\`")
    # Escapar interpolaciones JS ${...}
    text = re.sub(r'\$\{', r'\\${', text)
    return text

with open(MD_FILE, 'r', encoding='utf-8') as f:
    md = f.read()

with open(HTML_FILE, 'r', encoding='utf-8') as f:
    html = f.read()

start_idx = html.find(START_MARKER)
end_idx   = html.find(END_MARKER)

if start_idx == -1 or end_idx == -1:
    print("ERROR: No se encontraron los marcadores en el HTML.")
    sys.exit(1)

content_start = start_idx + len(START_MARKER)
escaped = escape_js_template(md)
new_html = html[:content_start] + escaped + html[end_idx:]

with open(HTML_FILE, 'w', encoding='utf-8') as f:
    f.write(new_html)

print(f"OK: PLAN_TRABAJO.html actualizado ({len(md):,} chars markdown)")
