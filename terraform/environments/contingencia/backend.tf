###############################################################################
# BACKEND REMOTO — MinIO S3-compatible (on-premise)
#
# CREDENCIALES — NO poner en este archivo. Usar variables de entorno:
#   export AWS_ACCESS_KEY_ID="tu_access_key"
#   export AWS_SECRET_ACCESS_KEY="tu_secret_key"
#
# PRIMER USO (migrar state local a MinIO):
#   terraform init -migrate-state
#
# REQUISITO PREVIO: MinIO corriendo y bucket "terraform-state" creado.
#   Ver: scripts/setup-minio.sh
###############################################################################

terraform {
  backend "s3" {
    bucket   = "terraform-state"
    key      = "vsphere/contingencia/terraform.tfstate"
    region   = "us-east-1"   # requerido por S3, MinIO lo ignora

    # URL de MinIO — ajustar según dónde corra:
    #   WSL local:  http://localhost:9000
    #   VM interna: http://192.168.X.X:9000  o  http://minio.gnb.loc:9000
    endpoints = {
      s3 = "http://localhost:9000"
    }

    use_path_style              = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true

    # Versionado del state (requiere que el bucket tenga versioning habilitado en MinIO)
    # versioning = true
  }
}
