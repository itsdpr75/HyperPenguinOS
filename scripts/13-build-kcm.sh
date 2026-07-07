#!/bin/bash

# ============================================================
# Fase 10: Compilar KCM Rollback (C++/QML)
# ============================================================

source "$(dirname "$0")/00-env.sh"

log_info "=== Compilando KCM Rollback ==="

KCM_SRC="$PROJECT_ROOT/src/kcm-rollback"

if [ ! -d "$KCM_SRC" ]; then
    log_error "Directorio $KCM_SRC no encontrado"
    exit 1
fi

BUILD_DIR="$KCM_SRC/build"
mkdir -pv "$BUILD_DIR"
cd "$BUILD_DIR"

cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache

make $MAKEFLAGS

if [ $? -eq 0 ]; then
    log_success "KCM Rollback compilado correctamente"
    make install DESTDIR="$LFS_ROOTFS"
    log_info "Instalado en $LFS_ROOTFS"
else
    log_error "Fallo la compilación del KCM"
    exit 1
fi
