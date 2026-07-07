#!/bin/bash

# ============================================================
# Fase 4: Sistema Inmutable A/B BTRFS
# Scripts de actualización atómica y rollback
# ============================================================

source "$(dirname "$0")/00-env.sh"

log_info "=== Configurando sistema A/B BTRFS ==="

if [ ! -d "$LFS_ROOTFS/usr/sbin" ]; then
    mkdir -pv "$LFS_ROOTFS/usr/sbin"
fi

# Script de actualización atómica A/B
cat > "$LFS_ROOTFS/usr/sbin/penguin-update" << 'SCRIPT'
#!/bin/bash

HYPERPENGUIN_UPDATE_URL="https://updates.hyperpenguin.os/stable"

# Detectar partición activa e inactiva
ACTIVE=$(findmnt -n -o OPTIONS / | grep -oP '@rootfs-\K[AB]')
if [ "$ACTIVE" = "A" ]; then
    INACTIVE="B"
else
    INACTIVE="A"
fi

echo "HyperPenguinOS Update"
echo "  Partición activa: @rootfs-$ACTIVE"
echo "  Partición objetivo: @rootfs-$INACTIVE"
echo ""

# Descargar imagen de actualización
echo "Descargando actualización..."
wget "$HYPERPENGUIN_UPDATE_URL/rootfs-$INACTIVE.img" -O /tmp/update.img
wget "$HYPERPENGUIN_UPDATE_URL/rootfs-$INACTIVE.img.sha256" -O /tmp/update.img.sha256

# Validar checksum
echo "Verificando integridad..."
sha256sum -c /tmp/update.img.sha256 || {
    echo "ERROR: Checksum inválido"
    rm -f /tmp/update.img /tmp/update.img.sha256
    exit 1
}

# Aplicar actualización
echo "Aplicando actualización a @rootfs-$INACTIVE..."
btrfs receive -f /tmp/update.img "/mnt/system-$INACTIVE"

# Actualizar GRUB para que arranque la nueva partición
echo "Actualizando bootloader..."
grub-reboot "HyperPenguinOS ($INACTIVE)"
grub-set-default "HyperPenguinOS ($ACTIVE)"

echo "Actualización aplicada. Reinicia para activar."
echo ""
echo "Para hacer rollback durante el boot:"
echo "  Mantén Shift durante el arranque y selecciona la otra entrada en GRUB"
SCRIPT

# Script de rollback CLI
cat > "$LFS_ROOTFS/usr/sbin/penguin-rollback" << 'SCRIPT'
#!/bin/bash

echo "HyperPenguinOS Rollback"
echo "======================"

# Listar snapshots
echo ""
echo "Snapshots BTRFS disponibles:"
echo "---------------------------"
btrfs subvolume list -s / | awk '{print "ID: " $2 "  Path: " $NF}'

echo ""
read -p "ID del snapshot a restaurar: " SNAP_ID

SNAP_PATH=$(btrfs subvolume list -s / | awk -v id="$SNAP_ID" '$2 == id {print $NF}')

if [ -z "$SNAP_PATH" ]; then
    echo "ERROR: Snapshot ID $SNAP_ID no encontrado"
    exit 1
fi

echo "Restaurando snapshot: $SNAP_PATH"
echo "Se creará un backup del estado actual antes de restaurar."

# Backup del estado actual
BACKUP_NAME="pre-rollback-$(date +%Y%m%d-%H%M%S)"
ACTIVE=$(findmnt -n -o OPTIONS / | grep -oP '@rootfs-\K[AB]')
btrfs subvolume snapshot "/" "@snapshots/$BACKUP_NAME"

# Restaurar snapshot sobre la partición activa
btrfs subvolume delete "/@rootfs-$ACTIVE"
btrfs subvolume snapshot "/$SNAP_PATH" "/@rootfs-$ACTIVE"

echo ""
echo "Rollback completado."
echo "Snapshot actual respaldado en: @snapshots/$BACKUP_NAME"
echo "Reinicia el sistema para aplicar los cambios."
SCRIPT

# Script de servicio de first-boot para sistema inmutable
cat > "$LFS_ROOTFS/usr/lib/systemd/system/penguin-firstboot.service" << 'SERVICE'
[Unit]
Description=HyperPenguinOS First Boot Setup
ConditionPathExists=!/var/lib/hyperpenguin/firstboot-done
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/penguin-firstboot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE

cat > "$LFS_ROOTFS/usr/sbin/penguin-firstboot" << 'SCRIPT'
#!/bin/bash

# Configuración inicial después de instalación/actualización
FIRSTBOOT_FLAG="/var/lib/hyperpenguin/firstboot-done"

mkdir -pv /var/lib/hyperpenguin

echo "HyperPenguinOS - Primera configuración"

# Crear snapshot inicial del sistema
echo "Creando snapshot inicial..."
btrfs subvolume snapshot -r / "@snapshots/initial-install"

# Configurar hostname
echo "penguin" > /etc/hostname

# Configurar locales
locale-gen
echo "LANG=es_ES.UTF-8" > /etc/locale.conf

# Configurar GRUB para soporte A/B
grub-install --target=x86_64-efi --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg

touch "$FIRSTBOOT_FLAG"
echo "Configuración inicial completada."
SCRIPT

chmod +x "$LFS_ROOTFS/usr/sbin/penguin-update"
chmod +x "$LFS_ROOTFS/usr/sbin/penguin-rollback"
chmod +x "$LFS_ROOTFS/usr/sbin/penguin-firstboot"

# Habilitar servicio de first-boot
ln -sf /usr/lib/systemd/system/penguin-firstboot.service \
    "$LFS_ROOTFS/usr/lib/systemd/system/multi-user.target.wants/" 2>/dev/null || true

log_success "Sistema A/B BTRFS configurado"
echo "  Scripts instalados en /usr/sbin/:"
echo "    - penguin-update   : Actualización atómica"
echo "    - penguin-rollback : Rollback CLI"
echo "    - penguin-firstboot: Configuración inicial"
