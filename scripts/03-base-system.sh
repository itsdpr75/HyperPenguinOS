#!/bin/bash

set -euo pipefail

# ============================================================
# 03-base-system.sh — Build LFS Chapter 8 base system
# Phase 1 (host): Cross-compile minimal tools into rootfs
# Phase 2 (chroot): Build all 81 packages natively
# ============================================================

source "$(dirname "$0")/00-env.sh"

log_info "=== Fase 3: Sistema Base LFS (Chapter 8) ==="

# Verificar toolchain
if [ ! -f "$LFS_TOOLS/bin/$LFS_TGT-gcc" ]; then
    log_error "Toolchain no encontrada. Ejecuta primero 02-toolchain.sh"
    exit 1
fi

# ============================================================
# PHASE 1: Cross-compile temporary tools into rootfs
# ============================================================
log_info "Phase 1: Cross-compilando herramientas temporales..."

mkdir -pv "$LFS/build" "$LFS_ROOTFS"/{usr/{bin,lib,sbin},bin,lib,sbin,etc,var,run,tmp}
ln -sfv usr/bin "$LFS_ROOTFS/bin" 2>/dev/null || true
ln -sfv usr/lib "$LFS_ROOTFS/lib" 2>/dev/null || true
ln -sfv usr/sbin "$LFS_ROOTFS/sbin" 2>/dev/null || true

# Copy gcc + binutils from tools into rootfs
log_info "  Instalando gcc + binutils en rootfs..."
for dir in bin lib libexec share include; do
    mkdir -pv "$LFS_ROOTFS/usr/$dir"
    if [ -d "$LFS_TOOLS/$dir" ]; then
        cp -rv "$LFS_TOOLS/$dir"/* "$LFS_ROOTFS/usr/$dir/" 2>/dev/null || true
    fi
done
# Also copy target-specific dir if exists
if [ -d "$LFS_TOOLS/$LFS_TGT" ]; then
    cp -rv "$LFS_TOOLS/$LFS_TGT"/* "$LFS_ROOTFS/usr/" 2>/dev/null || true
fi

# Create cc symlink
ln -sfv gcc "$LFS_ROOTFS/usr/bin/cc" 2>/dev/null || true

# Cross-compile function for Phase 1
cross_build() {
    local pkg="$1" dir="${2:-}" ver="${3:-}"
    local srcdir="$LFS/build/${dir:-$pkg}"
    log_info "  Cross: $pkg"
    rm -rf "$LFS/build/$pkg" "$srcdir"
    tar -xf "$LFS_SOURCES/$pkg.tar"* -C "$LFS/build"
    cd "$srcdir"
}

# 1a. M4-1.4.21 (needed by autotools)
cross_build m4-1.4.21
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make $MAKEFLAGS
make DESTDIR=$LFS_ROOTFS install
cd "$LFS" && rm -rf "$LFS/build/m4-1.4.21"

# 1b. Ncurses-6.6 (needed by bash, less)
cross_build ncurses-6.6
sed -i 's/ mawk//' configure
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess) \
  --with-shared --without-debug --without-normal --with-cxx-shared \
  --enable-pc-files --with-pkg-config-libdir=/usr/lib/pkgconfig
make $MAKEFLAGS
make DESTDIR=$LFS_ROOTFS install
# Fix ncurses symlinks
for lib in ncurses form panel menu; do
    ln -sfv lib${lib}w.so "$LFS_ROOTFS/usr/lib/lib${lib}.so" 2>/dev/null || true
    ln -sfv ${lib}w.pc "$LFS_ROOTFS/usr/lib/pkgconfig/${lib}.pc" 2>/dev/null || true
done
ln -sfv libncursesw.so "$LFS_ROOTFS/usr/lib/libcurses.so" 2>/dev/null || true
cd "$LFS" && rm -rf "$LFS/build/ncurses-6.6"

# 1c. Bash-5.3 (needed for chroot)
cross_build bash-5.3
./configure --prefix=/usr --host=$LFS_TGT --build=$(support/config.guess) \
  --without-bash-malloc
make $MAKEFLAGS
make DESTDIR=$LFS_ROOTFS install
ln -sfv bash "$LFS_ROOTFS/bin/sh"
cd "$LFS" && rm -rf "$LFS/build/bash-5.3"

# 1d. Coreutils-9.10
cross_build coreutils-9.10
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess) \
  --enable-install-program=hostname --enable-no-install-program=kill,uptime
make $MAKEFLAGS
make DESTDIR=$LFS_ROOTFS install
mv -v "$LFS_ROOTFS/usr/bin/chroot" "$LFS_ROOTFS/usr/sbin"
cd "$LFS" && rm -rf "$LFS/build/coreutils-9.10"

# 1e. Diffutils-3.12
cross_build diffutils-3.12
./configure --prefix=/usr --host=$LFS_TGT
make $MAKEFLAGS
make DESTDIR=$LFS_ROOTFS install
cd "$LFS" && rm -rf "$LFS/build/diffutils-3.12"

# 1f. File-5.46
cross_build file-5.46
./configure --prefix=/usr --host=$LFS_TGT
make $MAKEFLAGS
make DESTDIR=$LFS_ROOTFS install
cd "$LFS" && rm -rf "$LFS/build/file-5.46"

# 1g. Findutils-4.10.0
cross_build findutils-4.10.0
./configure --prefix=/usr --host=$LFS_TGT --localstatedir=/var/lib/locate
make $MAKEFLAGS
make DESTDIR=$LFS_ROOTFS install
cd "$LFS" && rm -rf "$LFS/build/findutils-4.10.0"

# 1h. Gawk-5.3.2
cross_build gawk-5.3.2
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
make $MAKEFLAGS
make DESTDIR=$LFS_ROOTFS install
cd "$LFS" && rm -rf "$LFS/build/gawk-5.3.2"

# 1i. Grep-3.12
cross_build grep-3.12
./configure --prefix=/usr --host=$LFS_TGT
make $MAKEFLAGS
make DESTDIR=$LFS_ROOTFS install
cd "$LFS" && rm -rf "$LFS/build/grep-3.12"

# 1j. Gzip-1.14
cross_build gzip-1.14
./configure --prefix=/usr --host=$LFS_TGT
make $MAKEFLAGS
make DESTDIR=$LFS_ROOTFS install
cd "$LFS" && rm -rf "$LFS/build/gzip-1.14"

# 1k. Make-4.4.1
cross_build make-4.4.1
./configure --prefix=/usr --host=$LFS_TGT --without-guile
make $MAKEFLAGS
make DESTDIR=$LFS_ROOTFS install
cd "$LFS" && rm -rf "$LFS/build/make-4.4.1"

# 1l. Patch-2.8
cross_build patch-2.8
./configure --prefix=/usr --host=$LFS_TGT
make $MAKEFLAGS
make DESTDIR=$LFS_ROOTFS install
cd "$LFS" && rm -rf "$LFS/build/patch-2.8"

# 1m. Sed-4.9
cross_build sed-4.9
./configure --prefix=/usr --host=$LFS_TGT
make $MAKEFLAGS
make DESTDIR=$LFS_ROOTFS install
cd "$LFS" && rm -rf "$LFS/build/sed-4.9"

# 1n. Tar-1.35
cross_build tar-1.35
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make $MAKEFLAGS
make DESTDIR=$LFS_ROOTFS install
cd "$LFS" && rm -rf "$LFS/build/tar-1.35"

# 1o. Texinfo-7.2
cross_build texinfo-7.2
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
make $MAKEFLAGS
make DESTDIR=$LFS_ROOTFS install
cd "$LFS" && rm -rf "$LFS/build/texinfo-7.2"

# 1p. Xz-5.8.2
cross_build xz-5.8.2
./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess) --disable-static
make $MAKEFLAGS
make DESTDIR=$LFS_ROOTFS install
cd "$LFS" && rm -rf "$LFS/build/xz-5.8.2"

# 1q. Gdbm-1.26 (needed by less)
cross_build gdbm-1.26
./configure --prefix=/usr --host=$LFS_TGT --disable-static --enable-libgdbm-compat
make $MAKEFLAGS
make DESTDIR=$LFS_ROOTFS install
cd "$LFS" && rm -rf "$LFS/build/gdbm-1.26"

# 1r. Pkgconf-2.5.1
cross_build pkgconf-2.5.1
./configure --prefix=/usr --host=$LFS_TGT --disable-static --docdir=/usr/share/doc/pkgconf-2.5.1
make $MAKEFLAGS
make DESTDIR=$LFS_ROOTFS install
ln -sfv pkgconf "$LFS_ROOTFS/usr/bin/pkg-config" 2>/dev/null || true
cd "$LFS" && rm -rf "$LFS/build/pkgconf-2.5.1"

# Ensure /etc/ld.so.conf exists for glibc sanity
touch "$LFS_ROOTFS/etc/ld.so.conf"
mkdir -pv "$LFS_ROOTFS/etc/ld.so.conf.d"
mkdir -pv "$LFS_ROOTFS/dev" "$LFS_ROOTFS/proc" "$LFS_ROOTFS/sys" "$LFS_ROOTFS/run"
mkdir -pv "$LFS_ROOTFS/root" "$LFS_ROOTFS/tmp" "$LFS_ROOTFS/home"

# Create /etc/passwd and /etc/group for chroot
echo "root:x:0:0:root:/root:/bin/bash" > "$LFS_ROOTFS/etc/passwd"
echo "root:x:0:" > "$LFS_ROOTFS/etc/group"

# Fix lib symlinks for chroot
ln -sfv usr/lib "$LFS_ROOTFS/lib64" 2>/dev/null || true
rm -rf "$LFS_ROOTFS/lib"
ln -sfv usr/lib "$LFS_ROOTFS/lib" 2>/dev/null || true

# Copy missing libraries from tools (for gcc, binutils)
cp -v "$LFS/tools/lib64/libgcc_s.so"* "$LFS_ROOTFS/usr/lib/" 2>/dev/null || true

log_success "Phase 1 completada — herramientas temporales en rootfs"

# ============================================================
# PHASE 2: Chroot build of all LFS Chapter 8 packages
# ============================================================
log_info "Phase 2: Preparando entorno chroot..."

# Mount virtual filesystems
mount -v --bind /dev "$LFS_ROOTFS/dev" 2>/dev/null || true
mount -v --bind /dev/pts "$LFS_ROOTFS/dev/pts" 2>/dev/null || true
mount -vt proc proc "$LFS_ROOTFS/proc" 2>/dev/null || true
mount -vt sysfs sysfs "$LFS_ROOTFS/sys" 2>/dev/null || true
mount -vt tmpfs tmpfs "$LFS_ROOTFS/run" 2>/dev/null || true

if [ -h "$LFS_ROOTFS/dev/shm" ]; then
    mkdir -pv "$LFS_ROOTFS/$(readlink "$LFS_ROOTFS/dev/shm")" 2>/dev/null || true
fi

# Bind mount sources directory
mkdir -pv "$LFS_ROOTFS/sources"
mount --bind "$LFS_SOURCES" "$LFS_ROOTFS/sources" 2>/dev/null || true

# Copy host python3 for glibc gen-as-const.py
cp -v /usr/bin/python3 "$LFS_ROOTFS/usr/bin/" 2>/dev/null || true
cp -rv /usr/lib/python3.14 "$LFS_ROOTFS/usr/lib/" 2>/dev/null || true

# Fix GCC --sysroot path inside chroot
mkdir -pv "$LFS_ROOTFS$PROJECT_ROOT/lfs"
ln -sf / "$LFS_ROOTFS$PROJECT_ROOT/lfs/rootfs" 2>/dev/null || true

# Write the chroot build script
cat > "$LFS_ROOTFS/build-chroot.sh" << 'CHROOT_SCRIPT'
#!/bin/bash
set -euo pipefail

# ============================================================
# Chroot Build Script — LFS Chapter 8 packages
# Runs inside chroot with MAKEFLAGS from host environment
# Sources at /sources, installs to /
# ============================================================

SRC=/sources
LOG=/var/log/build
mkdir -pv "$LOG"

export LC_ALL=C.UTF-8
export PATH=/usr/bin:/usr/sbin
export FORCE_UNSAFE_CONFIGURE=1

MARKER_DIR=/usr/lib/opencode/installed
mkdir -p "$MARKER_DIR"

run_build() {
    local pkg="$1"
    shift
    if [ -f "$MARKER_DIR/$pkg" ]; then
        log_ok "$pkg already built, skipping"
        return 0
    fi
    "$@"
    touch "$MARKER_DIR/$pkg"
    return 0
}

log_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
log_ok()   { echo -e "\033[0;32m[OK]\033[0m $1"; }
log_err()  { echo -e "\033[0;31m[ERR]\033[0m $1"; }

# ---- Helper build functions ----

build_std() {
    local name="$1" ver="$2" dir="$3" logf="$4"
    log_info "Building: $name-$ver"
    cd "$SRC"
    rm -rf "$dir"
    tar xf "$SRC/$name-$ver.tar."* -C "$SRC" 2>/dev/null || \
    tar xf "$SRC/$name-$ver.tgz" -C "$SRC" 2>/dev/null || true
    cd "$SRC/$dir"
    shift 4
    ./configure --prefix=/usr "$@"
    make
    make check 2>&1 | tee "$LOG/$name-check.log" || true
    make install
    cd "$SRC" && rm -rf "$SRC/$dir"
    log_ok "$name-$ver done"
}

build_doc() {
    local name="$1" ver="$2" dir="$3" logf="$4"
    log_info "Building: $name-$ver"
    cd "$SRC"
    rm -rf "$dir"
    tar xf "$SRC/$name-$ver.tar."* -C "$SRC"
    cd "$SRC/$dir"
    shift 4
    ./configure --prefix=/usr --docdir=/usr/share/doc/"$name-$ver" "$@"
    make
    make check 2>&1 | tee "$LOG/$name-check.log" || true
    make install
    cd "$SRC" && rm -rf "$SRC/$dir"
    log_ok "$name-$ver done"
}

build_meson() {
    local name="$1" ver="$2" dir="$3" logf="$4"
    log_info "Building: $name-$ver"
    cd "$SRC"
    rm -rf "$dir"
    tar xf "$SRC/$name-$ver.tar."* -C "$SRC"
    cd "$SRC/$dir"
    shift 4
    mkdir -p build && cd build
    meson setup --prefix=/usr --buildtype=release "$@" ..
    ninja
    ninja test 2>&1 | tee "$LOG/$name-test.log" || true
    DESTDIR= ninja install
    cd "$SRC" && rm -rf "$SRC/$dir"
    log_ok "$name-$ver done"
}

build_pip() {
    local name="$1" ver="$2" dir="$3" pkgname="${4:-$name}"
    log_info "Building: $name-$ver"
    cd "$SRC"
    rm -rf "$dir"
    tar xf "$SRC/$name-$ver.tar."* -C "$SRC"
    cd "$SRC/$dir"
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
    pip3 install --no-index --find-links dist "$pkgname"
    cd "$SRC" && rm -rf "$SRC/$dir"
    log_ok "$name-$ver done"
}

# ============================================================
# PACKAGE BUILDS (in LFS Chapter 8 order)
# ============================================================

# Only build if not in DRY_RUN mode
build_if_needed() {
    "$@"
}

# ---------- 1. man-pages-6.17 ----------
build_man_pages() {
    log_info "Building: man-pages-6.17"
    cd "$SRC"
    rm -rf man-pages-6.17
    tar xf "$SRC/man-pages-6.17.tar.xz" -C "$SRC"
    cd man-pages-6.17
    rm -v man3/crypt* 2>/dev/null || true
    make -R GIT=false prefix=/usr install
    cd "$SRC" && rm -rf man-pages-6.17
    log_ok "man-pages-6.17 done"
}

# ---------- 2. iana-etc-20260202 ----------
build_iana_etc() {
    log_info "Building: iana-etc-20260202"
    cd "$SRC"
    rm -rf iana-etc-20260202
    tar xf "$SRC/iana-etc-20260202.tar.gz" -C "$SRC"
    cd iana-etc-20260202
    cp -v services protocols /etc
    cd "$SRC" && rm -rf iana-etc-20260202
    log_ok "iana-etc-20260202 done"
}

# ---------- 3. glibc-2.43 ----------
build_glibc() {
    log_info "Building: glibc-2.43"
    cd "$SRC"
    rm -rf glibc-2.43
    tar xf "$SRC/glibc-2.43.tar.xz" -C "$SRC"
    cd glibc-2.43
    patch -Np1 -i ../glibc-fhs-1.patch
    mkdir -v build && cd build
    echo "rootsbindir=/usr/sbin" > configparms
    ../configure --prefix=/usr --disable-werror --disable-nscd \
      libc_cv_slibdir=/usr/lib --enable-stack-protector=strong \
      --enable-kernel=5.4
    make $MAKEFLAGS
    make check 2>&1 | tee "$LOG/glibc-check.log" || true
    touch /etc/ld.so.conf
    sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
    make install
    sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd
    # Locales
    mkdir -pv /usr/lib/locale
    localedef -i C -f UTF-8 C.UTF-8 || true
    localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8 || true
    localedef -i de_DE -f ISO-8859-1 de_DE || true
    localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro || true
    localedef -i de_DE -f UTF-8 de_DE.UTF-8 || true
    localedef -i el_GR -f ISO-8859-7 el_GR || true
    localedef -i en_GB -f ISO-8859-1 en_GB || true
    localedef -i en_GB -f UTF-8 en_GB.UTF-8 || true
    localedef -i en_HK -f ISO-8859-1 en_HK || true
    localedef -i en_PH -f ISO-8859-1 en_PH || true
    localedef -i en_US -f ISO-8859-1 en_US || true
    localedef -i en_US -f UTF-8 en_US.UTF-8 || true
    localedef -i es_ES -f ISO-8859-15 es_ES@euro || true
    localedef -i es_MX -f ISO-8859-1 es_MX || true
    localedef -i fa_IR -f UTF-8 fa_IR || true
    localedef -i fr_FR -f ISO-8859-1 fr_FR || true
    localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro || true
    localedef -i fr_FR -f UTF-8 fr_FR.UTF-8 || true
    localedef -i is_IS -f ISO-8859-1 is_IS || true
    localedef -i is_IS -f UTF-8 is_IS.UTF-8 || true
    localedef -i it_IT -f ISO-8859-1 it_IT || true
    localedef -i it_IT -f ISO-8859-15 it_IT@euro || true
    localedef -i it_IT -f UTF-8 it_IT.UTF-8 || true
    localedef -i ja_JP -f EUC-JP ja_JP || true
    localedef -i ja_JP -f UTF-8 ja_JP.UTF-8 || true
    localedef -i nl_NL@euro -f ISO-8859-15 nl_NL@euro || true
    localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R || true
    localedef -i ru_RU -f UTF-8 ru_RU.UTF-8 || true
    localedef -i se_NO -f UTF-8 se_NO.UTF-8 || true
    localedef -i ta_IN -f UTF-8 ta_IN.UTF-8 || true
    localedef -i tr_TR -f UTF-8 tr_TR.UTF-8 || true
    localedef -i zh_CN -f GB18030 zh_CN.GB18030 || true
    localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS || true
    localedef -i zh_TW -f UTF-8 zh_TW.UTF-8 || true
    # nsswitch.conf
    cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf
passwd: files systemd
group: files systemd
shadow: files systemd
hosts: mymachines resolve [!UNAVAIL=return] files myhostname dns
networks: files
protocols: files
services: files
ethers: files
rpc: files
# End /etc/nsswitch.conf
EOF
    # Timezone data
    tar -xf ../../tzdata2025c.tar.gz 2>/dev/null || true
    if [ -f tzdata2025c.tar.gz ]; then
        tar -xf tzdata2025c.tar.gz
        ZONEINFO=/usr/share/zoneinfo
        mkdir -pv $ZONEINFO/{posix,right}
        for tz in etcetera southamerica northamerica europe africa antarctica \
                  asia australasia backward; do
            zic -L /dev/null -d $ZONEINFO ${tz}
            zic -L /dev/null -d $ZONEINFO/posix ${tz}
            zic -L leapseconds -d $ZONEINFO/right ${tz}
        done
        cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
        zic -d $ZONEINFO -p America/New_York
    fi
    # ld.so.conf
    cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib
EOF
    cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf
EOF
    mkdir -pv /etc/ld.so.conf.d
    cd "$SRC" && rm -rf glibc-2.43
    log_ok "glibc-2.43 done"
}

# ---------- 4. zlib-1.3.2 ----------
build_zlib() {
    build_std zlib 1.3.2 zlib-1.3.2 zlib
    rm -fv /usr/lib/libz.a
}

# ---------- 5. bzip2-1.0.8 ----------
build_bzip2() {
    log_info "Building: bzip2-1.0.8"
    cd "$SRC"
    rm -rf bzip2-1.0.8
    tar xf "$SRC/bzip2-1.0.8.tar.gz" -C "$SRC"
    cd bzip2-1.0.8
    patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
    sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
    sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
    make -f Makefile-libbz2_so
    make clean
    make
    make PREFIX=/usr install
    cp -av libbz2.so.* /usr/lib
    ln -sfv libbz2.so.1.0.8 /usr/lib/libbz2.so
    ln -sfv libbz2.so.1.0.8 /usr/lib/libbz2.so.1
    cp -v bzip2-shared /usr/bin/bzip2
    for i in /usr/bin/{bzcat,bunzip2}; do ln -sfv bzip2 $i; done
    rm -fv /usr/lib/libbz2.a
    cd "$SRC" && rm -rf bzip2-1.0.8
    log_ok "bzip2-1.0.8 done"
}

# ---------- 6. xz-5.8.2 ----------
build_xz() {
    build_doc xz 5.8.2 xz-5.8.2 xz --disable-static
}

# ---------- 7. lz4-1.10.0 ----------
build_lz4() {
    log_info "Building: lz4-1.10.0"
    cd "$SRC"
    rm -rf lz4-1.10.0
    tar xf "$SRC/lz4-1.10.0.tar.gz" -C "$SRC"
    cd lz4-1.10.0
    make BUILD_STATIC=no PREFIX=/usr $MAKEFLAGS
    make -j1 check 2>&1 | tee "$LOG/lz4-check.log" || true
    make BUILD_STATIC=no PREFIX=/usr install
    cd "$SRC" && rm -rf lz4-1.10.0
    log_ok "lz4-1.10.0 done"
}

# ---------- 8. zstd-1.5.7 ----------
build_zstd() {
    log_info "Building: zstd-1.5.7"
    cd "$SRC"
    rm -rf zstd-1.5.7
    tar xf "$SRC/zstd-1.5.7.tar.gz" -C "$SRC"
    cd zstd-1.5.7
    make prefix=/usr $MAKEFLAGS
    make check 2>&1 | tee "$LOG/zstd-check.log" || true
    make prefix=/usr install
    rm -v /usr/lib/libzstd.a
    cd "$SRC" && rm -rf zstd-1.5.7
    log_ok "zstd-1.5.7 done"
}

# ---------- 9. file-5.46 ----------
build_file() {
    build_std file 5.46 file-5.46 file
}

# ---------- 10. readline-8.3 ----------
build_readline() {
    log_info "Building: readline-8.3"
    cd "$SRC"
    rm -rf readline-8.3
    tar xf "$SRC/readline-8.3.tar.gz" -C "$SRC"
    cd readline-8.3
    sed -i '/MV.*old/d' Makefile.in
    sed -i '/{OLDSUFF}/c:' support/shlib-install
    sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf
    sed -e '270a\     else\       chars_avail = 1;' \
        -e '288i\   result = -1;' -i.orig input.c
    ./configure --prefix=/usr --disable-static --with-curses \
      --docdir=/usr/share/doc/readline-8.3
    make SHLIB_LIBS="-lncursesw" $MAKEFLAGS
    make install
    install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.3 2>/dev/null || true
    cd "$SRC" && rm -rf readline-8.3
    log_ok "readline-8.3 done"
}

# ---------- 11. pcre2-10.47 ----------
build_pcre2() {
    build_doc pcre2 10.47 pcre2-10.47 pcre2 \
      --enable-unicode --enable-jit --enable-pcre2-16 --enable-pcre2-32 \
      --enable-pcre2grep-libz --enable-pcre2grep-libbz2 \
      --enable-pcre2test-libreadline --disable-static
}

# ---------- 12. m4-1.4.21 ----------
build_m4() {
    build_std m4 1.4.21 m4-1.4.21 m4
}

# ---------- 13. bc-7.0.3 ----------
build_bc() {
    log_info "Building: bc-7.0.3"
    cd "$SRC"
    rm -rf bc-7.0.3
    tar xf "$SRC/bc-7.0.3.tar.xz" -C "$SRC"
    cd bc-7.0.3
    CC='gcc -std=c99' ./configure --prefix=/usr -G -O3 -r
    make $MAKEFLAGS
    make test 2>&1 | tee "$LOG/bc-test.log" || true
    make install
    cd "$SRC" && rm -rf bc-7.0.3
    log_ok "bc-7.0.3 done"
}

# ---------- 14. flex-2.6.4 ----------
build_flex() {
    build_doc flex 2.6.4 flex-2.6.4 flex --disable-static
    ln -sv flex /usr/bin/lex 2>/dev/null || true
    ln -sv flex.1 /usr/share/man/man1/lex.1 2>/dev/null || true
}

# ---------- 15. tcl-8.6.17 ----------
build_tcl() {
    log_info "Building: tcl-8.6.17"
    cd "$SRC"
    rm -rf tcl8.6.17
    tar xf "$SRC/tcl8.6.17-src.tar.gz" -C "$SRC"
    cd tcl8.6.17
    SRCDIR=$(pwd)
    cd unix
    ./configure --prefix=/usr --mandir=/usr/share/man --disable-rpath
    make $MAKEFLAGS
    sed -e "s|$SRCDIR/unix|/usr/lib|" -e "s|$SRCDIR|/usr/include|" -i tclConfig.sh
    sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.12|/usr/lib/tdbc1.1.12|" \
        -e "s|$SRCDIR/pkgs/tdbc1.1.12/generic|/usr/include|" \
        -e "s|$SRCDIR/pkgs/tdbc1.1.12/library|/usr/lib/tcl8.6|" \
        -e "s|$SRCDIR/pkgs/tdbc1.1.12|/usr/include|" -i pkgs/tdbc1.1.12/tdbcConfig.sh
    sed -e "s|$SRCDIR/unix/pkgs/itcl4.3.4|/usr/lib/itcl4.3.4|" \
        -e "s|$SRCDIR/pkgs/itcl4.3.4/generic|/usr/include|" \
        -e "s|$SRCDIR/pkgs/itcl4.3.4|/usr/include|" -i pkgs/itcl4.3.4/itclConfig.sh
    timeout 300 make test 2>&1 | tee "$LOG/tcl-test.log" || true
    make install
    chmod 644 /usr/lib/libtclstub8.6.a
    chmod -v u+w /usr/lib/libtcl8.6.so
    make install-private-headers
    ln -sfv tclsh8.6 /usr/bin/tclsh
    cd "$SRC" && rm -rf tcl8.6.17
    log_ok "tcl-8.6.17 done"
}

# ---------- 16. expect-5.45.4 ----------
build_expect() {
    log_info "Building: expect-5.45.4"
    cd "$SRC"
    rm -rf expect5.45.4
    tar xf "$SRC/expect5.45.4.tar.gz" -C "$SRC"
    cd expect5.45.4
    patch -Np1 -i ../expect-5.45.4-gcc15-1.patch
    ./configure --prefix=/usr --with-tcl=/usr/lib --enable-shared \
      --disable-rpath --mandir=/usr/share/man --with-tclinclude=/usr/include
    make $MAKEFLAGS
    make test 2>&1 | tee "$LOG/expect-test.log" || true
    make install
    ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib
    cd "$SRC" && rm -rf expect5.45.4
    log_ok "expect-5.45.4 done"
}

# ---------- 17. dejagnu-1.6.3 ----------
build_dejagnu() {
    log_info "Building: dejagnu-1.6.3"
    cd "$SRC"
    rm -rf dejagnu-1.6.3
    tar xf "$SRC/dejagnu-1.6.3.tar.gz" -C "$SRC"
    cd dejagnu-1.6.3
    mkdir -v build && cd build
    ../configure --prefix=/usr
    makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi 2>/dev/null || true
    makeinfo --plaintext -o doc/dejagnu.txt ../doc/dejagnu.texi 2>/dev/null || true
    make check 2>&1 | tee "$LOG/dejagnu-check.log" || true
    make install
    install -v -dm755 /usr/share/doc/dejagnu-1.6.3
    install -v -m644 doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3 2>/dev/null || true
    cd "$SRC" && rm -rf dejagnu-1.6.3
    log_ok "dejagnu-1.6.3 done"
}

# ---------- 18. pkgconf-2.5.1 ----------
build_pkgconf() {
    log_info "Building: pkgconf-2.5.1"
    cd "$SRC"
    rm -rf pkgconf-2.5.1
    tar xf "$SRC/pkgconf-2.5.1.tar.xz" -C "$SRC"
    cd pkgconf-2.5.1
    ./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/pkgconf-2.5.1
    make $MAKEFLAGS
    make install
    ln -sv pkgconf /usr/bin/pkg-config 2>/dev/null || true
    ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1 2>/dev/null || true
    cd "$SRC" && rm -rf pkgconf-2.5.1
    log_ok "pkgconf-2.5.1 done"
}

# ---------- 19. binutils-2.46.0 ----------
build_binutils() {
    log_info "Building: binutils-2.46.0"
    cd "$SRC"
    rm -rf binutils-2.46.0
    tar xf "$SRC/binutils-2.46.0.tar.xz" -C "$SRC"
    cd binutils-2.46.0
    mkdir -v build && cd build
    ../configure --prefix=/usr --sysconfdir=/etc --enable-ld=default \
      --enable-plugins --enable-shared --disable-werror --enable-64-bit-bfd \
      --enable-new-dtags --with-system-zlib --enable-default-hash-style=gnu \
      --disable-gprofng
    make tooldir=/usr $MAKEFLAGS
    make -k check 2>&1 | tee "$LOG/binutils-check.log" || true
    make tooldir=/usr install
    rm -rfv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a 2>/dev/null || true
    rm -rfv /usr/share/doc/gprofng/ 2>/dev/null || true
    cd "$SRC" && rm -rf binutils-2.46.0
    log_ok "binutils-2.46.0 done"
}

# ---------- 20. gmp-6.3.0 ----------
build_gmp() {
    log_info "Building: gmp-6.3.0"
    cd "$SRC"
    rm -rf gmp-6.3.0
    tar xf "$SRC/gmp-6.3.0.tar.xz" -C "$SRC"
    cd gmp-6.3.0
    sed -i '/long long t1;/,+1s/()/(...)/' configure
    ./configure --prefix=/usr --disable-cxx --disable-static --docdir=/usr/share/doc/gmp-6.3.0
    make $MAKEFLAGS
    make check 2>&1 | tee gmp-check-log
    make install
    make html 2>/dev/null || true
    make install-html 2>/dev/null || true
    cd "$SRC" && rm -rf gmp-6.3.0
    log_ok "gmp-6.3.0 done"
}

# ---------- 21. mpfr-4.2.2 ----------
build_mpfr() {
    build_doc mpfr 4.2.2 mpfr-4.2.2 mpfr --disable-static --enable-thread-safe
    make html && make install-html 2>/dev/null || true
}

# ---------- 22. mpc-1.3.1 ----------
build_mpc() {
    build_doc mpc 1.3.1 mpc-1.3.1 mpc --disable-static
    make html && make install-html 2>/dev/null || true
}

# ---------- 23. attr-2.5.2 ----------
build_attr() {
    build_doc attr 2.5.2 attr-2.5.2 attr --disable-static --sysconfdir=/etc
}

# ---------- 24. acl-2.3.2 ----------
build_acl() {
    build_doc acl 2.3.2 acl-2.3.2 acl --disable-static
}

# ---------- 25. libcap-2.77 ----------
build_libcap() {
    log_info "Building: libcap-2.77"
    cd "$SRC"
    rm -rf libcap-2.77
    tar xf "$SRC/libcap-2.77.tar.xz" -C "$SRC"
    cd libcap-2.77
    sed -i '/install -m.*STA/d' libcap/Makefile
    make prefix=/usr lib=lib $MAKEFLAGS
    make test 2>&1 | tee "$LOG/libcap-test.log" || true
    make prefix=/usr lib=lib install
    cd "$SRC" && rm -rf libcap-2.77
    log_ok "libcap-2.77 done"
}

# ---------- 26. libxcrypt-4.5.2 ----------
build_libxcrypt() {
    log_info "Building: libxcrypt-4.5.2"
    cd "$SRC"
    rm -rf libxcrypt-4.5.2
    tar xf "$SRC/libxcrypt-4.5.2.tar.xz" -C "$SRC"
    cd libxcrypt-4.5.2
    sed -i '/strchr/s/const//' lib/crypt-{sm3,gost}-yescrypt.c
    ./configure --prefix=/usr --enable-hashes=strong,glibc \
      --enable-obsolete-api=no --disable-static --disable-failure-tokens
    make $MAKEFLAGS
    make check 2>&1 | tee "$LOG/libxcrypt-check.log" || true
    make install
    cd "$SRC" && rm -rf libxcrypt-4.5.2
    log_ok "libxcrypt-4.5.2 done"
}

# ---------- 27. shadow-4.19.3 ----------
build_shadow() {
    log_info "Building: shadow-4.19.3"
    cd "$SRC"
    rm -rf shadow-4.19.3
    tar xf "$SRC/shadow-4.19.3.tar.xz" -C "$SRC"
    cd shadow-4.19.3
    sed -i 's/groups$(EXEEXT) //' src/Makefile.in
    find man -name Makefile.in -exec sed -i 's/groups\.1 / /' {} \;
    find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
    find man -name Makefile.in -exec sed -i 's/passwd\.5 / /' {} \;
    sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
        -e 's:/var/spool/mail:/var/mail:' \
        -e '/PATH=/{s@/sbin:@@;s@/bin:@@}' -i etc/login.defs
    touch /usr/bin/passwd
    ./configure --sysconfdir=/etc --disable-static --with-{b,yes}crypt \
      --without-libbsd --disable-logind --with-group-name-max-length=32
    make $MAKEFLAGS
    make exec_prefix=/usr install
    make -C man install-man
    pwconv
    grpconv
    mkdir -p /etc/default
    useradd -D --gid 999 2>/dev/null || true
    cd "$SRC" && rm -rf shadow-4.19.3
    log_ok "shadow-4.19.3 done"
}

# ---------- 28. gcc-15.2.0 ----------
build_gcc() {
    log_info "Building: gcc-15.2.0"
    cd "$SRC"
    rm -rf gcc-15.2.0
    tar xf "$SRC/gcc-15.2.0.tar.xz" -C "$SRC"
    # Extract deps
    cd gcc-15.2.0
    tar -xf "$SRC/mpfr-4.2.2.tar.xz" && mv mpfr-4.2.2 mpfr
    tar -xf "$SRC/gmp-6.3.0.tar.xz" && mv gmp-6.3.0 gmp
    tar -xf "$SRC/mpc-1.3.1.tar.gz" && mv mpc-1.3.1 mpc
    case $(uname -m) in x86_64) sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 ;; esac
    sed -i 's/char \*q = strchr/const char *q = strchr/' libgomp/affinity-fmt.c
    mkdir -v build && cd build
    ../configure --prefix=/usr LD=ld --enable-languages=c,c++ \
      --enable-default-pie --enable-default-ssp --enable-host-pie \
      --disable-multilib --disable-bootstrap --disable-fixincludes --with-system-zlib
    make $MAKEFLAGS
    ulimit -s -H unlimited
    sed -e '/cpython/d' -i ../gcc/testsuite/gcc.dg/plugin/plugin.exp
    chown -R tester . 2>/dev/null || true
    su tester -c "PATH=$PATH make -k check" 2>&1 | tee "$LOG/gcc-check.log" || true
    make install
    chown -v -R root:root /usr/lib/gcc/"$(gcc -dumpmachine)"/15.2.0/include{,-fixed} 2>/dev/null || true
    ln -svr /usr/bin/cpp /usr/lib 2>/dev/null || true
    ln -sv gcc.1 /usr/share/man/man1/cc.1 2>/dev/null || true
    ln -sfv ../../libexec/gcc/"$(gcc -dumpmachine)"/15.2.0/liblto_plugin.so /usr/lib/bfd-plugins/ 2>/dev/null || true
    # Sanity check
    echo 'int main(){}' | cc -x c - -v -Wl,--verbose &> dummy.log 2>/dev/null || true
    readelf -l a.out 2>/dev/null | grep ': /lib' || true
    rm -f a.out dummy.log
    mkdir -pv /usr/share/gdb/auto-load/usr/lib
    mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib/ 2>/dev/null || true
    cd "$SRC" && rm -rf gcc-15.2.0
    log_ok "gcc-15.2.0 done"
}

# ---------- 29. ncurses-6.6 ----------
build_ncurses() {
    log_info "Building: ncurses-6.6"
    cd "$SRC"
    rm -rf ncurses-6.6
    tar xf "$SRC/ncurses-6.6.tar.gz" -C "$SRC"
    cd ncurses-6.6
    ./configure --prefix=/usr --mandir=/usr/share/man --with-shared \
      --without-debug --without-normal --without-cxx-binding --enable-pc-files \
      --with-pkg-config-libdir=/usr/lib/pkgconfig
    make $MAKEFLAGS
    make DESTDIR="$PWD/dest" install
    sed -e 's/^#if.*XOPEN.*$/#if 1/' -i dest/usr/include/curses.h
    cp --remove-destination -av dest/* /
    for lib in ncurses form panel menu; do
        ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
        ln -sfv ${lib}w.pc /usr/lib/pkgconfig/${lib}.pc
    done
    ln -sfv libncursesw.so /usr/lib/libcurses.so
    cp -v -R doc -T /usr/share/doc/ncurses-6.6 2>/dev/null || true
    cd "$SRC" && rm -rf ncurses-6.6
    log_ok "ncurses-6.6 done"
}

# ---------- 30. sed-4.9 ----------
build_sed() {
    log_info "Building: sed-4.9"
    cd "$SRC"
    rm -rf sed-4.9
    tar xf "$SRC/sed-4.9.tar.xz" -C "$SRC"
    cd sed-4.9
    ./configure --prefix=/usr
    make $MAKEFLAGS
    make html
    make check 2>&1 | tee "$LOG/sed-check.log" || true
    make install
    install -d -m755 /usr/share/doc/sed-4.9
    install -m644 doc/sed.html /usr/share/doc/sed-4.9 2>/dev/null || true
    cd "$SRC" && rm -rf sed-4.9
    log_ok "sed-4.9 done"
}

# ---------- 31. psmisc-23.7 ----------
build_psmisc() {
    build_std psmisc 23.7 psmisc-23.7 psmisc
}

# ---------- 32. gettext-1.0 ----------
build_gettext() {
    build_doc gettext 1.0 gettext-1.0 gettext --disable-static
    chmod -v 0755 /usr/lib/preloadable_libintl.so
}

# ---------- 33. bison-3.8.2 ----------
build_bison() {
    build_doc bison 3.8.2 bison-3.8.2 bison
}

# ---------- 34. grep-3.12 ----------
build_grep() {
    log_info "Building: grep-3.12"
    cd "$SRC"
    rm -rf grep-3.12
    tar xf "$SRC/grep-3.12.tar.xz" -C "$SRC"
    cd grep-3.12
    sed -i "s/echo/#echo/" src/egrep.sh
    ./configure --prefix=/usr
    make $MAKEFLAGS
    make check 2>&1 | tee "$LOG/grep-check.log" || true
    make install
    cd "$SRC" && rm -rf grep-3.12
    log_ok "grep-3.12 done"
}

# ---------- 35. bash-5.3 ----------
build_bash() {
    log_info "Building: bash-5.3"
    cd "$SRC"
    rm -rf bash-5.3
    tar xf "$SRC/bash-5.3.tar.gz" -C "$SRC"
    cd bash-5.3
    ./configure --prefix=/usr --without-bash-malloc --with-installed-readline \
      --docdir=/usr/share/doc/bash-5.3
    make $MAKEFLAGS
    make install
    cd "$SRC" && rm -rf bash-5.3
    log_ok "bash-5.3 done"
}

# ---------- 36. libtool-2.5.4 ----------
build_libtool() {
    build_std libtool 2.5.4 libtool-2.5.4 libtool
    rm -fv /usr/lib/libltdl.a
}

# ---------- 37. gdbm-1.26 ----------
build_gdbm() {
    log_info "Building: gdbm-1.26"
    cd "$SRC"
    rm -rf gdbm-1.26
    tar xf "$SRC/gdbm-1.26.tar.gz" -C "$SRC"
    cd gdbm-1.26
    ./configure --prefix=/usr --disable-static --enable-libgdbm-compat
    make $MAKEFLAGS
    make check 2>&1 | tee "$LOG/gdbm-check.log" || true
    make install
    cd "$SRC" && rm -rf gdbm-1.26
    log_ok "gdbm-1.26 done"
}

# ---------- 38. gperf-3.3 ----------
build_gperf() {
    build_doc gperf 3.3 gperf-3.3 gperf
}

# ---------- 39. expat-2.7.4 ----------
build_expat() {
    build_doc expat 2.7.4 expat-2.7.4 expat --disable-static
}

# ---------- 40. inetutils-2.7 ----------
build_inetutils() {
    log_info "Building: inetutils-2.7"
    cd "$SRC"
    rm -rf inetutils-2.7
    tar xf "$SRC/inetutils-2.7.tar.gz" -C "$SRC"
    cd inetutils-2.7
    sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c
    ./configure --prefix=/usr --bindir=/usr/bin --localstatedir=/var \
      --disable-logger --disable-whois --disable-rcp --disable-rexec \
      --disable-rlogin --disable-rsh --disable-servers
    make $MAKEFLAGS
    make check 2>&1 | tee "$LOG/inetutils-check.log" || true
    make install
    mv -v /usr/{,s}bin/ifconfig
    cd "$SRC" && rm -rf inetutils-2.7
    log_ok "inetutils-2.7 done"
}

# ---------- 41. less-692 ----------
build_less() {
    log_info "Building: less-692"
    cd "$SRC"
    rm -rf less-692
    tar xf "$SRC/less-692.tar.gz" -C "$SRC"
    cd less-692
    ./configure --prefix=/usr --sysconfdir=/etc
    make $MAKEFLAGS
    make check 2>&1 | tee "$LOG/less-check.log" || true
    make install
    cd "$SRC" && rm -rf less-692
    log_ok "less-692 done"
}

# ---------- 42. perl-5.42.0 ----------
build_perl() {
    log_info "Building: perl-5.42.0"
    cd "$SRC"
    rm -rf perl-5.42.0
    tar xf "$SRC/perl-5.42.0.tar.xz" -C "$SRC"
    cd perl-5.42.0
    export BUILD_ZLIB=False BUILD_BZIP2=0
    sh Configure -des -D prefix=/usr -D vendorprefix=/usr \
      -D privlib=/usr/lib/perl5/5.42/core_perl \
      -D archlib=/usr/lib/perl5/5.42/core_perl \
      -D sitelib=/usr/lib/perl5/5.42/site_perl \
      -D sitearch=/usr/lib/perl5/5.42/site_perl \
      -D vendorlib=/usr/lib/perl5/5.42/vendor_perl \
      -D vendorarch=/usr/lib/perl5/5.42/vendor_perl \
      -D man1dir=/usr/share/man/man1 -D man3dir=/usr/share/man/man3 \
      -D pager="/usr/bin/less -isR" -D useshrplib -D usethreads
    make $MAKEFLAGS
    make test_harness 2>&1 | tee "$LOG/perl-test.log" || true
    make install
    unset BUILD_ZLIB BUILD_BZIP2
    cd "$SRC" && rm -rf perl-5.42.0
    log_ok "perl-5.42.0 done"
}

# ---------- 43. XML-Parser-2.47 ----------
build_XML_Parser() {
    log_info "Building: XML-Parser-2.47"
    cd "$SRC"
    rm -rf XML-Parser-2.47
    tar xf "$SRC/XML-Parser-2.47.tar.gz" -C "$SRC"
    cd XML-Parser-2.47
    perl Makefile.PL
    make $MAKEFLAGS
    make test 2>&1 | tee "$LOG/XML-Parser-test.log" || true
    make install
    cd "$SRC" && rm -rf XML-Parser-2.47
    log_ok "XML-Parser-2.47 done"
}

# ---------- 44. intltool-0.51.0 ----------
build_intltool() {
    log_info "Building: intltool-0.51.0"
    cd "$SRC"
    rm -rf intltool-0.51.0
    tar xf "$SRC/intltool-0.51.0.tar.gz" -C "$SRC"
    cd intltool-0.51.0
    sed -i 's:\\\${:\\\$\\{:' intltool-update.in
    ./configure --prefix=/usr
    make $MAKEFLAGS
    make check 2>&1 | tee "$LOG/intltool-check.log" || true
    make install
    install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
    cd "$SRC" && rm -rf intltool-0.51.0
    log_ok "intltool-0.51.0 done"
}

# ---------- 45. autoconf-2.72 ----------
build_autoconf() {
    build_std autoconf 2.72 autoconf-2.72 autoconf
}

# ---------- 46. automake-1.18.1 ----------
build_automake() {
    build_doc automake 1.18.1 automake-1.18.1 automake
}

# ---------- 47. openssl-3.6.1 ----------
build_openssl() {
    log_info "Building: openssl-3.6.1"
    cd "$SRC"
    rm -rf openssl-3.6.1
    tar xf "$SRC/openssl-3.6.1.tar.gz" -C "$SRC"
    cd openssl-3.6.1
    ./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib shared zlib-dynamic
    make $MAKEFLAGS
    HARNESS_JOBS=$(nproc) make test 2>&1 | tee "$LOG/openssl-test.log" || true
    sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
    make MANSUFFIX=ssl install
    mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.6.1 2>/dev/null || true
    cd "$SRC" && rm -rf openssl-3.6.1
    log_ok "openssl-3.6.1 done"
}

# ---------- 48. libelf (elfutils-0.194) ----------
build_libelf() {
    log_info "Building: libelf (elfutils-0.194)"
    cd "$SRC"
    rm -rf elfutils-0.194
    tar xf "$SRC/elfutils-0.194.tar.bz2" -C "$SRC"
    cd elfutils-0.194
    ./configure --prefix=/usr --disable-debuginfod --enable-libdebuginfod=dummy
    make -C lib $MAKEFLAGS
    make -C libelf $MAKEFLAGS
    make -C libelf install
    install -vm644 config/libelf.pc /usr/lib/pkgconfig
    rm /usr/lib/libelf.a
    cd "$SRC" && rm -rf elfutils-0.194
    log_ok "libelf done"
}

# ---------- 49. libffi-3.5.2 ----------
build_libffi() {
    log_info "Building: libffi-3.5.2"
    cd "$SRC"
    rm -rf libffi-3.5.2
    tar xf "$SRC/libffi-3.5.2.tar.gz" -C "$SRC"
    cd libffi-3.5.2
    ./configure --prefix=/usr --disable-static --with-gcc-arch=native
    make $MAKEFLAGS
    make check 2>&1 | tee "$LOG/libffi-check.log" || true
    make install
    cd "$SRC" && rm -rf libffi-3.5.2
    log_ok "libffi-3.5.2 done"
}

# ---------- 50. sqlite-3510200 ----------
build_sqlite() {
    log_info "Building: sqlite-3510200"
    cd "$SRC"
    rm -rf sqlite-autoconf-3510200
    tar xf "$SRC/sqlite-autoconf-3510200.tar.gz" -C "$SRC"
    cd sqlite-autoconf-3510200
    ./configure --prefix=/usr --disable-static --enable-fts{4,5} \
      CPPFLAGS="-D SQLITE_ENABLE_COLUMN_METADATA=1 -D SQLITE_ENABLE_UNLOCK_NOTIFY=1 -D SQLITE_ENABLE_DBSTAT_VTAB=1 -D SQLITE_SECURE_DELETE=1"
    make LDFLAGS.rpath="" $MAKEFLAGS
    make install
    cd "$SRC" && rm -rf sqlite-autoconf-3510200
    log_ok "sqlite-3510200 done"
}

# ---------- 51. python-3.14.3 ----------
build_python() {
    log_info "Building: python-3.14.3"
    cd "$SRC"
    rm -rf Python-3.14.3
    tar xf "$SRC/Python-3.14.3.tar.xz" -C "$SRC"
    cd Python-3.14.3
    ./configure --prefix=/usr --enable-shared --with-system-expat \
      --without-static-libpython
    make $MAKEFLAGS
    make test TESTOPTS="--timeout 120" 2>&1 | tee "$LOG/python-test.log" || true
    make install
    rm -f /usr/lib/python3.14/EXTERNALLY-MANAGED
    cat > /etc/pip.conf << "PIPEOF"
[global]
root-user-action = ignore
disable-pip-version-check = true
PIPEOF
    cd "$SRC" && rm -rf Python-3.14.3
    log_ok "python-3.14.3 done"
}

# ---------- 52. flit-core-3.12.0 ----------
build_flit_core() {
    build_pip flit_core 3.12.0 flit_core-3.12.0 flit_core
}

# ---------- 53. packaging-26.0 ----------
build_packaging() {
    build_pip packaging 26.0 packaging-26.0 packaging
}

# ---------- 54. wheel-0.46.3 ----------
build_wheel() {
    build_pip wheel 0.46.3 wheel-0.46.3 wheel
}

# ---------- 55. setuptools-82.0.0 ----------
build_setuptools() {
    build_pip setuptools 82.0.0 setuptools-82.0.0 setuptools
}

# ---------- 56. ninja-1.13.2 ----------
build_ninja() {
    log_info "Building: ninja-1.13.2"
    cd "$SRC"
    rm -rf ninja-1.13.2
    tar xf "$SRC/ninja-1.13.2.tar.gz" -C "$SRC"
    cd ninja-1.13.2
    sed -i '/int Guess/a \  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc
    python3 configure.py --bootstrap --verbose
    install -vm755 ninja /usr/bin/
    install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja 2>/dev/null || true
    install -vDm644 misc/zsh-completion /usr/share/zsh/site-functions/_ninja 2>/dev/null || true
    cd "$SRC" && rm -rf ninja-1.13.2
    log_ok "ninja-1.13.2 done"
}

# ---------- 57. meson-1.10.1 ----------
build_meson() {
    log_info "Building: meson-1.10.1"
    cd "$SRC"
    rm -rf meson-1.10.1
    tar xf "$SRC/meson-1.10.1.tar.gz" -C "$SRC"
    cd meson-1.10.1
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
    pip3 install --no-index --find-links dist meson
    install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson 2>/dev/null || true
    install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson 2>/dev/null || true
    cd "$SRC" && rm -rf meson-1.10.1
    log_ok "meson-1.10.1 done"
}

# ---------- 58. kmod-34.2 ----------
build_kmod() {
    build_meson kmod 34.2 kmod-34.2 -D manpages=false
}

# ---------- 59. coreutils-9.10 ----------
build_coreutils() {
    log_info "Building: coreutils-9.10"
    cd "$SRC"
    rm -rf coreutils-9.10
    tar xf "$SRC/coreutils-9.10.tar.xz" -C "$SRC"
    cd coreutils-9.10
    patch -Np1 -i ../coreutils-9.10-i18n-1.patch
    autoreconf -fv
    automake -af
    FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr
    make $MAKEFLAGS
    make NON_ROOT_USERNAME=tester check-root 2>&1 | tee "$LOG/coreutils-checkroot.log" || true
    groupadd -g 102 dummy -U tester 2>/dev/null || true
    chown -R tester . 2>/dev/null || true
    su tester -c "PATH=$PATH make -k RUN_EXPENSIVE_TESTS=yes check" < /dev/null 2>&1 | tee "$LOG/coreutils-check.log" || true
    groupdel dummy 2>/dev/null || true
    make install
    mv -v /usr/bin/chroot /usr/sbin
    mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8 2>/dev/null || true
    sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8 2>/dev/null || true
    cd "$SRC" && rm -rf coreutils-9.10
    log_ok "coreutils-9.10 done"
}

# ---------- 60. diffutils-3.12 ----------
build_diffutils() {
    build_std diffutils 3.12 diffutils-3.12 diffutils
}

# ---------- 61. gawk-5.3.2 ----------
build_gawk() {
    log_info "Building: gawk-5.3.2"
    cd "$SRC"
    rm -rf gawk-5.3.2
    tar xf "$SRC/gawk-5.3.2.tar.xz" -C "$SRC"
    cd gawk-5.3.2
    sed -i 's/extras//' Makefile.in
    ./configure --prefix=/usr
    make $MAKEFLAGS
    timeout 300 make check 2>&1 | tee "$LOG/gawk-check.log" || true
    rm -f /usr/bin/gawk-5.3.2
    make install
    ln -sv gawk.1 /usr/share/man/man1/awk.1 2>/dev/null || true
    cd "$SRC" && rm -rf gawk-5.3.2
    log_ok "gawk-5.3.2 done"
}

# ---------- 62. findutils-4.10.0 ----------
build_findutils() {
    log_info "Building: findutils-4.10.0"
    cd "$SRC"
    rm -rf findutils-4.10.0
    tar xf "$SRC/findutils-4.10.0.tar.xz" -C "$SRC"
    cd findutils-4.10.0
    ./configure --prefix=/usr --localstatedir=/var/lib/locate
    make $MAKEFLAGS
    make check 2>&1 | tee "$LOG/findutils-check.log" || true
    make install
    cd "$SRC" && rm -rf findutils-4.10.0
    log_ok "findutils-4.10.0 done"
}

# ---------- 63. groff-1.23.0 ----------
build_groff() {
    log_info "Building: groff-1.23.0"
    cd "$SRC"
    rm -rf groff-1.23.0
    tar xf "$SRC/groff-1.23.0.tar.gz" -C "$SRC"
    cd groff-1.23.0
    PAGE=A4 ./configure --prefix=/usr
    make $MAKEFLAGS
    make check 2>&1 | tee "$LOG/groff-check.log" || true
    make install
    cd "$SRC" && rm -rf groff-1.23.0
    log_ok "groff-1.23.0 done"
}

# ---------- 64. grub-2.14 ----------
build_grub() {
    log_info "Building: grub-2.14"
    cd "$SRC"
    rm -rf grub-2.14
    tar xf "$SRC/grub-2.14.tar.xz" -C "$SRC"
    cd grub-2.14
    unset {C,CPP,CXX,LD}FLAGS
    sed 's/--image-base/--nonexist-linker-option/' -i configure
    ./configure --prefix=/usr --sysconfdir=/etc --disable-efiemu --disable-werror
    make $MAKEFLAGS
    make install
    cd "$SRC" && rm -rf grub-2.14
    log_ok "grub-2.14 done"
}

# ---------- 65. gzip-1.14 ----------
build_gzip() {
    build_std gzip 1.14 gzip-1.14 gzip
}

# ---------- 66. iproute2-6.18.0 ----------
build_iproute2() {
    log_info "Building: iproute2-6.18.0"
    cd "$SRC"
    rm -rf iproute2-6.18.0
    tar xf "$SRC/iproute2-6.18.0.tar.xz" -C "$SRC"
    cd iproute2-6.18.0
    sed -i /ARPD/d Makefile
    rm -fv man/man8/arpd.8
    make NETNS_RUN_DIR=/run/netns $MAKEFLAGS
    make SBINDIR=/usr/sbin install
    cd "$SRC" && rm -rf iproute2-6.18.0
    log_ok "iproute2-6.18.0 done"
}

# ---------- 67. kbd-2.9.0 ----------
build_kbd() {
    log_info "Building: kbd-2.9.0"
    cd "$SRC"
    rm -rf kbd-2.9.0
    tar xf "$SRC/kbd-2.9.0.tar.xz" -C "$SRC"
    cd kbd-2.9.0
    patch -Np1 -i ../kbd-2.9.0-backspace-1.patch
    sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
    sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
    ./configure --prefix=/usr --disable-vlock
    make $MAKEFLAGS
    make check 2>&1 | tee "$LOG/kbd-check.log" || true
    make install
    cd "$SRC" && rm -rf kbd-2.9.0
    log_ok "kbd-2.9.0 done"
}

# ---------- 68. libpipeline-1.5.8 ----------
build_libpipeline() {
    build_std libpipeline 1.5.8 libpipeline-1.5.8 libpipeline
}

# ---------- 69. make-4.4.1 ----------
build_make() {
    build_std make 4.4.1 make-4.4.1 make
}

# ---------- 70. patch-2.8 ----------
build_patch() {
    build_std patch 2.8 patch-2.8 patch
}

# ---------- 71. tar-1.35 ----------
build_tar() {
    log_info "Building: tar-1.35"
    cd "$SRC"
    rm -rf tar-1.35
    tar xf "$SRC/tar-1.35.tar.xz" -C "$SRC"
    cd tar-1.35
    FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr
    make $MAKEFLAGS
    make check 2>&1 | tee "$LOG/tar-check.log" || true
    make install
    make -C doc install-html docdir=/usr/share/doc/tar-1.35 2>/dev/null || true
    cd "$SRC" && rm -rf tar-1.35
    log_ok "tar-1.35 done"
}

# ---------- 72. texinfo-7.2 ----------
build_texinfo() {
    log_info "Building: texinfo-7.2"
    cd "$SRC"
    rm -rf texinfo-7.2
    tar xf "$SRC/texinfo-7.2.tar.xz" -C "$SRC"
    cd texinfo-7.2
    sed 's/! $output_file eq/$output_file ne/' -i tp/Texinfo/Convert/*.pm
    ./configure --prefix=/usr
    make $MAKEFLAGS
    timeout 600 make check 2>&1 | tee "$LOG/texinfo-check.log" || true
    make install
    cd "$SRC" && rm -rf texinfo-7.2
    log_ok "texinfo-7.2 done"
}

# ---------- 73. vim-9.2.0078 ----------
build_vim() {
    log_info "Building: vim-9.2.0078"
    cd "$SRC"
    rm -rf vim-9.2.0078
    tar xf "$SRC/vim-9.2.0078.tar.gz" -C "$SRC"
    cd vim-9.2.0078
    echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
    ./configure --prefix=/usr
    make $MAKEFLAGS
    make install
    ln -sv vim /usr/bin/vi
    for L in /usr/share/man/{,*/}man1/vim.1; do
        ln -sv vim.1 "$(dirname "$L")/vi.1" 2>/dev/null || true
    done
    ln -sv ../vim/vim92/doc /usr/share/doc/vim-9.2.0078 2>/dev/null || true
    cat > /etc/vimrc << "VIMRC"
" Begin /etc/vimrc
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1
set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif
" End /etc/vimrc
VIMRC
    cd "$SRC" && rm -rf vim-9.2.0078
    log_ok "vim-9.2.0078 done"
}

# ---------- 74. markupsafe-3.0.3 ----------
build_markupsafe() {
    build_pip markupsafe 3.0.3 markupsafe-3.0.3 Markupsafe
}

# ---------- 75. jinja2-3.1.6 ----------
build_jinja2() {
    build_pip jinja2 3.1.6 jinja2-3.1.6 Jinja2
}

# ---------- 76. systemd-259.1 ----------
build_systemd() {
    log_info "Building: systemd-259.1"
    cd "$SRC"
    rm -rf systemd-259.1
    tar xf "$SRC/systemd-259.1.tar.gz" -C "$SRC"
    cd systemd-259.1
    sed -e 's/GROUP="render"/GROUP="video"/' -e 's/GROUP="sgx", //' \
      -i rules.d/50-udev-default.rules.in
    echo 'NAME="HyperPenguinOS"' > /etc/os-release
    mkdir -p build && cd build
    meson setup .. --prefix=/usr --buildtype=release \
      -D default-dnssec=no -D firstboot=false -D install-tests=false \
      -D ldconfig=false -D sysusers=false -D rpmmacrosdir=no \
      -D homed=disabled -D man=disabled -D mode=release \
      -D pamconfdir=no -D dev-kvm-mode=0660 -D nobody-group=nogroup \
      -D sysupdate=disabled -D ukify=disabled \
      -D sbat-distro=hyperpenguin -D sbat-distro-generation=1 \
      -D sbat-distro-url=https://hyperpenguin.org \
      -D docdir=/usr/share/doc/systemd-259.1
    ninja $MAKEFLAGS
    unshare -m ninja test 2>&1 | tee "$LOG/systemd-test.log" || true
    ninja install
    systemd-machine-id-setup
    systemctl preset-all 2>/dev/null || true
    cd "$SRC" && rm -rf systemd-259.1
    log_ok "systemd-259.1 done"
}

# ---------- 77. dbus-1.16.2 ----------
build_dbus() {
    build_meson dbus 1.16.2 dbus-1.16.2 --wrap-mode=nofallback
    ln -sfv /etc/machine-id /var/lib/dbus
}

# ---------- 78. man-db-2.13.1 ----------
build_man_db() {
    log_info "Building: man-db-2.13.1"
    cd "$SRC"
    rm -rf man-db-2.13.1
    tar xf "$SRC/man-db-2.13.1.tar.xz" -C "$SRC"
    cd man-db-2.13.1
    ./configure --prefix=/usr --docdir=/usr/share/doc/man-db-2.13.1 \
      --sysconfdir=/etc --disable-setuid --enable-cache-owner=bin \
      --with-browser=/usr/bin/lynx --with-vgrind=/usr/bin/vgrind --with-grap=/usr/bin/grap
    make $MAKEFLAGS
    make check 2>&1 | tee "$LOG/man-db-check.log" || true
    make install
    cd "$SRC" && rm -rf man-db-2.13.1
    log_ok "man-db-2.13.1 done"
}

# ---------- 79. procps-ng-4.0.6 ----------
build_procps_ng() {
    log_info "Building: procps-ng-4.0.6"
    cd "$SRC"
    rm -rf procps-ng-4.0.6
    tar xf "$SRC/procps-ng-4.0.6.tar.xz" -C "$SRC"
    cd procps-ng-4.0.6
    ./configure --prefix=/usr --docdir=/usr/share/doc/procps-ng-4.0.6 \
      --disable-static --disable-kill --enable-watch8bit --with-systemd
    make $MAKEFLAGS
    make check 2>&1 | tee "$LOG/procps-ng-check.log" || true
    make install
    cd "$SRC" && rm -rf procps-ng-4.0.6
    log_ok "procps-ng-4.0.6 done"
}

# ---------- 80. util-linux-2.41.3 ----------
build_util_linux() {
    log_info "Building: util-linux-2.41.3"
    cd "$SRC"
    rm -rf util-linux-2.41.3
    tar xf "$SRC/util-linux-2.41.3.tar.xz" -C "$SRC"
    cd util-linux-2.41.3
    ./configure --bindir=/usr/bin --libdir=/usr/lib --runstatedir=/run \
      --sbindir=/usr/sbin --disable-chfn-chsh --disable-login --disable-nologin \
      --disable-su --disable-setpriv --disable-runuser --disable-pylibmount \
      --disable-liblastlog2 --disable-static --without-python \
      ADJTIME_PATH=/var/lib/hwclock/adjtime --docdir=/usr/share/doc/util-linux-2.41.3
    make $MAKEFLAGS
    make install
    cd "$SRC" && rm -rf util-linux-2.41.3
    log_ok "util-linux-2.41.3 done"
}

# ---------- 81. e2fsprogs-1.47.3 ----------
build_e2fsprogs() {
    log_info "Building: e2fsprogs-1.47.3"
    cd "$SRC"
    rm -rf e2fsprogs-1.47.3
    tar xf "$SRC/e2fsprogs-1.47.3.tar.gz" -C "$SRC"
    cd e2fsprogs-1.47.3
    mkdir -v build && cd build
    ../configure --prefix=/usr --sysconfdir=/etc --enable-elf-shlibs \
      --disable-libblkid --disable-libuuid --disable-uuidd --disable-fsck
    make $MAKEFLAGS
    make check 2>&1 | tee "$LOG/e2fsprogs-check.log" || true
    make install
    rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
    gunzip -v /usr/share/info/libext2fs.info.gz 2>/dev/null || true
    install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info 2>/dev/null || true
    cd "$SRC" && rm -rf e2fsprogs-1.47.3
    log_ok "e2fsprogs-1.47.3 done"
}

# ============================================================
# MAIN BUILD LOOP
# ============================================================
log_info "=== Iniciando construcción de paquetes LFS Chapter 8 ==="

# Execute each package build in order
run_build man-pages-6.17 build_man_pages
run_build iana-etc-20260202 build_iana_etc
run_build m4-1.4.21 build_m4
run_build bison-3.8.2 build_bison
run_build glibc-2.41 build_glibc
run_build zlib-1.3.2 build_zlib
run_build bzip2-1.0.8 build_bzip2
run_build xz-5.8.2 build_xz
run_build lz4-1.10.0 build_lz4
run_build zstd-1.5.7 build_zstd
run_build file-5.46 build_file
run_build ncurses-6.6 build_ncurses
run_build readline-8.3 build_readline
run_build pcre2-10.47 build_pcre2
run_build bc-7.0.3 build_bc
run_build flex-2.6.4 build_flex
run_build tcl-8.6.17 build_tcl
run_build expect-5.45.4 build_expect
run_build dejagnu-1.6.3 build_dejagnu
run_build pkgconf-2.5.1 build_pkgconf
run_build binutils-2.46.0 build_binutils
run_build gmp-6.3.0 build_gmp
run_build mpfr-4.2.2 build_mpfr
run_build mpc-1.3.1 build_mpc
run_build attr-2.5.2 build_attr
run_build acl-2.3.2 build_acl
run_build libcap-2.77 build_libcap
run_build libxcrypt-4.5.2 build_libxcrypt
run_build shadow-4.17.4 build_shadow
run_build gcc-15.2.0 build_gcc
run_build sed-4.9 build_sed
run_build psmisc-23.7 build_psmisc
run_build gettext-0.24 build_gettext
run_build grep-3.11 build_grep
run_build bash-5.3 build_bash
run_build libtool-2.5.4 build_libtool
run_build gdbm-1.24 build_gdbm
run_build gperf-3.1 build_gperf
run_build expat-2.7.1 build_expat
run_build inetutils-2.6 build_inetutils
run_build less-668 build_less
run_build perl-5.42.0 build_perl
run_build XML-Parser-2.47 build_XML_Parser
run_build intltool-0.51.0 build_intltool
run_build autoconf-2.72 build_autoconf
run_build automake-1.18.1 build_automake
run_build openssl-3.5.0 build_openssl
run_build libelf-0.194 build_libelf
run_build libffi-3.4.7 build_libffi
run_build sqlite-3.49.1 build_sqlite
run_build python-3.14.0 build_python
run_build flit-core-3.12.0 build_flit_core
run_build packaging-24.2 build_packaging
run_build wheel-0.45.1 build_wheel
run_build setuptools-75.8.0 build_setuptools
run_build ninja-1.13.0 build_ninja
run_build meson-1.7.0 build_meson
run_build kmod-34 build_kmod
run_build coreutils-9.10 build_coreutils
run_build diffutils-3.12 build_diffutils
run_build gawk-5.3.1 build_gawk
run_build findutils-4.11.1 build_findutils
run_build groff-1.23.0 build_groff
run_build grub-2.14 build_grub
run_build gzip-1.14 build_gzip
run_build iproute2-6.15.0 build_iproute2
run_build kbd-2.7.1 build_kbd
run_build libpipeline-1.5.8 build_libpipeline
run_build make-4.4.1 build_make
run_build patch-2.7.6 build_patch
run_build tar-1.35 build_tar
run_build texinfo-7.2 build_texinfo
run_build vim-9.1.1227 build_vim
run_build markupsafe-3.0.2 build_markupsafe
run_build jinja2-3.1.6 build_jinja2
run_build systemd-257.4 build_systemd
run_build dbus-1.16.2 build_dbus
run_build man-db-2.13.0 build_man_db
run_build procps-ng-4.0.5 build_procps_ng
run_build util-linux-2.41 build_util_linux
run_build e2fsprogs-1.47.3 build_e2fsprogs

log_info "=== LFS Chapter 8 completado ==="
echo ""
log_info "Resumen de logs en: $LOG/"
ls -la "$LOG/"
CHROOT_SCRIPT

chmod +x "$LFS_ROOTFS/build-chroot.sh"

# ============================================================
# Execute chroot build
# ============================================================
log_info "Entrando al chroot para construcción nativa..."
log_info "Esto tomará muchas horas (glibc ~12 SBU, gcc ~45 SBU)"

chroot "$LFS_ROOTFS" /usr/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin \
    MAKEFLAGS="$MAKEFLAGS" \
    /build-chroot.sh

# Cleanup
log_info "Limpiando..."
umount "$LFS_ROOTFS/sources" 2>/dev/null || true
umount "$LFS_ROOTFS/run" 2>/dev/null || true
umount "$LFS_ROOTFS/sys" 2>/dev/null || true
umount "$LFS_ROOTFS/proc" 2>/dev/null || true
umount "$LFS_ROOTFS/dev/pts" 2>/dev/null || true
umount "$LFS_ROOTFS/dev" 2>/dev/null || true

log_success "=== Fase 3 completada: Sistema Base LFS ==="

# ============================================================
# Apply system config (fstab, hostname, locale, network, etc.)
# ============================================================
"$(dirname "$0")/00.5-setup-config.sh"
log_success "Configuración del sistema aplicada"
