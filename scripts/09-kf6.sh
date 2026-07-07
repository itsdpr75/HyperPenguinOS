#!/bin/bash

# ============================================================
# Fase 7b: KDE Frameworks 6
# Compila los módulos de KF6 (~45) necesarios para Plasma 6
# ============================================================

source "$(dirname "$0")/00-env.sh"

log_info "=== Construyendo KDE Frameworks 6 ==="
log_warning "Esta fase toma ~2-3 horas"

# Configurar ccache en el chroot
eval "$(ccache_setup)"

KF6_MODULES_TIER1=(
    "extra-cmake-modules-6.5.0"
    "kcoreaddons-6.5.0"
    "ki18n-6.5.0"
    "kconfig-6.5.0"
    "kwidgetsaddons-6.5.0"
    "karchive-6.5.0"
    "kcodecs-6.5.0"
    "kcolorscheme-6.5.0"
    "kdbusaddons-6.5.0"
    "kglobalaccel-6.5.0"
    "kguiaddons-6.5.0"
    "kimageformats-6.5.0"
    "kitemmodels-6.5.0"
    "kitemviews-6.5.0"
    "kplotting-6.5.0"
    "kquickcharts-6.5.0"
    "kstatusnotifieritem-6.5.0"
    "kwindowsystem-6.5.0"
    "kxmlgui-6.5.0"
)

KF6_MODULES_TIER2=(
    "kauth-6.5.0"
    "kcompletion-6.5.0"
    "kcrash-6.5.0"
    "kdoctools-6.5.0"
    "kfilemetadata-6.5.0"
    "kio-6.5.0"
    "knewstuff-6.5.0"
    "knotifications-6.5.0"
    "kpackage-6.5.0"
    "kpty-6.5.0"
    "kunitconversion-6.5.0"
    "kparts-6.5.0"
    "ktexteditor-6.5.0"
)

KF6_MODULES_TIER3=(
    "kcmutils-6.5.0"
    "kdeclarative-6.5.0"
    "kded-6.5.0"
    "kdesu-6.5.0"
    "krunner-6.5.0"
    "kwallet-6.5.0"
    "kxmlrpcclient-6.5.0"
    "purpose-6.5.0"
    "kcalendarcore-6.5.0"
    "kcontacts-6.5.0"
    "kholidays-6.5.0"
    "kpeople-6.5.0"
    "ksyntaxhighlighting-6.5.0"
    "kuserfeedback-6.5.0"
)

chroot "$LFS_ROOTFS" /usr/bin/env -i \
    HOME=/root TERM="$TERM" MAKEFLAGS="$MAKEFLAGS" \
    PATH="/usr/lib/ccache:/usr/bin:/usr/sbin" \
    CCACHE_DIR="$CCACHE_DIR" CCACHE_MAXSIZE="$CCACHE_MAXSIZE" \
    bash -c '

CHECKPOINT_DIR="/usr/lib/opencode/installed"
mkdir -p "$CHECKPOINT_DIR"

build_kf6_module() {
    local module="$1"

    if [ -f "$CHECKPOINT_DIR/$module" ]; then
        echo "  Saltando $module (checkpoint)"
        return 0
    fi

    echo "Construyendo: $module"
    tar -xf /sources/$module.tar.xz -C /build

    cd /build/$module
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
    cd / && rm -rf /build/$module
    echo "  [CHECKPOINT] $module"
}

for module in "${KF6_MODULES_TIER1[@]}"; do
    build_kf6_module "$module"
done

for module in "${KF6_MODULES_TIER2[@]}"; do
    build_kf6_module "$module"
done

for module in "${KF6_MODULES_TIER3[@]}"; do
    build_kf6_module "$module"
done

echo "KDE Frameworks 6 construido."
'

log_success "KF6 completado"
