###############################################################################
# BACKEND REMOTO — Terraform State
# IMPORTANTE: El state file contiene credenciales y configuración sensible.
# Debe almacenarse de forma segura y con locking habilitado.
#
# Opciones disponibles (descomentar la que aplique):
#   Opción A: MinIO (S3-compatible, on-premise) — RECOMENDADA para airgap
#   Opción B: NFS compartido en la red interna
#   Opción C: GitLab HTTP backend
###############################################################################

# ---- OPCIÓN A: MinIO S3-compatible (on-premise) ----
# Desplegar MinIO en una VM del datacenter contingencia primero.
# Requiere: bucket "terraform-state" creado en MinIO

terraform {
  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "vsphere/contingencia/terraform.tfstate"
    region                      = "us-east-1"      # valor requerido por S3, no importa para MinIO
    endpoint                    = "http://minio.dominio.local:9000"
    access_key                  = "MINIO_ACCESS_KEY"   # usar variable de entorno TF_BACKEND_ACCESS_KEY
    secret_key                  = "MINIO_SECRET_KEY"   # usar variable de entorno TF_BACKEND_SECRET_KEY
    force_path_style            = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
  }
}

# ---- OPCIÓN B: NFS local (alternativa simple) ----
# Montar NFS share en el jump host y usar backend "local" apuntando a esa ruta
# NO provee locking automático; usar terraform.lock manual o single operator mode
#
# terraform {
#   backend "local" {
#     path = "/mnt/nfs-iaac/terraform/contingencia.tfstate"
#   }
# }

# ---- OPCIÓN C: GitLab HTTP backend ----
# terraform {
#   backend "http" {
#     address        = "https://gitlab.dominio.local/api/v4/projects/PROJECT_ID/terraform/state/contingencia"
#     lock_address   = "https://gitlab.dominio.local/api/v4/projects/PROJECT_ID/terraform/state/contingencia/lock"
#     unlock_address = "https://gitlab.dominio.local/api/v4/projects/PROJECT_ID/terraform/state/contingencia/lock"
#     username       = "gitlab-ci-token"
#     password       = "GITLAB_TOKEN"
#     lock_method    = "POST"
#     unlock_method  = "DELETE"
#     retry_wait_min = 5
#   }
# }
