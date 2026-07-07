#!/bin/bash

# ============================================================
# Fase 12: Generación de ISO
# Empaqueta el sistema en una ISO booteable con Calamares
# Usa dracut dmsquash-live para initramfs
# ============================================================

source "$(dirname "$0")/00-env.sh"

log_info "=== Generando ISO de HyperPenguinOS ==="

ISO_DIR="$PROJECT_ROOT/iso"
LIVE_DIR="$ISO_DIR/live"
ISO_OUTPUT="$ISO_DIR/hyperpenguin.iso"

# Verificar requisitos
if ! command -v grub-mkrescue &>/dev/null; then
    log_error "grub-mkrescue no encontrado. Instala grub y xorriso."
    exit 1
fi

if ! command -v mksquashfs &>/dev/null; then
    log_error "mksquashfs no encontrado. Instala squashfs-tools."
    exit 1
fi

# Limpiar
rm -rf "$ISO_DIR"
mkdir -pv "$LIVE_DIR"

# 1. Crear squashfs del sistema
log_info "Creando squashfs del rootfs (esto toma varios minutos)..."
mksquashfs "$LFS_ROOTFS" "$LIVE_DIR/rootfs.squashfs" \
    -comp xz \
    -Xbcj x86 \
    -b 1M \
    -no-recovery \
    -no-exports \
    -no-sparse \
    -quiet

SFS_SIZE=$(du -h "$LIVE_DIR/rootfs.squashfs" | cut -f1)
log_success "Squashfs creado: $SFS_SIZE"

# 2. Obtener versión del kernel instalado
KERNEL_FILE=$(ls "$LFS_ROOTFS/boot/vmlinuz-"* 2>/dev/null | head -1)
if [ -z "$KERNEL_FILE" ]; then
    log_error "No se encontró kernel en $LFS_ROOTFS/boot/"
    exit 1
fi

KERNEL_VER=$(basename "$KERNEL_FILE" | sed 's/vmlinuz-//')

# 3. Copiar kernel
cp -v "$KERNEL_FILE" "$LIVE_DIR/vmlinuz"

# 4. Generar initramfs live con dracut
log_info "Generando initramfs live con dracut (dmsquash-live)..."
printf '5906d\n' | sudo -S chroot "$LFS_ROOTFS" /usr/bin/env -i \
    HOME=/root PATH=/usr/bin:/usr/sbin \
    LD_LIBRARY_PATH=/usr/lib64 TMPDIR=/tmp \
    dracut --kver "$KERNEL_VER" \
    --add "dmsquash-live dmsquash-live-autooverlay" \
    --omit "systemd-journald systemd-initrd dracut-systemd" \
    --force "/boot/initramfs-hyperpenguin-live.img" 2>/dev/null || true

if [ -f "$LFS_ROOTFS/boot/initramfs-hyperpenguin-live.img" ]; then
    cp -v "$LFS_ROOTFS/boot/initramfs-hyperpenguin-live.img" "$LIVE_DIR/initramfs.img"
    log_success "Initramfs live generado"
else
    log_warning "No se pudo generar initramfs con dracut, creando uno mínimo..."
    # Initramfs mínimo como fallback
    mkdir -p /tmp/live-initramfs/{bin,dev,etc,lib,mnt,sbin,proc,sys}
    cat > /tmp/live-initramfs/init << 'EOF'
#!/bin/bash

mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

echo "HyperPenguinOS Live - Montando squashfs..."
modprobe loop
modprobe squashfs

mkdir -p /run/archiso/bootmnt
mount -t squashfs -o loop /live/rootfs.squashfs /run/archiso/bootmnt 2>/dev/null || \
mount -t squashfs -o loop /run/archiso/bootmnt/live/rootfs.squashfs /run/archiso/bootmnt 2>/dev/null || true

# Overlay para escritura
mount -t tmpfs tmpfs /run/archiso/bootmnt/run
mount -t tmpfs tmpfs /run/archiso/bootmnt/tmp

exec /run/archiso/bootmnt/sbin/init
EOF
    chmod +x /tmp/live-initramfs/init

    cd /tmp/live-initramfs
    find . -print0 | cpio -0 -H newc -o | gzip -9 > "$LIVE_DIR/initramfs.img"
    rm -rf /tmp/live-initramfs
    log_success "Initramfs mínimo creado como fallback"
fi

# 5. Configurar GRUB para la ISO
GRUB_DIR="$ISO_DIR/boot/grub"
mkdir -pv "$GRUB_DIR"

cat > "$GRUB_DIR/grub.cfg" << 'EOF'
set default="HyperPenguinOS Live"
set timeout=30

insmod all_video
insmod gfxterm
insmod font
insmod png

set gfxmode=1920x1080
set gfxpayload=keep

terminal_output gfxterm

menuentry "HyperPenguinOS Live" {
    linux /live/vmlinuz archisobasedir=live archisodevice=/dev/sr0 quiet splash
    initrd /live/initramfs.img
}

menuentry "HyperPenguinOS Live (Safe Mode)" {
    linux /live/vmlinuz archisobasedir=live archisodevice=/dev/sr0 nomodeset
    initrd /live/initramfs.img
}

menuentry "Boot from first disk" {
    insmod chain
    insmod ext2
    set root=(hd1,1)
    chainloader +1
}
EOF

# 6. Generar ISO con GRUB (UEFI + BIOS)
log_info "Generando imagen ISO con grub-mkrescue..."
grub-mkrescue -o "$ISO_OUTPUT" "$ISO_DIR" \
    --fonts=unicode \
    --locales=es \
    --themes=starfield \
    --install-modules="linux all_video gfxterm font png chain ext2 btrfs squash4 loopback iso9660"

if [ -f "$ISO_OUTPUT" ]; then
    ISO_SIZE=$(du -h "$ISO_OUTPUT" | cut -f1)
    log_success "ISO generada: $ISO_OUTPUT ($ISO_SIZE)"
else
    log_error "Error generando la ISO"
    exit 1
fi

log_info "Para probar la ISO:"
echo "  qemu-system-x86_64 -cdrom $ISO_OUTPUT -m 4096 -enable-kvm"
