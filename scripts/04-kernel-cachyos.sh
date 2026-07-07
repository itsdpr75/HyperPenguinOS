#!/bin/bash

# ============================================================
# Fase 3: Kernel CachyOS
# Descarga, parchea y compila el kernel con optimizaciones
# Genera initramfs con dracut
# ============================================================

source "$(dirname "$0")/00-env.sh"

log_info "=== Iniciando construcción del kernel CachyOS ==="

# Verificar que cpio esté disponible para dracut (dentro del chroot)
if [ ! -x "$LFS_ROOTFS/usr/bin/cpio" ]; then
    log_info "Copiando cpio al chroot (necesario para dracut)..."
    cp /usr/bin/cpio "$LFS_ROOTFS/usr/bin/cpio"
fi

KERNEL_DIR="$LFS/build/linux-$KERNEL_VERSION"

# Extraer fuente del kernel
if [ ! -d "$KERNEL_DIR" ]; then
    tar -xf "$LFS_SOURCES/linux-${KERNEL_VERSION}.tar.xz" -C "$LFS/build"
fi
cd "$KERNEL_DIR"

# Aplicar parches CachyOS (misc compatibles con 6.18.37)
log_info "Aplicando parches CachyOS..."
for patch in $(find "$KERNEL_PATCHES_DIR/6.18/misc" -name '*.patch' -type f | sort); do
    base=$(basename "$patch")
    case "$base" in
        0001-hardened.patch|poc-selector.patch|reflex-governor.patch)
            log_info "  Saltando: $base (incompatible con 6.18.37)"
            ;;
        *)
            log_info "  Aplicando: ${patch#$KERNEL_PATCHES_DIR/}"
            patch -p1 < "$patch" 2>/dev/null || log_warning "Fallo: ${patch#$KERNEL_PATCHES_DIR/}"
            ;;
    esac
done
log_info "  Scheduler patches omitidos: incompatibles con 6.18.37"

# Copiar configuración personalizada
mkdir -p "$LFS_ROOTFS/boot" "$LFS_ROOTFS/var/tmp"
if [ -f "$KERNEL_CONFIG_DIR/.config" ]; then
    cp -v "$KERNEL_CONFIG_DIR/.config" .config
    make olddefconfig
else
    log_info "Generando configuración base optimizada para AMD Ryzen..."
    make defconfig
    # Activar opciones esenciales para HyperPenguinOS
    ./scripts/config --enable CONFIG_BTRFS_FS
    ./scripts/config --enable CONFIG_BTRFS_FS_POSIX_ACL
    ./scripts/config --enable CONFIG_OVERLAY_FS
    ./scripts/config --enable CONFIG_NAMESPACES
    ./scripts/config --enable CONFIG_CGROUPS
    ./scripts/config --enable CONFIG_USER_NS
    ./scripts/config --enable CONFIG_VETH
    ./scripts/config --enable CONFIG_BRIDGE
    ./scripts/config --enable CONFIG_NETFILTER
    ./scripts/config --enable CONFIG_NF_NAT
    ./scripts/config --enable CONFIG_NF_CONNTRACK
    ./scripts/config --enable CONFIG_DRM_AMDGPU
    ./scripts/config --enable CONFIG_DRM_AMDGPU_USERPTR
    ./scripts/config --enable CONFIG_DRM_KMS_HELPER
    ./scripts/config --enable CONFIG_DRM_FBDEV_EMULATION
    ./scripts/config --enable CONFIG_SND_HDA_INTEL
    ./scripts/config --enable CONFIG_SND_HDA_CODEC_HDMI
    ./scripts/config --enable CONFIG_SND_HDA_CODEC_REALTEK
    ./scripts/config --enable CONFIG_SND_USB_AUDIO
    ./scripts/config --enable CONFIG_BPF
    ./scripts/config --enable CONFIG_BPF_SYSCALL
    ./scripts/config --enable CONFIG_IMA
    ./scripts/config --enable CONFIG_DM_VERITY
    ./scripts/config --enable CONFIG_EFI
    ./scripts/config --enable CONFIG_EFI_STUB
    ./scripts/config --enable CONFIG_EFIVAR_FS
    ./scripts/config --enable CONFIG_TCG_TPM
    ./scripts/config --enable CONFIG_KVM
    ./scripts/config --enable CONFIG_KVM_AMD
    ./scripts/config --enable CONFIG_VIRTIO
    ./scripts/config --enable CONFIG_VIRTIO_NET
    ./scripts/config --enable CONFIG_VIRTIO_BLK
    ./scripts/config --enable CONFIG_9P_FS
    ./scripts/config --enable CONFIG_9P_FS_POSIX_ACL
    ./scripts/config --enable CONFIG_NET_9P
    ./scripts/config --enable CONFIG_NET_9P_VIRTIO
    ./scripts/config --enable CONFIG_SQUASHFS
    ./scripts/config --enable CONFIG_SQUASHFS_XZ
    ./scripts/config --enable CONFIG_SQUASHFS_ZSTD
    ./scripts/config --enable CONFIG_UNICODE
    ./scripts/config --enable CONFIG_CRYPTO_LZO
    ./scripts/config --enable CONFIG_CRYPTO_LZ4
    ./scripts/config --enable CONFIG_CRYPTO_ZSTD
    ./scripts/config --enable CONFIG_CRYPTO_LZ4HC
    # Optimizaciones CachyOS
    ./scripts/config --set-val CONFIG_LOCALVERSION "\"-hyperpenguin-cachyos\""
    ./scripts/config --set-val CONFIG_HZ 1000
fi

# Optimizaciones para x86-64-v3
export CFLAGS="-march=x86-64-v3 -O3 -pipe"
export CXXFLAGS="$CFLAGS"

# Compilar kernel
log_info "Compilando kernel (esto toma tiempo)..."
make $MAKEFLAGS bzImage
make $MAKEFLAGS modules

# Instalar módulos (usar sudo si hay sesión activa)
if command -v sudo &>/dev/null && sudo -n true 2>/dev/null; then
    sudo make modules_install INSTALL_MOD_PATH="$LFS_ROOTFS" 2>/dev/null || true
fi

# Copiar kernel al rootfs
cp -v arch/x86_64/boot/bzImage "$LFS_ROOTFS/boot/vmlinuz-$KERNEL_VERSION-hyperpenguin-cachyos"

# Instalar kernel headers
make headers_install INSTALL_HDR_PATH="$LFS_ROOTFS/usr"

# Generar initramfs con dracut
log_info "Generando initramfs con dracut..."
chroot "$LFS_ROOTFS" /usr/bin/env -i HOME=/root PATH=/usr/bin:/usr/sbin \
    LD_LIBRARY_PATH=/usr/lib64 TMPDIR=/tmp \
    dracut --kver "$KERNEL_VERSION-hyperpenguin-cachyos" \
    --force /boot/initramfs-$KERNEL_VERSION.img \
    --omit "systemd-journald systemd-initrd dracut-systemd"

cd "$LFS"
log_success "Kernel CachyOS compilado e instalado"
echo "  Kernel: vmlinuz-$KERNEL_VERSION-hyperpenguin-cachyos"
echo "  Initramfs: initramfs-$KERNEL_VERSION.img"
echo "  Config: $KERNEL_CONFIG_DIR/.config"
