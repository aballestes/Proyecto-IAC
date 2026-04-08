#!/bin/bash
###############################################################################
# setup-minio.sh — Instalar y arrancar MinIO en WSL Ubuntu (modo dev/local)
# Uso: bash scripts/setup-minio.sh
#
# Resultado:
#   - MinIO corriendo en http://localhost:9000
#   - Consola web en   http://localhost:9001
#   - Bucket "terraform-state" creado automáticamente
#   - Credenciales guardadas en ~/.minio-credentials
###############################################################################

set -e

MINIO_DIR="$HOME/.minio"
DATA_DIR="$HOME/.minio/data"
CREDS_FILE="$HOME/.minio-credentials"
MINIO_BIN="/usr/local/bin/minio"
MC_BIN="/usr/local/bin/mc"

# Credenciales por defecto (cambiar en producción)
MINIO_USER="terraform-admin"
MINIO_PASS="terraform-secret-2026"
BUCKET_NAME="terraform-state"

echo "======================================================"
echo " Setup MinIO — Terraform Backend (on-premise)"
echo "======================================================"

# ── 1. Descargar MinIO binary ──────────────────────────────
if [ ! -f "$MINIO_BIN" ]; then
    echo "[1/5] Descargando MinIO..."
    wget -q --show-progress --no-check-certificate \
        https://dl.min.io/server/minio/release/linux-amd64/minio \
        -O /tmp/minio
    sudo install /tmp/minio "$MINIO_BIN"
    echo "      ✓ MinIO instalado en $MINIO_BIN"
else
    echo "[1/5] MinIO ya instalado — omitiendo descarga"
fi

# ── 2. Descargar mc (MinIO Client) ────────────────────────
if [ ! -f "$MC_BIN" ]; then
    echo "[2/5] Descargando mc (MinIO Client)..."
    wget -q --show-progress --no-check-certificate \
        https://dl.min.io/client/mc/release/linux-amd64/mc \
        -O /tmp/mc
    sudo install /tmp/mc "$MC_BIN"
    echo "      ✓ mc instalado en $MC_BIN"
else
    echo "[2/5] mc ya instalado — omitiendo descarga"
fi

# ── 3. Crear directorios ───────────────────────────────────
echo "[3/5] Preparando directorios..."
mkdir -p "$DATA_DIR"
echo "      ✓ Directorio de datos: $DATA_DIR"

# ── 4. Guardar credenciales ────────────────────────────────
echo "[4/5] Guardando credenciales..."
cat > "$CREDS_FILE" << EOF
# Credenciales MinIO — Terraform Backend
# Cargar con: source ~/.minio-credentials

export MINIO_ROOT_USER="$MINIO_USER"
export MINIO_ROOT_PASSWORD="$MINIO_PASS"

# Variables para Terraform backend S3
export AWS_ACCESS_KEY_ID="$MINIO_USER"
export AWS_SECRET_ACCESS_KEY="$MINIO_PASS"
EOF
chmod 600 "$CREDS_FILE"
echo "      ✓ Credenciales guardadas en $CREDS_FILE"

# ── 5. Arrancar MinIO ─────────────────────────────────────
echo "[5/5] Arrancando MinIO..."
source "$CREDS_FILE"

# Arrancar en background
nohup minio server "$DATA_DIR" \
    --address ":9000" \
    --console-address ":9001" \
    > "$MINIO_DIR/minio.log" 2>&1 &

MINIO_PID=$!
echo "      ✓ MinIO PID: $MINIO_PID"
sleep 3

# ── Crear bucket terraform-state ──────────────────────────
echo ""
echo "Creando bucket '$BUCKET_NAME'..."
mc alias set local http://localhost:9000 "$MINIO_USER" "$MINIO_PASS" --insecure 2>/dev/null
mc mb --ignore-existing local/"$BUCKET_NAME" 2>/dev/null && \
    echo "✓ Bucket '$BUCKET_NAME' creado" || \
    echo "✓ Bucket '$BUCKET_NAME' ya existe"

# Habilitar versionado en el bucket
mc version enable local/"$BUCKET_NAME" 2>/dev/null && \
    echo "✓ Versionado habilitado en bucket" || true

echo ""
echo "======================================================"
echo " MinIO listo"
echo "======================================================"
echo ""
echo "  API S3:     http://localhost:9000"
echo "  Consola:    http://localhost:9001"
echo "  Usuario:    $MINIO_USER"
echo "  Password:   $MINIO_PASS"
echo "  Bucket:     $BUCKET_NAME"
echo "  Log:        $MINIO_DIR/minio.log"
echo ""
echo "Próximo paso — en el directorio terraform/environments/contingencia:"
echo ""
echo "  source ~/.minio-credentials"
echo "  terraform init -migrate-state"
echo ""
echo "Para iniciar MinIO después de reiniciar WSL:"
echo "  source ~/.minio-credentials && minio server ~/.minio/data --address :9000 --console-address :9001 &"
echo "======================================================"
