#!/bin/bash

# ============================================================
# Fase 8: Compilar hpk (HyperPenguin Kommander)
# ============================================================

source "$(dirname "$0")/00-env.sh"

log_info "=== Compilando hpk (HyperPenguin Kommander) ==="

HPK_SRC="$PROJECT_ROOT/src/hpk"

if [ ! -d "$HPK_SRC" ]; then
    log_error "Directorio $HPK_SRC no encontrado"
    exit 1
fi

cd "$HPK_SRC"

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
go build -ldflags="-s -w" -o hpk .

if [ -f hpk ]; then
    log_success "hpk compilado correctamente"
    cp -v hpk "$LFS_ROOTFS/usr/bin/hpk"
    log_info "Binario copiado a $LFS_ROOTFS/usr/bin/hpk"
else
    log_error "Fallo la compilación de hpk"
    exit 1
fi
