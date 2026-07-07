#!/bin/bash

# ============================================================
# Fase 1: Toolchain LFS (Cross-compilación)
# Compila: binutils → gcc-pass1 → glibc → gcc-pass2
# ============================================================

set -euo pipefail

source "$(dirname "$0")/00-env.sh"
source "$(dirname "$0")/utils/build-package.sh"

GCC_PATCHES_DIR="$LFS/sources/patches"

log_info "Iniciando construcción de la toolchain cruzada"

# Verificar que estamos en el entorno correcto
if [ ! -d "$LFS_SOURCES" ]; then
    log_error "Ejecuta primero 01-download-sources.sh"
    exit 1
fi

GCC_VERSION="15.2.0"
GLIBC_VERSION="2.43"

# Crear directorios base
mkdir -pv "$LFS/build"
mkdir -pv "$LFS_ROOTFS"/{etc,var,sbin,lib,usr/{bin,lib,sbin},sbin,tools}
ln -sfv usr/bin "$LFS_ROOTFS/bin"
ln -sfv usr/lib "$LFS_ROOTFS/lib"
ln -sfv usr/sbin "$LFS_ROOTFS/sbin"

# 1.1 binutils-2.46 - Pass 1
log_info "=== 1.1: binutils-2.46 (pass 1) ==="
tar -xf "$LFS_SOURCES/binutils-2.46.0.tar.xz" -C "$LFS/build"
cd "$LFS/build/binutils-2.46.0"
mkdir -v build && cd build
../configure --prefix=$LFS_TOOLS \
             --with-sysroot=$LFS_ROOTFS \
             --target=$LFS_TGT \
             --disable-nls \
             --enable-gprofng=no \
             --disable-werror \
             --enable-default-hash-style=gnu
make $MAKEFLAGS
make install
cd "$LFS" && rm -rf "$LFS/build/binutils-2.46.0"
log_success "binutils pass 1 completado"

# 1.2 gcc-15.2.0 - Pass 1 (sin libgcc)
log_info "=== 1.2: gcc-15.2.0 (pass 1) ==="
tar -xf "$LFS_SOURCES/gcc-15.2.0.tar.xz" -C "$LFS/build"
cd "$LFS/build/gcc-15.2.0"

# Aplicar parches necesarios para gcc
if [ -d "$GCC_PATCHES_DIR" ]; then
    for patch in "$GCC_PATCHES_DIR"/gcc-*.patch; do
        if [ -f "$patch" ]; then
            log_info "  Aplicando parche gcc: $(basename $patch)"
            patch -p1 < "$patch" || log_warning "Fallo parche $(basename $patch)"
        fi
    done
fi

# Fix: libcody usa u8"" literales que en C++20 son char8_t, no char
# GCC 16 del host compila en modo C++20 por defecto
log_info "  Aplicando fix libcody u8 -> char (compatibilidad C++20)..."
find libcody -name '*.cc' -o -name '*.hh' | xargs sed -i 's/u8"/"/g'

# Pass 1 solo necesita C; libcody y c++tools requieren C++ funcional
log_info "  Eliminando libcody y c++tools para pass 1 (solo C)..."
rm -rf libcody c++tools

# Extraer mpfr, gmp, mpc dentro de gcc
tar -xf "$LFS_SOURCES/mpfr-4.2.2.tar.xz"
mv -v mpfr-4.2.2 mpfr
tar -xf "$LFS_SOURCES/gmp-6.3.0.tar.xz"
mv -v gmp-6.3.0 gmp
tar -xf "$LFS_SOURCES/mpc-1.3.1.tar.gz"
mv -v mpc-1.3.1 mpc

mkdir -v build && cd build
../configure --target=$LFS_TGT \
             --prefix=$LFS_TOOLS \
             --with-glibc-version=${GLIBC_VERSION} \
             --with-sysroot=$LFS_ROOTFS \
             --with-newlib \
             --without-headers \
             --enable-default-pie \
             --enable-default-ssp \
             --disable-nls \
             --disable-shared \
             --disable-multilib \
             --disable-threads \
             --disable-libatomic \
             --disable-libgomp \
             --disable-libquadmath \
             --disable-libssp \
             --disable-libvtv \
             --disable-libstdcxx \
             --enable-languages=c
make $MAKEFLAGS
make install
cd "$LFS" && rm -rf "$LFS/build/gcc-15.2.0"
log_success "gcc pass 1 completado"

# 1.3 Linux API Headers
log_info "=== 1.3: Linux API Headers ==="
tar -xf "$LFS_SOURCES/linux-${KERNEL_VERSION}.tar.xz" -C "$LFS/build"
cd "$LFS/build/linux-${KERNEL_VERSION}"
make mrproper
make headers
find usr/include -name '.*' -delete
cp -rv usr/include "$LFS_ROOTFS/usr"
cd "$LFS" && rm -rf "$LFS/build/linux-${KERNEL_VERSION}"
log_success "Linux API Headers instalados"

# 1.4 glibc-2.43
log_info "=== 1.4: glibc-2.43 ==="
tar -xf "$LFS_SOURCES/glibc-2.43.tar.xz" -C "$LFS/build"
cd "$LFS/build/glibc-2.43"
case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $LFS_ROOTFS/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS_ROOTFS/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS_ROOTFS/lib/ld-lsb-x86-64.so.3
    ;;
esac
mkdir -v build && cd build
echo "rootsbindir=/usr/sbin" > configparms

# Parche: eliminar test links-dso-program (requiere -lstdc++ y -lgcc_s que no existen)
# También parcheamos el Makefile para que no intente construirlo
sed -i '/LINKS_DSO_PROGRAM/,/^endif/d' ../support/Makefile

CXX= ../configure --prefix=/usr \
             --host=$LFS_TGT \
             --build=$(../scripts/config.guess) \
             --enable-kernel=4.19 \
             --with-headers=$LFS_ROOTFS/usr/include \
             --disable-nscd \
             libc_cv_slibdir=/usr/lib
make $MAKEFLAGS
make DESTDIR=$LFS_ROOTFS install
sed '/RTLDLIST=/s@/usr@@g' -i $LFS_ROOTFS/usr/bin/ldd
cd "$LFS" && rm -rf "$LFS/build/glibc-2.43"
log_success "glibc completada"

# 1.5 libstdc++ de gcc pass 1 (para gcc pass 2)
log_info "=== 1.5: libstdc++ (paso intermedio) ==="
tar -xf "$LFS_SOURCES/gcc-15.2.0.tar.xz" -C "$LFS/build"
cd "$LFS/build/gcc-15.2.0"
log_info "  Aplicando fix libcody u8 -> char (compatibilidad C++20)..."
find libcody -name '*.cc' -o -name '*.hh' | xargs sed -i 's/u8"/"/g'
tar -xf "$LFS_SOURCES/mpfr-4.2.2.tar.xz"
mv -v mpfr-4.2.2 mpfr
tar -xf "$LFS_SOURCES/gmp-6.3.0.tar.xz"
mv -v gmp-6.3.0 gmp
tar -xf "$LFS_SOURCES/mpc-1.3.1.tar.gz"
mv -v mpc-1.3.1 mpc
mkdir -v build && cd build
# IMPORTANTE: Usar ../libstdc++-v3/configure, NO ../configure
# El configure top-level de gcc intenta construir cc1plus que requiere CXX cross
../libstdc++-v3/configure --host=$LFS_TGT \
                          --build=$(../config.guess) \
                          --prefix=$LFS_TOOLS \
                          --disable-multilib \
                          --disable-nls \
                          --disable-libstdcxx-pch \
                          --with-gxx-include-dir=$LFS_TOOLS/$LFS_TGT/include/c++/15.2.0
make $MAKEFLAGS
make install
cd "$LFS" && rm -rf "$LFS/build/gcc-15.2.0"
log_success "libstdc++ completada"

# 1.6 gcc-15.2.0 - Pass 2 (toolchain completa con shared libs)
log_info "=== 1.6: gcc-15.2.0 (pass 2) ==="
tar -xf "$LFS_SOURCES/gcc-15.2.0.tar.xz" -C "$LFS/build"
cd "$LFS/build/gcc-15.2.0"
log_info "  Aplicando fix libcody u8 -> char (compatibilidad C++20)..."
find libcody -name '*.cc' -o -name '*.hh' | xargs sed -i 's/u8"/"/g'
tar -xf "$LFS_SOURCES/mpfr-4.2.2.tar.xz"
mv -v mpfr-4.2.2 mpfr
tar -xf "$LFS_SOURCES/gmp-6.3.0.tar.xz"
mv -v gmp-6.3.0 gmp
tar -xf "$LFS_SOURCES/mpc-1.3.1.tar.gz"
mv -v mpc-1.3.1 mpc
mkdir -v build && cd build
# Nota: --disable-checking evita self-tests que fallan porque pass 1 no tiene C++
# Usamos COMPILER_PATH y LIBRARY_PATH para que xgcc encuentre liblto_plugin
../configure --prefix=$LFS_TOOLS \
             --target=$LFS_TGT \
             --host=$LFS_TGT \
             --build=$(../config.guess) \
             --with-sysroot=$LFS_ROOTFS \
             --enable-default-pie \
             --enable-default-ssp \
             --disable-nls \
             --disable-multilib \
             --disable-checking \
             --enable-languages=c,c++

# Paso 1: construir solo los compiladores (cc1, cc1plus, xgcc, xg++)
# Saltamos self-test de C++ (pass 1 no reconoce -xc++)
make all-gcc $MAKEFLAGS
touch gcc/s-selftest-c++

# Paso 2: construir libgcc con shared library
COMPILER_PATH=$LFS_TOOLS/libexec/gcc/x86_64-hyperpenguin-linux-gnu/15.2.0 \
LIBRARY_PATH=$LFS_TOOLS/lib/gcc/x86_64-hyperpenguin-linux-gnu/15.2.0:$LFS_ROOTFS/usr/lib \
make all-target-libgcc $MAKEFLAGS

# Paso 3: construir libstdc++ target
COMPILER_PATH=$LFS_TOOLS/libexec/gcc/x86_64-hyperpenguin-linux-gnu/15.2.0 \
LIBRARY_PATH=$LFS_TOOLS/lib/gcc/x86_64-hyperpenguin-linux-gnu/15.2.0:$LFS_TOOLS/lib64:$LFS_ROOTFS/usr/lib \
make all-target-libstdc++-v3 $MAKEFLAGS

# Instalar todo
make install-gcc
ln -sfv g++ "$LFS_TOOLS/bin/$LFS_TGT-g++"
ln -sfv g++ "$LFS_TOOLS/bin/$LFS_TGT-c++"

COMPILER_PATH=$LFS_TOOLS/libexec/gcc/x86_64-hyperpenguin-linux-gnu/15.2.0 \
LIBRARY_PATH=$LFS_TOOLS/lib/gcc/x86_64-hyperpenguin-linux-gnu/15.2.0:$LFS_TOOLS/lib64:$LFS_ROOTFS/usr/lib \
make install-target-libgcc

COMPILER_PATH=$LFS_TOOLS/libexec/gcc/x86_64-hyperpenguin-linux-gnu/15.2.0 \
LIBRARY_PATH=$LFS_TOOLS/lib/gcc/x86_64-hyperpenguin-linux-gnu/15.2.0:$LFS_TOOLS/lib64:$LFS_ROOTFS/usr/lib \
make install-target-libstdc++-v3

cd "$LFS" && rm -rf "$LFS/build/gcc-15.2.0"
log_success "gcc pass 2 completado"

log_success "=== TOOLCHAIN COMPLETADA ==="
echo ""
log_info "Verificación:"
$LFS_TOOLS/bin/$LFS_TGT-gcc --version
echo ""
log_info "Resumen:"
echo "  Toolchain en: $LFS_TOOLS"
echo "  Rootfs base en: $LFS_ROOTFS"
echo "  Target: $LFS_TGT"
