# Build Instructions — LFS Chapter 8 (HyperPenguinOS)

> Basado en LFS 13.0-systemd (marzo 2026).  
> Objetivo: 81 paquetes core + ~12 BLFS extras

## Leyenda

| Símbolo | Significado |
|---------|-------------|
| ⚡ | autotools (`./configure --prefix=/usr ...` → `make` → `make install`) |
| ⚡+ | autotools con flags especiales |
| 🔧 | meson (`meson setup build --prefix=/usr ...` → `ninja`) |
| 🐍 | Python pip (`pip3 wheel ...` → `pip3 install ...`) |
| 💎 | Perl (`perl Makefile.PL` / `sh Configure`) |
| ⭐ | Build especial (case-by-case) |
| 📋 | No build (solo copiar archivos) |

---

## LFS Chapter 8 — Lista Completa

### 1. man-pages-6.17 ⭐
```
make -R GIT=false prefix=/usr install
```
- Pre-install: `rm -v man3/crypt*`

### 2. iana-etc-20260202 📋
```
cp -v services protocols /etc
```

### 3. glibc-2.43 ⭐
```
patch -Np1 -i ../glibc-fhs-1.patch
mkdir -v build && cd build
echo "rootsbindir=/usr/sbin" > configparms
../configure --prefix=/usr --disable-werror --disable-nscd \
  libc_cv_slibdir=/usr/lib --enable-stack-protector=strong \
  --enable-kernel=5.4
make
make check  # critical
touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install
sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd
localedef -i C -f UTF-8 C.UTF-8 ...
```
- Post-install: `/etc/nsswitch.conf`, timezone data, `/etc/ld.so.conf`

### 4. zlib-1.3.2 ⚡
```
./configure --prefix=/usr
make && make check && make install
rm -fv /usr/lib/libz.a
```

### 5. bzip2-1.0.8 ⭐
```
patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so && make clean
make && make PREFIX=/usr install
cp -av libbz2.so.* /usr/lib
ln -sfv libbz2.so.1.0.8 /usr/lib/libbz2.so
ln -sfv libbz2.so.1.0.8 /usr/lib/libbz2.so.1
cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do ln -sfv bzip2 $i; done
rm -fv /usr/lib/libbz2.a
```

### 6. xz-5.8.2 ⚡+
```
./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/xz-5.8.2
make && make check && make install
```

### 7. lz4-1.10.0 ⭐
```
make BUILD_STATIC=no PREFIX=/usr
make -j1 check
make BUILD_STATIC=no PREFIX=/usr install
```

### 8. zstd-1.5.7 ⭐
```
make prefix=/usr && make check && make prefix=/usr install
rm -v /usr/lib/libzstd.a
```

### 9. file-5.46 ⚡
```
./configure --prefix=/usr
make && make check && make install
```

### 10. readline-8.3 ⚡+
```
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf
sed -e '270a\     else\       chars_avail = 1;' -e '288i\   result = -1;' -i.orig input.c
./configure --prefix=/usr --disable-static --with-curses --docdir=/usr/share/doc/readline-8.3
make SHLIB_LIBS="-lncursesw"
make install
```

### 11. pcre2-10.47 ⚡+
```
./configure --prefix=/usr --docdir=/usr/share/doc/pcre2-10.47 \
  --enable-unicode --enable-jit --enable-pcre2-16 --enable-pcre2-32 \
  --enable-pcre2grep-libz --enable-pcre2grep-libbz2 \
  --enable-pcre2test-libreadline --disable-static
make && make check && make install
```

### 12. m4-1.4.21 ⚡
```
./configure --prefix=/usr
make && make check && make install
```

### 13. bc-7.0.3 ⚡+
```
CC='gcc -std=c99' ./configure --prefix=/usr -G -O3 -r
make && make test && make install
```

### 14. flex-2.6.4 ⚡+
```
./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/flex-2.6.4
make && make check && make install
ln -sv flex /usr/bin/lex && ln -sv flex.1 /usr/share/man/man1/lex.1
```

### 15. tcl-8.6.17 ⭐
```
SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr --mandir=/usr/share/man --disable-rpath
make
sed -e "s|$SRCDIR/unix|/usr/lib|" -e "s|$SRCDIR|/usr/include|" -i tclConfig.sh
sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.12|/usr/lib/tdbc1.1.12|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.12/generic|/usr/include|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.12/library|/usr/lib/tcl8.6|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.12|/usr/include|" -i pkgs/tdbc1.1.12/tdbcConfig.sh
sed -e "s|$SRCDIR/unix/pkgs/itcl4.3.4|/usr/lib/itcl4.3.4|" \
    -e "s|$SRCDIR/pkgs/itcl4.3.4/generic|/usr/include|" \
    -e "s|$SRCDIR/pkgs/itcl4.3.4|/usr/include|" -i pkgs/itcl4.3.4/itclConfig.sh
unset SRCDIR
make test && make install
chmod 644 /usr/lib/libtclstub8.6.a
chmod -v u+w /usr/lib/libtcl8.6.so
make install-private-headers
ln -sfv tclsh8.6 /usr/bin/tclsh
mv -v /usr/share/man/man3/{Thread,Tcl_Thread}.3
```

### 16. expect-5.45.4 ⭐
```
patch -Np1 -i ../expect-5.45.4-gcc15-1.patch
./configure --prefix=/usr --with-tcl=/usr/lib --enable-shared \
  --disable-rpath --mandir=/usr/share/man --with-tclinclude=/usr/include
make && make test && make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib
```

### 17. dejagnu-1.6.3 ⭐
```
mkdir -v build && cd build
../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext -o doc/dejagnu.txt ../doc/dejagnu.texi
make check && make install
install -v -dm755 /usr/share/doc/dejagnu-1.6.3
install -v -m644 doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3
```

### 18. pkgconf-2.5.1 ⚡+
```
./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/pkgconf-2.5.1
make && make install
ln -sv pkgconf /usr/bin/pkg-config
ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1
```

### 19. binutils-2.46.0 ⭐
```
mkdir -v build && cd build
../configure --prefix=/usr --sysconfdir=/etc --enable-ld=default \
  --enable-plugins --enable-shared --disable-werror --enable-64-bit-bfd \
  --enable-new-dtags --with-system-zlib --enable-default-hash-style=gnu
make tooldir=/usr
make -k check  # critical
grep '^FAIL:' $(find -name '*.log')
make tooldir=/usr install
rm -rfv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a /usr/share/doc/gprofng/
```

### 20. gmp-6.3.0 ⚡+
```
sed -i '/long long t1;/,+1s/()/(...)/' configure
./configure --prefix=/usr --enable-cxx --disable-static --docdir=/usr/share/doc/gmp-6.3.0
make && make html
make check 2>&1 | tee gmp-check-log  # critical, ≥199 tests
awk '/# PASS:/{total+=$3}; END{print total}' gmp-check-log
make install && make install-html
```

### 21. mpfr-4.2.2 ⚡+
```
./configure --prefix=/usr --disable-static --enable-thread-safe --docdir=/usr/share/doc/mpfr-4.2.2
make && make html
make check  # critical, 198 tests
make install && make install-html
```

### 22. mpc-1.3.1 ⚡+
```
./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/mpc-1.3.1
make && make html && make check && make install && make install-html
```

### 23. attr-2.5.2 ⚡+
```
./configure --prefix=/usr --disable-static --sysconfdir=/etc --docdir=/usr/share/doc/attr-2.5.2
make && make check && make install
```

### 24. acl-2.3.2 ⚡+
```
./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/acl-2.3.2
make && make check && make install
```

### 25. libcap-2.77 ⭐
```
sed -i '/install -m.*STA/d' libcap/Makefile
make prefix=/usr lib=lib
make test
make prefix=/usr lib=lib install
```

### 26. libxcrypt-4.5.2 ⚡+
```
sed -i '/strchr/s/const//' lib/crypt-{sm3,gost}-yescrypt.c
./configure --prefix=/usr --enable-hashes=strong,glibc --enable-obsolete-api=no \
  --disable-static --disable-failure-tokens
make && make check && make install
```

### 27. shadow-4.19.3 ⭐
```
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
make && make exec_prefix=/usr install
make -C man install-man
pwconv && grpconv
mkdir -p /etc/default
useradd -D --gid 999
```

### 28. gcc-15.2.0 ⭐
```
sed -i 's/char [*]q/const \&/' libgomp/affinity-fmt.c
case $(uname -m) in x86_64) sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 ;; esac
mkdir -v build && cd build
../configure --prefix=/usr LD=ld --enable-languages=c,c++ \
  --enable-default-pie --enable-default-ssp --enable-host-pie \
  --disable-multilib --disable-bootstrap --disable-fixincludes --with-system-zlib
make
ulimit -s -H unlimited
sed -e '/cpython/d' -i ../gcc/testsuite/gcc.dg/plugin/plugin.exp
chown -R tester . && su tester -c "PATH=$PATH make -k check"
make install
chown -v -R root:root /usr/lib/gcc/$(gcc -dumpmachine)/15.2.0/include{,-fixed}
ln -svr /usr/bin/cpp /usr/lib
ln -sv gcc.1 /usr/share/man/man1/cc.1
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/15.2.0/liblto_plugin.so /usr/lib/bfd-plugins/
# Sanity checks
echo 'int main(){}' | cc -x c - -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'
rm -v a.out dummy.log
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
```

### 29. ncurses-6.6 ⭐
```
./configure --prefix=/usr --mandir=/usr/share/man --with-shared \
  --without-debug --without-normal --with-cxx-shared --enable-pc-files \
  --with-pkg-config-libdir=/usr/lib/pkgconfig
make
make DESTDIR=$PWD/dest install
sed -e 's/^#if.*XOPEN.*$/#if 1/' -i dest/usr/include/curses.h
cp --remove-destination -av dest/* /
for lib in ncurses form panel menu; do
  ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
  ln -sfv ${lib}w.pc /usr/lib/pkgconfig/${lib}.pc
done
ln -sfv libncursesw.so /usr/lib/libcurses.so
cp -v -R doc -T /usr/share/doc/ncurses-6.6
```

### 30. sed-4.9 ⚡
```
./configure --prefix=/usr
make && make html
make check # as tester
make install
install -d -m755 /usr/share/doc/sed-4.9
install -m644 doc/sed.html /usr/share/doc/sed-4.9
```

### 31. psmisc-23.7 ⚡
```
./configure --prefix=/usr
make && make check && make install
```

### 32. gettext-1.0 ⚡+
```
./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/gettext-1.0
make && make check && make install
chmod -v 0755 /usr/lib/preloadable_libintl.so
```

### 33. bison-3.8.2 ⚡+
```
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
make && make check && make install
```

### 34. grep-3.12 ⚡
```
sed -i "s/echo/#echo/" src/egrep.sh
./configure --prefix=/usr
make && make check && make install
```

### 35. bash-5.3 ⚡+
```
./configure --prefix=/usr --without-bash-malloc --with-installed-readline \
  --docdir=/usr/share/doc/bash-5.3
make
make install
exec /usr/bin/bash --login
```

### 36. libtool-2.5.4 ⚡
```
./configure --prefix=/usr
make && make check && make install
rm -fv /usr/lib/libltdl.a
```

### 37. gdbm-1.26 ⚡+
```
./configure --prefix=/usr --disable-static --enable-libgdbm-compat
make && make check && make install
```

### 38. gperf-3.3 ⚡+
```
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.3
make && make check && make install
```

### 39. expat-2.7.4 ⚡+
```
./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/expat-2.7.4
make && make check && make install
```

### 40. inetutils-2.7 ⚡+
```
sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c
./configure --prefix=/usr --bindir=/usr/bin --localstatedir=/var \
  --disable-logger --disable-whois --disable-rcp --disable-rexec \
  --disable-rlogin --disable-rsh --disable-servers
make && make check && make install
mv -v /usr/{,s}bin/ifconfig
```

### 41. less-692 ⚡+
```
./configure --prefix=/usr --sysconfdir=/etc
make && make check && make install
```

### 42. perl-5.42.0 💎
```
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
make && make test_harness && make install
unset BUILD_ZLIB BUILD_BZIP2
```

### 43. XML::Parser-2.47 💎
```
perl Makefile.PL && make && make test && make install
```

### 44. intltool-0.51.0 ⚡
```
sed -i 's:\\\${:\\\$\\{:' intltool-update.in
./configure --prefix=/usr
make && make check && make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
```

### 45. autoconf-2.72 ⚡
```
./configure --prefix=/usr
make && make check && make install
```

### 46. automake-1.18.1 ⚡+
```
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.18.1
make && make -j$(nproc) check && make install
```

### 47. openssl-3.6.1 ⭐
```
./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib shared zlib-dynamic
make && HARNESS_JOBS=$(nproc) make test
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.6.1
```

### 48. libelf (elfutils-0.194) ⭐
```
./configure --prefix=/usr --disable-debuginfod --enable-libdebuginfod=dummy
make -C lib && make -C libelf
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a
```

### 49. libffi-3.5.2 ⚡+
```
./configure --prefix=/usr --disable-static --with-gcc-arch=native
make && make check && make install
```

### 50. sqlite-3510200 ⚡+
```
tar -xf ../sqlite-doc-3510200.tar.xz  # optional
./configure --prefix=/usr --disable-static --enable-fts{4,5} \
  CPPFLAGS="-D SQLITE_ENABLE_COLUMN_METADATA=1 -D SQLITE_ENABLE_UNLOCK_NOTIFY=1 \
            -D SQLITE_ENABLE_DBSTAT_VTAB=1 -D SQLITE_SECURE_DELETE=1"
make LDFLAGS.rpath=""
make install
```

### 51. python-3.14.3 ⭐
```
./configure --prefix=/usr --enable-shared --with-system-expat \
  --enable-optimizations --without-static-libpython
make && make test TESTOPTS="--timeout 120" && make install
cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF
```

### 52. flit-core-3.12.0 🐍
```
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist flit_core
```

### 53. packaging-26.0 🐍
```
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist packaging
```

### 54. wheel-0.46.3 🐍
```
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist wheel
```

### 55. setuptools-82.0.0 🐍
```
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist setuptools
```

### 56. ninja-1.13.2 ⭐
```
sed -i '/int Guess/a \  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc
python3 configure.py --bootstrap --verbose
install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion /usr/share/zsh/site-functions/_ninja
```

### 57. meson-1.10.1 🐍
```
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist meson
install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson
```

### 58. kmod-34.2 🔧
```
mkdir -p build && cd build
meson setup --prefix=/usr .. --buildtype=release -D manpages=false
ninja && ninja install
```

### 59. coreutils-9.10 ⭐
```
patch -Np1 -i ../coreutils-9.10-i18n-1.patch
autoreconf -fv && automake -af
FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr
make && make NON_ROOT_USERNAME=tester check-root
groupadd -g 102 dummy -U tester
chown -R tester .
su tester -c "PATH=$PATH make -k RUN_EXPENSIVE_TESTS=yes check" < /dev/null
groupdel dummy
make install
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8
```

### 60. diffutils-3.12 ⚡
```
./configure --prefix=/usr
make && make check && make install
```

### 61. gawk-5.3.2 ⚡+
```
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr
make && make check && make install
ln -sv gawk.1 /usr/share/man/man1/awk.1
```

### 62. findutils-4.10.0 ⚡+
```
./configure --prefix=/usr --localstatedir=/var/lib/locate
make && make check && make install
```

### 63. groff-1.23.0 ⚡+
```
PAGE=A4 ./configure --prefix=/usr
make && make check && make install
```

### 64. grub-2.14 ⭐
```
unset {C,CPP,CXX,LD}FLAGS
sed 's/--image-base/--nonexist-linker-option/' -i configure
./configure --prefix=/usr --sysconfdir=/etc --disable-efiemu --disable-werror
make && make install
```

### 65. gzip-1.14 ⚡
```
./configure --prefix=/usr
make && make check && make install
```

### 66. iproute2-6.18.0 ⭐
```
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8
make NETNS_RUN_DIR=/run/netns
make SBINDIR=/usr/sbin install
```

### 67. kbd-2.9.0 ⭐
```
patch -Np1 -i ../kbd-2.9.0-backspace-1.patch
sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
./configure --prefix=/usr --disable-vlock
make && make check && make install
```

### 68. libpipeline-1.5.8 ⚡
```
./configure --prefix=/usr
make && make install
```

### 69. make-4.4.1 ⚡
```
./configure --prefix=/usr
make && make check && make install
```

### 70. patch-2.8 ⚡
```
./configure --prefix=/usr
make && make check && make install
```

### 71. tar-1.35 ⚡+
```
FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr
make && make check && make install
make -C doc install-html docdir=/usr/share/doc/tar-1.35
```

### 72. texinfo-7.2 ⚡+
```
sed 's/! $output_file eq/$output_file ne/' -i tp/Texinfo/Convert/*.pm
./configure --prefix=/usr
make && make check && make install
```

### 73. vim-9.2.0078 ⭐
```
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr
make && make install
ln -sv vim /usr/bin/vi
for L in /usr/share/man/{,*/}man1/vim.1; do ln -sv vim.1 $(dirname $L)/vi.1; done
ln -sv ../vim/vim92/doc /usr/share/doc/vim-9.2.0078
# /etc/vimrc config
```

### 74. markupsafe-3.0.3 🐍
```
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist Markupsafe
```

### 75. jinja2-3.1.6 🐍
```
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist Jinja2
```

### 76. systemd-259.1 🔧
```
sed -e 's/GROUP="render"/GROUP="video"/' -e 's/GROUP="sgx", //' \
  -i rules.d/50-udev-default.rules.in
mkdir -p build && cd build
meson setup .. --prefix=/usr --buildtype=release \
  -D default-dnssec=no -D firstboot=false -D install-tests=false \
  -D ldconfig=false -D sysusers=false -D rpmmacrosdir=no \
  -D homed=disabled -D man=disabled -D mode=release \
  -D pamconfdir=no -D dev-kvm-mode=0660 -D nobody-group=nogroup \
  -D sysupdate=disabled -D ukify=disabled
ninja
echo 'NAME="HyperPenguinOS"' > /etc/os-release
unshare -m ninja test
ninja install
tar -xf ../../systemd-man-pages-259.1.tar.xz --no-same-owner --strip-components=1 -C /usr/share/man
systemd-machine-id-setup
systemctl preset-all
```

### 77. dbus-1.16.2 🔧
```
mkdir build && cd build
meson setup --prefix=/usr --buildtype=release --wrap-mode=nofallback ..
ninja && ninja test && ninja install
ln -sfv /etc/machine-id /var/lib/dbus
```

### 78. man-db-2.13.1 ⚡+
```
./configure --prefix=/usr --docdir=/usr/share/doc/man-db-2.13.1 \
  --sysconfdir=/etc --disable-setuid --enable-cache-owner=bin \
  --with-browser=/usr/bin/lynx --with-vgrind=/usr/bin/vgrind --with-grap=/usr/bin/grap
make && make check && make install
```

### 79. procps-ng-4.0.6 ⚡+
```
./configure --prefix=/usr --docdir=/usr/share/doc/procps-ng-4.0.6 \
  --disable-static --disable-kill --enable-watch8bit --with-systemd
make && make check && make install
```

### 80. util-linux-2.41.3 ⚡+
```
./configure --bindir=/usr/bin --libdir=/usr/lib --runstatedir=/run \
  --sbindir=/usr/sbin --disable-chfn-chsh --disable-login --disable-nologin \
  --disable-su --disable-setpriv --disable-runuser --disable-pylibmount \
  --disable-liblastlog2 --disable-static --without-python \
  ADJTIME_PATH=/var/lib/hwclock/adjtime --docdir=/usr/share/doc/util-linux-2.41.3
make && make install
```

### 81. e2fsprogs-1.47.3 ⭐
```
mkdir -v build && cd build
../configure --prefix=/usr --sysconfdir=/etc --enable-elf-shlibs \
  --disable-libblkid --disable-libuuid --disable-uuidd --disable-fsck
make && make check && make install
rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
```

---

## BLFS Extras (post-LFS)

### make-ca-1.14 ⚡+
```
./configure --prefix=/usr --sysconfdir=/etc
make && make install
```

### libunistring-1.2 ⚡+
```
./configure --prefix=/usr --disable-static
make && make install
```

### libidn2-2.3.7 ⚡+
```
./configure --prefix=/usr --disable-static
make && make install
```

### libpsl-0.21.5 ⚡+
```
./configure --prefix=/usr --disable-static
make && make install
```

### libtasn1-4.19.0 ⚡+
```
./configure --prefix=/usr --disable-static
make && make check && make install
```

### p11-kit-0.25.5 ⚡+
```
./configure --prefix=/usr --sysconfdir=/etc --with-trust-paths=/etc/pki/anchors
make && make install
```

### wget-1.25.0 ⚡+
```
./configure --prefix=/usr --sysconfdir=/etc --with-ssl=openssl
make && make install
```

### curl-8.12.0 ⚡+
```
./configure --prefix=/usr --with-ssl --with-ca-path=/etc/ssl/certs
make && make install
```

### git-2.48.0 ⚡+
```
./configure --prefix=/usr --with-curl --with-expat
make && make install
```

### dhcpcd-10.2.0 ⚡+
```
./configure --prefix=/usr --sysconfdir=/etc --dbdir=/var/lib/dhcpcd
make && make install
```

### efivar-39 ⚡+
```
make && make install
```

### efibootmgr-19 ⚡+
```
make && make install
```

---

## Build Time & Space Estimates

| Paquete | SBU | Disco | Build System |
|---------|-----|-------|-------------|
| glibc | 12.0 | 3.5 GB | Special |
| gcc | 45.0 | 6.6 GB | Special |
| coreutils | 1.2 | 188 MB | Special |
| binutils | 1.7 | 835 MB | Special |
| python | 2.6 | 494 MB | Special |
| vim | 3.2 | 217 MB | Autotools+ |
| tcl | 2.9 | 91 MB | Special |
| bison | 2.1 | 63 MB | Autotools+ |
| gettext | 2.1 | 447 MB | Autotools+ |
| systemd | 1.1 | 349 MB | Meson |
| perl | 1.3 | 257 MB | Perl |
| e2fsprogs | 2.4 | 100 MB | Special |
| grub | 0.3 | 202 MB | Special |
| libffi | 1.7 | 10 MB | Autotools+ |
| resto | < 1.0 | < 100 MB | varios |

**Total estimado**: ~80-120 SBU (~20-30 horas en Ryzen 7 7730U con -j16)

## Patches Necesarios (ya descargados)

| Patch | Para |
|-------|------|
| `bzip2-1.0.8-install_docs-1.patch` | bzip2 |
| `coreutils-9.10-i18n-1.patch` | coreutils |
| `expect-5.45.4-gcc15-1.patch` | expect |
| `glibc-fhs-1.patch` | glibc |
| `kbd-2.9.0-backspace-1.patch` | kbd |
| `systemd-man-pages-259.1.tar.xz` | systemd (man pages) |
