#!/bin/bash

# ============================================================
# Variables de entorno para la construcción de HyperPenguinOS
# Basado en Linux From Scratch
# ============================================================

export HYPERPENGUIN_VERSION="1.0"
export LFS_VERSION="13.0"

# Raíz del proyecto (directorio raíz del repo, independiente de la ruta)
export PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Directorio base de construcción
export LFS="$PROJECT_ROOT/lfs"

# Arquitectura objetivo
export LFS_TGT="x86_64-hyperpenguin-linux-gnu"
export LFS_HOST=$(gcc -dumpmachine)

# Número de cores para compilación paralela
export MAKEFLAGS="-j$(nproc)"

# Directorios dentro de LFS
export LFS_SOURCES="$LFS/sources"
export LFS_TOOLS="$LFS/tools"
export LFS_ROOTFS="$LFS/rootfs"

# Path temporal para la toolchain cruzada
export PATH="$LFS_TOOLS/bin:$PATH"

# Variables de configuración del kernel
export KERNEL_VERSION="6.18.37"
export KERNEL_CONFIG_DIR="$PROJECT_ROOT/kernel/config"
export KERNEL_PATCHES_DIR="$PROJECT_ROOT/kernel/cachyos-patches"

# Particionamiento A/B
export ESP_SIZE="512M"
export ROOT_SIZE="10G"
export VAR_SIZE="4G"
export USER_SIZE="resto"

# URL base para descargas LFS
export LFS_MIRROR="https://www.linuxfromscratch.org/lfs/view/13.0-systemd"

# Checkpoints de paquetes instalados (dentro del chroot)
export CHECKPOINT_DIR="/usr/lib/opencode/installed"

# ccache
export CCACHE_DIR="$PROJECT_ROOT/.ccache"
export CCACHE_MAXSIZE="10G"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funciones auxiliares
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar si un checkpoint existe
checkpoint_done() {
    local name="$1"
    [ -f "$CHECKPOINT_DIR/$name" ]
}

# Marcar un checkpoint como completado
checkpoint_mark() {
    local name="$1"
    mkdir -p "$CHECKPOINT_DIR"
    touch "$CHECKPOINT_DIR/$name"
    echo "  [CHECKPOINT] $name"
}

# Configurar ccache dentro del chroot
# Uso: eval "$(ccache_setup)"
ccache_setup() {
    # Copiar ccache del host al chroot si no existe
    if [ ! -x "$LFS_ROOTFS/usr/bin/ccache" ]; then
        if command -v ccache &>/dev/null; then
            cp "$(command -v ccache)" "$LFS_ROOTFS/usr/bin/ccache"
        else
            log_warning "ccache no disponible en el host — compilaciones sin caché"
            return
        fi
    fi

    # Crear wrappers de compilador que pasan por ccache
    mkdir -p "$LFS_ROOTFS/usr/lib/ccache"
    for compiler in gcc g++ cc c++ c89 c99; do
        ln -sf /usr/bin/ccache "$LFS_ROOTFS/usr/lib/ccache/$compiler" 2>/dev/null || true
    done

    # Configurar directorio de caché persistente (fuera del chroot)
    mkdir -p "$CCACHE_DIR"

    # Retornar exports para usar en el entorno del chroot
    cat <<EOF
export PATH="/usr/lib/ccache:\$PATH"
export CCACHE_DIR="$CCACHE_DIR"
export CCACHE_MAXSIZE="$CCACHE_MAXSIZE"
EOF
}

# Construir un módulo CMake con checkpoint y ccache
cmake_build() {
    local name="$1"
    local src_dir="$2"
    shift 2

    if checkpoint_done "$name"; then
        echo "  Saltando $name (checkpoint)"
        return 0
    fi

    local build_dir="${src_dir}/build"
    mkdir -p "$build_dir"
    cd "$build_dir"

    cmake "$src_dir" \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER_LAUNCHER=ccache \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        -DBUILD_TESTING=OFF \
        "$@"

    make $MAKEFLAGS
    make install
    checkpoint_mark "$name"
}

# Construir un módulo Meson con checkpoint y ccache
meson_build() {
    local name="$1"
    local src_dir="$2"
    shift 2

    if checkpoint_done "$name"; then
        echo "  Saltando $name (checkpoint)"
        return 0
    fi

    local build_dir="${src_dir}/build"
    mkdir -p "$build_dir"
    cd "$build_dir"

    CC="ccache gcc" CXX="ccache g++" meson setup \
        --prefix=/usr \
        --buildtype=release \
        "$src_dir" \
        "$@"

    CC="ccache gcc" CXX="ccache g++" ninja
    CC="ccache gcc" CXX="ccache g++" ninja install
    checkpoint_mark "$name"
}

check_prerequisites() {
    log_info "Verificando requisitos previos..."
    local cmds=("gcc" "make" "bison" "flex" "gawk" "grep" "sed" "texinfo" \
                "xz" "bzip2" "patch" "perl" "python3" "ninja" "meson" \
                "cmake" "pkg-config" "chrpath" "help2man" "xsltproc" \
                "wget" "curl" "git" "rsync" "parted" "losetup" "mkfs.ext4" \
                "go" "podman" "qemu-system-x86_64")

    local missing=0
    for cmd in "${cmds[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            log_error "Falta: $cmd"
            missing=$((missing + 1))
        fi
    done

    if [ $missing -gt 0 ]; then
        log_error "Faltan $missing comandos requeridos. Instálalos primero."
        exit 1
    fi

    log_success "Todos los requisitos están presentes"
}

create_directories() {
    log_info "Creando directorios de construcción..."
    mkdir -pv "$LFS_SOURCES"
    mkdir -pv "$LFS_TOOLS"
    mkdir -pv "$LFS_ROOTFS"
    log_success "Directorios creados"
}
