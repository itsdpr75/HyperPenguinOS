#!/bin/bash

# ============================================================
# Fase 11: Calamares Installer + Módulos personalizados
# Compila yaml-cpp, kpmcore y Calamares con checkpoints
# Boost se copia del host (evita 5-10h de compilación)
# ============================================================

source "$(dirname "$0")/00-env.sh"

log_info "=== Construyendo Calamares ==="

if [ ! -f "$LFS_ROOTFS/bin/bash" ]; then
    log_error "Sistema base no encontrado."
    exit 1
fi

# Configurar ccache en el chroot
eval "$(ccache_setup)"

# Copiar boost del host al chroot (evita compilarlo desde source)
if [ ! -f "$LFS_ROOTFS/usr/include/boost/version.hpp" ]; then
    log_info "Copiando boost $BOOST_VERSION del host al chroot..."
    for dir in include lib lib64 share; do
        if [ -d "/usr/$dir/boost" ]; then
            cp -r "/usr/$dir/boost" "$LFS_ROOTFS/usr/$dir/" 2>/dev/null || true
        fi
    done
    # Librerías boost compartidas
    cp -r /usr/lib/libboost_* "$LFS_ROOTFS/usr/lib/" 2>/dev/null || true
    log_success "Boost copiado al chroot"
fi

chroot "$LFS_ROOTFS" /usr/bin/env -i \
    HOME=/root TERM="$TERM" MAKEFLAGS="$MAKEFLAGS" \
    PATH="/usr/lib/ccache:/usr/bin:/usr/sbin" \
    CCACHE_DIR="$CCACHE_DIR" CCACHE_MAXSIZE="$CCACHE_MAXSIZE" \
    bash -c '

CHECKPOINT_DIR="/usr/lib/opencode/installed"
mkdir -p "$CHECKPOINT_DIR"

cmake_build() {
    local name="$1"
    shift

    if [ -f "$CHECKPOINT_DIR/$name" ]; then
        echo "  Saltando $name (checkpoint)"
        return 0
    fi

    echo "Construyendo: $name"

    # Detectar extensión
    local found=0
    for ext in tar.xz tar.gz tar.bz2; do
        if [ -f "/sources/$name.$ext" ]; then
            tar -xf "/sources/$name.$ext" -C /build
            found=1
            break
        fi
    done

    if [ $found -eq 0 ]; then
        echo "  [ERROR] Source no encontrado para $name"
        return 1
    fi

    cd "/build/$name"
    mkdir -p build && cd build

    cmake .. \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER_LAUNCHER=ccache \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        -DBUILD_TESTING=OFF \
        "$@"

    make $MAKEFLAGS
    make install

    touch "$CHECKPOINT_DIR/$name"
    cd / && rm -rf "/build/$name"
    echo "  [CHECKPOINT] $name"
}

# 1. yaml-cpp (necesario para Calamares)
cmake_build "yaml-cpp-0.8.0" \
    -DYAML_BUILD_SHARED_LIBS=ON \
    -DYAML_CPP_BUILD_TESTS=OFF \
    -DYAML_CPP_BUILD_TOOLS=OFF

# 2. kpmcore (backend de particionado para Calamares)
cmake_build "kpmcore-24.08.0" \
    -DBUILD_APPIMAGE_TESTS=OFF \
    -DCMAKE_DISABLE_FIND_PACKAGE_Qt5WebKit=ON

# 3. Calamares
cmake_build "calamares-3.3.7" \
    -DWITH_PYTHON=OFF \
    -DWITH_PYTHONQT=OFF \
    -DINSTALL_CONFIG=ON \
    -DWITH_QML=ON

# 4. Configurar módulos de Calamares para HyperPenguinOS
mkdir -pv /etc/calamares/modules

cat > /etc/calamares/modules/partition-hyperpenguin.conf << "EOF"
---
name: partition
type: job
interface: python
script: "modules/partition-hyperpenguin/main.py"
config:
    defaultFilesystemType: "btrfs"
    defaultSubvolumes:
        - "@rootfs-A"
        - "@rootfs-B"
        - "@etc"
        - "@var"
        - "@user"
        - "@snapshots"
    efi: true
EOF

cat > /etc/calamares/modules/users-hyperpenguin.conf << "EOF"
---
name: users
type: job
interface: python
script: "modules/users-hyperpenguin/main.py"
config:
    defaultGroups: ["wheel", "users"]
    autologinGroup: "autologin"
    doAutologin: true
    homeDir: "/user"
    homeMode: "0750"
EOF

cat > /etc/calamares/modules/bootloader-hyperpenguin.conf << "EOF"
---
name: bootloader
type: job
interface: python
script: "modules/bootloader-hyperpenguin/main.py"
config:
    efi: true
    efiBootloaderId: "hyperpenguin"
    grubInstallTarget: "x86_64-efi"
    defaultEntry: "HyperPenguinOS"
EOF

# Stubs para módulos Python (implementación real se hace después)
mkdir -pv /etc/calamares/modules/partition-hyperpenguin
cat > /etc/calamares/modules/partition-hyperpenguin/main.py << "PYEOF"
#!/usr/bin/env python3
# Placeholder - implementación real pendiente
def run():
    return None
PYEOF

mkdir -pv /etc/calamares/modules/users-hyperpenguin
cat > /etc/calamares/modules/users-hyperpenguin/main.py << "PYEOF"
#!/usr/bin/env python3
# Placeholder - implementación real pendiente
def run():
    return None
PYEOF

mkdir -pv /etc/calamares/modules/bootloader-hyperpenguin
cat > /etc/calamares/modules/bootloader-hyperpenguin/main.py << "PYEOF"
#!/usr/bin/env python3
# Placeholder - implementación real pendiente
def run():
    return None
PYEOF

# Branding
mkdir -pv /etc/calamares/branding/hyperpenguin
cat > /etc/calamares/branding/hyperpenguin/branding.desc << "DESC"
---
componentName: hyperpenguin
name: HyperPenguinOS
version: "1.0"
shortDescription: HyperPenguinOS Linux
description: Una distribución Linux inmutable centrada en el usuario
bootloaderEntryName: HyperPenguinOS
productUrl: https://hyperpenguin.os
supportUrl: https://hyperpenguin.os/support
knownIssuesUrl: https://hyperpenguin.os/issues
releaseNotesUrl: https://hyperpenguin.os/release-notes
welcomeImage: "welcome.png"
welcomeFontColor: "#ffffff"
welcomeFontSize: 20
stylesheet: "style.qss"
slideshow: "slideshow.qml"
DESC

echo "Calamares instalado y configurado."
'

log_success "Calamares construido"
