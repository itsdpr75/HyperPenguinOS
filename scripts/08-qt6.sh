#!/bin/bash

# ============================================================
# Fase 7a: Qt6
# Compila los módulos de Qt6 necesarios para KF6 y Plasma
# ============================================================

source "$(dirname "$0")/00-env.sh"

log_info "=== Construyendo Qt6 ==="
log_warning "Esta fase toma varias horas (~6-10)"

# Configurar ccache en el chroot
eval "$(ccache_setup)"

QT6_MODULES=(
    "qtbase-everywhere-src-6.7.2"
    "qtdeclarative-everywhere-src-6.7.2"
    "qtshadertools-everywhere-src-6.7.2"
    "qtquick3d-everywhere-src-6.7.2"
    "qtwayland-everywhere-src-6.7.2"
    "qtsvg-everywhere-src-6.7.2"
    "qtimageformats-everywhere-src-6.7.2"
    "qt5compat-everywhere-src-6.7.2"
    "qtmultimedia-everywhere-src-6.7.2"
    "qttools-everywhere-src-6.7.2"
    "qttranslations-everywhere-src-6.7.2"
    "qtwebsockets-everywhere-src-6.7.2"
    "qthttpserver-everywhere-src-6.7.2"
)

chroot "$LFS_ROOTFS" /usr/bin/env -i \
    HOME=/root TERM="$TERM" MAKEFLAGS="$MAKEFLAGS" \
    PATH="/usr/lib/ccache:/usr/bin:/usr/sbin" \
    CCACHE_DIR="$CCACHE_DIR" CCACHE_MAXSIZE="$CCACHE_MAXSIZE" \
    bash -c '

CHECKPOINT_DIR="/usr/lib/opencode/installed"
mkdir -p "$CHECKPOINT_DIR"

for module in "${QT6_MODULES[@]}"; do
    if [ -f "$CHECKPOINT_DIR/$module" ]; then
        echo "  Saltando $module (checkpoint)"
        continue
    fi

    echo "Construyendo: $module"
    tar -xf /sources/$module.tar.xz -C /build

    cd /build/$module
    mkdir -p build && cd build

    if [[ "$module" == "qtbase"* ]]; then
        cmake .. \
            -DCMAKE_INSTALL_PREFIX=/usr \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_C_COMPILER_LAUNCHER=ccache \
            -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
            -DQT_FEATURE_wayland=ON \
            -DQT_FEATURE_xcb=ON \
            -DQT_FEATURE_sql=ON \
            -DQT_FEATURE_opengl=ON \
            -DQT_FEATURE_vulkan=ON
    else
        cmake .. \
            -DCMAKE_INSTALL_PREFIX=/usr \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_C_COMPILER_LAUNCHER=ccache \
            -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
    fi

    make $MAKEFLAGS
    make install

    touch "$CHECKPOINT_DIR/$module"
    cd / && rm -rf /build/$module
    echo "  [CHECKPOINT] $module"
done

echo "Qt6 construido completamente."
'

log_success "Qt6 completado"
