#!/bin/bash

# ============================================================
# Fase 7c: KDE Plasma 6 + SDDM + Apps esenciales
# Sin Bluetooth, sin NetworkManager (usa systemd-networkd)
# ============================================================

source "$(dirname "$0")/00-env.sh"

log_info "=== Construyendo KDE Plasma 6 ==="
log_warning "Esta fase toma ~2-3 horas"

# Configurar ccache en el chroot
eval "$(ccache_setup)"

PLASMA_MODULES=(
    "plasma-activities-6.1.4"
    "plasma-activities-stats-6.1.4"
    "breeze-6.1.4"
    "breeze-icons-6.1.0"
    "kdecoration-6.1.4"
    "plasma-wayland-protocols-1.14.0"
    "kwayland-6.1.4"
    "layer-shell-qt-6.1.4"
    "libkscreen-6.1.4"
    "libksysguard-6.1.4"
    "libplasma-6.1.4"
    "kpipewire-6.1.4"
    "kwin-6.1.4"
    "plasma-workspace-6.1.4"
    "plasma-desktop-6.1.4"
    "plasma-pa-6.1.4"
    "kscreen-6.1.4"
    "powerdevil-6.1.4"
    "systemsettings-6.1.4"
    "sddm-0.21.0"
    "sddm-kcm-6.1.4"
)

APPS_MODULES=(
    "dolphin-24.08.0"
    "konsole-24.08.0"
    "kate-24.08.0"
)

chroot "$LFS_ROOTFS" /usr/bin/env -i \
    HOME=/root TERM="$TERM" MAKEFLAGS="$MAKEFLAGS" \
    PATH="/usr/lib/ccache:/usr/bin:/usr/sbin" \
    CCACHE_DIR="$CCACHE_DIR" CCACHE_MAXSIZE="$CCACHE_MAXSIZE" \
    bash -c '

CHECKPOINT_DIR="/usr/lib/opencode/installed"
mkdir -p "$CHECKPOINT_DIR"

build_plasma_module() {
    local module="$1"

    if [ -f "$CHECKPOINT_DIR/$module" ]; then
        echo "  Saltando $module (checkpoint)"
        return 0
    fi

    echo "Construyendo: $module"

    # Detectar extensión del source
    local found=0
    for ext in tar.xz tar.gz tar.bz2; do
        if [ -f "/sources/$module.$ext" ]; then
            tar -xf "/sources/$module.$ext" -C /build
            found=1
            break
        fi
    done

    if [ $found -eq 0 ]; then
        echo "  [WARN] Source no encontrado para $module — saltando"
        return 0
    fi

    cd "/build/$module"
    mkdir -p build && cd build

    cmake .. \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER_LAUNCHER=ccache \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        -DBUILD_TESTING=OFF

    make $MAKEFLAGS
    make install

    touch "$CHECKPOINT_DIR/$module"
    cd / && rm -rf "/build/$module"
    echo "  [CHECKPOINT] $module"
}

for module in "${PLASMA_MODULES[@]}"; do
    build_plasma_module "$module"
done

for module in "${APPS_MODULES[@]}"; do
    build_plasma_module "$module"
done

# Configurar SDDM para Wayland
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/wayland.conf << EOF
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Autologin]
Session=plasmawayland
EOF

# Habilitar servicios con SYSTEMD_ROOT para chroot
systemctl enable sddm 2>/dev/null || true
systemctl enable systemd-networkd 2>/dev/null || true

echo "KDE Plasma 6 con Wayland construido."
'

log_success "Plasma 6 completado"
