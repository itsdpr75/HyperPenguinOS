#!/bin/bash

# ============================================================
# Fase 9: Compilar hbox (Cross-distro container manager)
# ============================================================

source "$(dirname "$0")/00-env.sh"

log_info "=== Compilando hbox ==="

HBOX_SRC="$PROJECT_ROOT/src/hbox"

if [ ! -d "$HBOX_SRC" ]; then
    log_error "Directorio $HBOX_SRC no encontrado"
    exit 1
fi

cd "$HBOX_SRC"

# Verificar Go
if ! command -v go &>/dev/null; then
    log_error "Go no está instalado. Instálalo con: sudo pacman -S go"
    exit 1
fi

# Instalar dependencias Go
log_info "Descargando dependencias..."
go mod tidy
go mod download

# Compilar
log_info "Compilando..."
go build -ldflags="-s -w" -o hbox .

if [ -f hbox ]; then
    log_success "hbox compilado correctamente"
    cp -v hbox "$LFS_ROOTFS/usr/bin/hbox"
    log_info "Binario copiado a $LFS_ROOTFS/usr/bin/hbox"
else
    log_error "Fallo la compilación de hbox"
    exit 1
fi
