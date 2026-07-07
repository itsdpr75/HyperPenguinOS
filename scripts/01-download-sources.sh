#!/bin/bash

# ============================================================
# Descarga de fuentes para HyperPenguinOS
# Basado en LFS 13.0-systemd wget-list oficial
# ============================================================

source "$(dirname "$0")/00-env.sh"

mkdir -pv "$LFS_SOURCES"
mkdir -pv "$KERNEL_PATCHES_DIR"

# Lista oficial de LFS 13.0-systemd (marzo 2026)
LFS_PACKAGES=(
    "https://download.savannah.gnu.org/releases/acl/acl-2.3.2.tar.xz"
    "https://download.savannah.gnu.org/releases/attr/attr-2.5.2.tar.gz"
    "https://ftpmirror.gnu.org/autoconf/autoconf-2.72.tar.xz"
    "https://ftpmirror.gnu.org/automake/automake-1.18.1.tar.xz"
    "https://ftpmirror.gnu.org/bash/bash-5.3.tar.gz"
    "https://github.com/gavinhoward/bc/releases/download/7.0.3/bc-7.0.3.tar.xz"
    "https://sourceware.org/pub/binutils/releases/binutils-2.46.0.tar.xz"
    "https://ftpmirror.gnu.org/bison/bison-3.8.2.tar.xz"
    "https://www.sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz"
    "https://ftpmirror.gnu.org/coreutils/coreutils-9.10.tar.xz"
    "https://dbus.freedesktop.org/releases/dbus/dbus-1.16.2.tar.xz"
    "https://ftpmirror.gnu.org/dejagnu/dejagnu-1.6.3.tar.gz"
    "https://ftpmirror.gnu.org/diffutils/diffutils-3.12.tar.xz"
    "https://downloads.sourceforge.net/project/e2fsprogs/e2fsprogs/v1.47.3/e2fsprogs-1.47.3.tar.gz"
    "https://sourceware.org/ftp/elfutils/0.194/elfutils-0.194.tar.bz2"
    "https://github.com/libexpat/libexpat/releases/download/R_2_7_4/expat-2.7.4.tar.xz"
    "https://prdownloads.sourceforge.net/expect/expect5.45.4.tar.gz"
    "https://astron.com/pub/file/file-5.46.tar.gz"
    "https://ftpmirror.gnu.org/findutils/findutils-4.10.0.tar.xz"
    "https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz"
    "https://pypi.org/packages/source/f/flit-core/flit_core-3.12.0.tar.gz"
    "https://ftpmirror.gnu.org/gawk/gawk-5.3.2.tar.xz"
    "https://ftpmirror.gnu.org/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz"
    "https://ftpmirror.gnu.org/gdbm/gdbm-1.26.tar.gz"
    "https://ftpmirror.gnu.org/gettext/gettext-1.0.tar.xz"
    "https://ftpmirror.gnu.org/glibc/glibc-2.43.tar.xz"
    "https://ftpmirror.gnu.org/gmp/gmp-6.3.0.tar.xz"
    "https://ftpmirror.gnu.org/gperf/gperf-3.3.tar.gz"
    "https://ftpmirror.gnu.org/grep/grep-3.12.tar.xz"
    "https://ftpmirror.gnu.org/groff/groff-1.23.0.tar.gz"
    "https://ftpmirror.gnu.org/grub/grub-2.14.tar.xz"
    "https://ftpmirror.gnu.org/gzip/gzip-1.14.tar.xz"
    "https://github.com/Mic92/iana-etc/releases/download/20260202/iana-etc-20260202.tar.gz"
    "https://ftpmirror.gnu.org/inetutils/inetutils-2.7.tar.gz"
    "https://launchpad.net/intltool/trunk/0.51.0/+download/intltool-0.51.0.tar.gz"
    "https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-6.18.0.tar.xz"
    "https://pypi.org/packages/source/J/Jinja2/jinja2-3.1.6.tar.gz"
    "https://www.kernel.org/pub/linux/utils/kbd/kbd-2.9.0.tar.xz"
    "https://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-34.2.tar.xz"
    "https://www.greenwoodsoftware.com/less/less-692.tar.gz"
    "https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.77.tar.xz"
    "https://github.com/libffi/libffi/releases/download/v3.5.2/libffi-3.5.2.tar.gz"
    "https://download.savannah.gnu.org/releases/libpipeline/libpipeline-1.5.8.tar.gz"
    "https://ftpmirror.gnu.org/libtool/libtool-2.5.4.tar.xz"
    "https://github.com/besser82/libxcrypt/releases/download/v4.5.2/libxcrypt-4.5.2.tar.xz"
    "https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.18.37.tar.xz"
    "https://github.com/lz4/lz4/releases/download/v1.10.0/lz4-1.10.0.tar.gz"
    "https://ftpmirror.gnu.org/m4/m4-1.4.21.tar.xz"
    "https://ftpmirror.gnu.org/make/make-4.4.1.tar.gz"
    "https://download.savannah.gnu.org/releases/man-db/man-db-2.13.1.tar.xz"
    "https://www.kernel.org/pub/linux/docs/man-pages/man-pages-6.17.tar.xz"
    "https://pypi.org/packages/source/M/MarkupSafe/markupsafe-3.0.3.tar.gz"
    "https://github.com/mesonbuild/meson/releases/download/1.10.1/meson-1.10.1.tar.gz"
    "https://ftpmirror.gnu.org/mpc/mpc-1.3.1.tar.gz"
    "https://ftpmirror.gnu.org/mpfr/mpfr-4.2.2.tar.xz"
    "https://invisible-mirror.net/archives/ncurses/ncurses-6.6.tar.gz"
    "https://github.com/ninja-build/ninja/archive/v1.13.2/ninja-1.13.2.tar.gz"
    "https://github.com/openssl/openssl/releases/download/openssl-3.6.1/openssl-3.6.1.tar.gz"
    "https://files.pythonhosted.org/packages/source/p/packaging/packaging-26.0.tar.gz"
    "https://ftpmirror.gnu.org/patch/patch-2.8.tar.xz"
    "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.47/pcre2-10.47.tar.bz2"
    "https://www.cpan.org/src/5.0/perl-5.42.0.tar.xz"
    "https://distfiles.ariadne.space/pkgconf/pkgconf-2.5.1.tar.xz"
    "https://sourceforge.net/projects/procps-ng/files/Production/procps-ng-4.0.6.tar.xz"
    "https://sourceforge.net/projects/psmisc/files/psmisc/psmisc-23.7.tar.xz"
    "https://www.python.org/ftp/python/3.14.3/Python-3.14.3.tar.xz"
    "https://ftpmirror.gnu.org/readline/readline-8.3.tar.gz"
    "https://ftpmirror.gnu.org/sed/sed-4.9.tar.xz"
    "https://pypi.org/packages/source/s/setuptools/setuptools-82.0.0.tar.gz"
    "https://github.com/shadow-maint/shadow/releases/download/4.19.3/shadow-4.19.3.tar.xz"
    "https://sqlite.org/2026/sqlite-autoconf-3510200.tar.gz"
    "https://github.com/systemd/systemd/archive/v259.1/systemd-259.1.tar.gz"
    "https://anduin.linuxfromscratch.org/LFS/systemd-man-pages-259.1.tar.xz"
    "https://ftpmirror.gnu.org/tar/tar-1.35.tar.xz"
    "https://downloads.sourceforge.net/tcl/tcl8.6.17-src.tar.gz"
    "https://ftpmirror.gnu.org/texinfo/texinfo-7.2.tar.xz"
    "https://www.kernel.org/pub/linux/utils/util-linux/v2.41/util-linux-2.41.3.tar.xz"
    "https://github.com/vim/vim/archive/v9.2.0078/vim-9.2.0078.tar.gz"
    "https://pypi.org/packages/source/w/wheel/wheel-0.46.3.tar.gz"
    "https://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-2.47.tar.gz"
    "https://github.com//tukaani-project/xz/releases/download/v5.8.2/xz-5.8.2.tar.xz"
    "https://zlib.net/fossils/zlib-1.3.2.tar.gz"
    "https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz"
    "https://www.kernel.org/pub/linux/kernel/people/kdave/btrfs-progs/btrfs-progs-v6.19.1.tar.xz"
)

# Parches LFS
LFS_PATCHES=(
    "https://www.linuxfromscratch.org/patches/lfs/13.0/bzip2-1.0.8-install_docs-1.patch"
    "https://www.linuxfromscratch.org/patches/lfs/13.0/coreutils-9.10-i18n-1.patch"
    "https://www.linuxfromscratch.org/patches/lfs/13.0/expect-5.45.4-gcc15-1.patch"
    "https://www.linuxfromscratch.org/patches/lfs/13.0/glibc-fhs-1.patch"
    "https://www.linuxfromscratch.org/patches/lfs/13.0/kbd-2.9.0-backspace-1.patch"
)

log_info "Descargando fuentes LFS 13.0..."

cd "$LFS_SOURCES"

for url in "${LFS_PACKAGES[@]}"; do
    filename=$(basename "$url" | sed 's/?.*//')
    if [ ! -f "$filename" ]; then
        log_info "Descargando: $filename"
        wget --no-verbose --show-progress "$url" 2>&1 || {
            log_warning "Falló descarga de $filename"
        }
    else
        log_info "Ya existe: $filename"
    fi
done

# Descargar parches
log_info "Descargando parches LFS..."
for url in "${LFS_PATCHES[@]}"; do
    filename=$(basename "$url")
    if [ ! -f "$filename" ]; then
        wget --no-verbose --show-progress "$url" 2>&1 || {
            log_warning "Falló descarga de $filename"
        }
    fi
done

# Descargar parches CachyOS
log_info "Descargando parches CachyOS..."
CACHYOS_PATCHES=(
    "https://raw.githubusercontent.com/CachyOS/kernel-patches/master/6.12/all/0001-BORE-v6.9.patch"
    "https://raw.githubusercontent.com/CachyOS/kernel-patches/master/6.12/all/0002-cachyos-base-config.patch"
)

cd "$KERNEL_PATCHES_DIR"
for url in "${CACHYOS_PATCHES[@]}"; do
    filename=$(basename "$url")
    if [ ! -f "$filename" ]; then
        log_info "Descargando: $filename"
        wget --no-verbose --show-progress "$url" 2>&1 || {
            log_warning "Falló descarga de $filename"
        }
    fi
done

# Descargar dracut (el nombre del archivo no coincide con la URL)
if [ ! -f "$LFS_SOURCES/dracut-111.tar.gz" ]; then
    log_info "Descargando: dracut-111.tar.gz"
    wget --no-verbose --show-progress \
      "https://github.com/dracut-ng/dracut/archive/refs/tags/111.tar.gz" \
      -O "$LFS_SOURCES/dracut-111.tar.gz" 2>&1 || {
        log_warning "Falló descarga de dracut-111.tar.gz"
    }
else
    log_info "Ya existe: dracut-111.tar.gz"
fi

# ============================================================
# Paquetes extra del stack gráfico (Wayland + Mesa)
# ============================================================
HYPERPENGUIN_GRAPHICS=(
    "https://dri.freedesktop.org/libdrm/libdrm-2.4.120.tar.xz"
    "https://gitlab.freedesktop.org/wayland/wayland/-/releases/1.23.0/downloads/wayland-1.23.0.tar.xz"
    "https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/1.36/downloads/wayland-protocols-1.36.tar.xz"
    "https://xkbcommon.org/download/libxkbcommon-1.7.0.tar.xz"
    "https://archive.mesa3d.org/mesa-24.2.0.tar.xz"
    "https://gitlab.freedesktop.org/libinput/libinput/-/archive/1.26.0/libinput-1.26.0.tar.xz"
)

log_info "Descargando fuentes del stack gráfico..."
for url in "${HYPERPENGUIN_GRAPHICS[@]}"; do
    filename=$(basename "$url" | sed 's/?.*//')
    if [ ! -f "$filename" ]; then
        log_info "Descargando: $filename"
        wget --no-verbose --show-progress "$url" 2>&1 || log_warning "Falló descarga de $filename"
    else
        log_info "Ya existe: $filename"
    fi
done

# ============================================================
# Qt6 (13 módulos necesarios para KF6/Plasma)
# ============================================================
QT6_BASE_URL="https://download.qt.io/official_releases/qt/6.7/6.7.2/submodules"
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

log_info "Descargando módulos Qt6..."
for module in "${QT6_MODULES[@]}"; do
    if [ ! -f "$LFS_SOURCES/$module.tar.xz" ]; then
        log_info "Descargando: $module.tar.xz"
        wget --no-verbose --show-progress "$QT6_BASE_URL/$module.tar.xz" \
            -O "$LFS_SOURCES/$module.tar.xz" 2>&1 || log_warning "Falló descarga de $module"
    else
        log_info "Ya existe: $module.tar.xz"
    fi
done

# ============================================================
# KDE Frameworks 6 (~45 módulos)
# ============================================================
KF6_BASE_URL="https://download.kde.org/stable/frameworks/6.5"
KF6_MODULES=(
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

log_info "Descargando KDE Frameworks 6..."
for module in "${KF6_MODULES[@]}"; do
    if [ ! -f "$LFS_SOURCES/$module.tar.xz" ]; then
        log_info "Descargando: $module.tar.xz"
        wget --no-verbose --show-progress "$KF6_BASE_URL/$module.tar.xz" \
            -O "$LFS_SOURCES/$module.tar.xz" 2>&1 || log_warning "Falló descarga de $module"
    else
        log_info "Ya existe: $module.tar.xz"
    fi
done

# ============================================================
# KDE Plasma 6 + SDDM + Apps
# ============================================================
PLASMA_BASE_URL="https://download.kde.org/stable/plasma/6.1.4"
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
    "sddm-kcm-6.1.4"
)

log_info "Descargando Plasma 6..."
for module in "${PLASMA_MODULES[@]}"; do
    if [ ! -f "$LFS_SOURCES/$module.tar.xz" ]; then
        log_info "Descargando: $module.tar.xz"
        wget --no-verbose --show-progress "$PLASMA_BASE_URL/$module.tar.xz" \
            -O "$LFS_SOURCES/$module.tar.xz" 2>&1 || log_warning "Falló descarga de $module"
    else
        log_info "Ya existe: $module.tar.xz"
    fi
done

# Plasma apps (dolphin, konsole, kate)
APPS_BASE_URL="https://download.kde.org/stable/release-service/24.08.0/src"
APPS_MODULES=(
    "dolphin-24.08.0"
    "konsole-24.08.0"
    "kate-24.08.0"
)

log_info "Descargando KDE Apps..."
for module in "${APPS_MODULES[@]}"; do
    if [ ! -f "$LFS_SOURCES/$module.tar.xz" ]; then
        log_info "Descargando: $module.tar.xz"
        wget --no-verbose --show-progress "$APPS_BASE_URL/$module.tar.xz" \
            -O "$LFS_SOURCES/$module.tar.xz" 2>&1 || log_warning "Falló descarga de $module"
    else
        log_info "Ya existe: $module.tar.xz"
    fi
done

# SDDM
if [ ! -f "$LFS_SOURCES/sddm-0.21.0.tar.xz" ]; then
    log_info "Descargando: sddm-0.21.0.tar.xz"
    wget --no-verbose --show-progress \
      "https://github.com/sddm/sddm/releases/download/v0.21.0/sddm-0.21.0.tar.xz" \
      -O "$LFS_SOURCES/sddm-0.21.0.tar.xz" 2>&1 || log_warning "Falló descarga de sddm"
fi

# ============================================================
# Calamares + dependencias
# ============================================================
log_info "Descargando Calamares y dependencias..."

if [ ! -f "$LFS_SOURCES/yaml-cpp-0.8.0.tar.xz" ]; then
    log_info "Descargando: yaml-cpp-0.8.0.tar.xz"
    wget --no-verbose --show-progress \
      "https://github.com/jbeder/yaml-cpp/archive/refs/tags/0.8.0.tar.gz" \
      -O "$LFS_SOURCES/yaml-cpp-0.8.0.tar.gz" 2>&1 || log_warning "Falló descarga de yaml-cpp"
fi

if [ ! -f "$LFS_SOURCES/kpmcore-24.08.0.tar.xz" ]; then
    log_info "Descargando: kpmcore-24.08.0.tar.xz"
    wget --no-verbose --show-progress \
      "https://download.kde.org/stable/kpmcore/24.08.0/kpmcore-24.08.0.tar.xz" \
      -O "$LFS_SOURCES/kpmcore-24.08.0.tar.xz" 2>&1 || log_warning "Falló descarga de kpmcore"
fi

if [ ! -f "$LFS_SOURCES/calamares-3.3.7.tar.gz" ]; then
    log_info "Descargando: calamares-3.3.7.tar.gz"
    wget --no-verbose --show-progress \
      "https://github.com/calamares/calamares/releases/download/v3.3.7/calamares-3.3.7.tar.gz" \
      -O "$LFS_SOURCES/calamares-3.3.7.tar.gz" 2>&1 || log_warning "Falló descarga de calamares"
fi

log_success "Descarga completada"
echo ""
log_info "Total archivos en sources: $(ls -1 "$LFS_SOURCES" | wc -l)"
