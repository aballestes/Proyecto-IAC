@echo off
REM ============================================================================
REM wsl-start.bat - Acceso rápido al proyecto IaC en WSL Ubuntu
REM ============================================================================
REM
REM Este script abre WSL Ubuntu directamente en la carpeta del proyecto
REM con las variables de entorno cargadas.
REM
REM Uso: Hacer doble clic o ejecutar desde CMD/PowerShell
REM

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║                                                               ║
echo ║     Proyecto IaC - VMware vSphere                            ║
echo ║     Iniciando WSL Ubuntu...                                  ║
echo ║                                                               ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

REM Verificar si WSL está instalado
wsl --status >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] WSL no está instalado o no está funcionando.
    echo.
    echo Para instalar WSL Ubuntu:
    echo   1. Abrir PowerShell como Administrador
    echo   2. Ejecutar: wsl --install -d Ubuntu
    echo   3. Reiniciar el equipo
    echo.
    pause
    exit /b 1
)

REM Obtener la ruta del proyecto (donde está este batch)
set "PROJECT_DIR=%~dp0"
set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

REM Convertir path de Windows a WSL
REM C:\BACKUP SEPTIEMBRE\GIFHUB\PROYECTO IAAC
REM -> /mnt/c/BACKUP SEPTIEMBRE/GIFHUB/PROYECTO IAAC

echo [INFO] Ruta del proyecto: %PROJECT_DIR%
echo.

REM Ejecutar WSL en la carpeta del proyecto
echo [INFO] Abriendo WSL Ubuntu en el proyecto...
echo.

REM Ejecutar WSL con comando para cargar entorno
wsl bash -c "cd '%PROJECT_DIR%' && echo '[✓] Ubicación actual:' && pwd && echo '' && echo '[INFO] Cargando variables de entorno...' && if [ -f .env ]; then source .env && echo '[✓] Variables de entorno cargadas'; else echo '[!] Archivo .env no encontrado. Ejecuta ./setup-wsl.sh primero'; fi && echo '' && echo '[INFO] Comandos disponibles:' && echo '  • ./setup-wsl.sh           → Instalar dependencias' && echo '  • source .env              → Cargar variables de entorno' && echo '  • cd scripts/discovery     → Ir a carpeta de scripts' && echo '  • ./run-inventory.sh cont  → Ejecutar inventario' && echo '' && exec bash"

echo.
echo [INFO] Sesión WSL finalizada.
pause
