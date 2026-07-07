#!/bin/bash

# ============================================================
# Fase 6: Wayland + Mesa + DRM
# Compila el stack gráfico base Wayland nativo
# Sin XWayland (se omite para acelerar la primera versión)
# ============================================================

source "$(dirname "$0")/00-env.sh"

log_info "=== Construyendo stack gráfico: Wayland + Mesa ==="

# Verificar chroot
if [ ! -f "$LFS_ROOTFS/bin/bash" ]; then
    log_error "Sistema base no encontrado. Ejecuta primero 03-base-system.sh"
    exit 1
fi

# Configurar ccache en el chroot
eval "$(ccache_setup)"

chroot "$LFS_ROOTFS" /usr/bin/env -i \
    HOME=/root TERM="$TERM" MAKEFLAGS="$MAKEFLAGS" \
    PATH="/usr/lib/ccache:/usr/bin:/usr/sbin" \
    CCACHE_DIR="$CCACHE_DIR" CCACHE_MAXSIZE="$CCACHE_MAXSIZE" \
    bash -c '

CHECKPOINT_DIR="/usr/lib/opencode/installed"
mkdir -p "$CHECKPOINT_DIR"

meson_build() {
    local name="$1"
    local ext="${2:-tar.xz}"

    if [ -f "$CHECKPOINT_DIR/$name" ]; then
        echo "  Saltando $name (checkpoint)"
        return 0
    fi

    echo "Construyendo: $name"
    tar -xf "/sources/$name.$ext" -C /build
    cd "/build/$name"
    mkdir -p build && cd build

    shift 2
    CC="ccache gcc" CXX="ccache g++" meson setup \
        --prefix=/usr --buildtype=release \
        "$@" ..

    CC="ccache gcc" CXX="ccache g++" ninja
    CC="ccache gcc" CXX="ccache g++" ninja install

    touch "$CHECKPOINT_DIR/$name"
    cd / && rm -rf "/build/$name"
    echo "  [CHECKPOINT] $name"
}

# libdrm
meson_build "libdrm-2.4.120" tar.xz \
    -Dudev=true -Damdgpu=enabled -Dradeon=enabled -Dintel=disabled

# wayland
meson_build "wayland-1.23.0" tar.xz \
    -Ddocumentation=false

# wayland-protocols
meson_build "wayland-protocols-1.36" tar.xz

# libxkbcommon
meson_build "libxkbcommon-1.7.0" tar.xz \
    -Denable-docs=false -Denable-wayland=true

# Mesa (solo gallium radeonsi + swrast, sin X11)
meson_build "mesa-24.2.0" tar.xz \
    -Dgallium-drivers=radeonsi,swrast \
    -Dvulkan-drivers=amd \
    -Dglx=disabled \
    -Degl=enabled \
    -Degl-native-platform=wayland \
    -Dgbm=enabled \
    -Dgles2=enabled \
    -Dllvm=enabled \
    -Dplatforms=wayland \
    -Dvalgrind=disabled \
    -Dtools=[] \
    -Ddri3=enabled

# libinput
meson_build "libinput-1.26.0" tar.xz \
    -Ddocumentation=false -Dlibwacom=false

echo "Stack gráfico Wayland completado (sin XWayland)."
'

log_success "Wayland + Mesa + DRM construidos"
