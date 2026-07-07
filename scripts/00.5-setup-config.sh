#!/bin/bash

# ============================================================
# 00.5-setup-config.sh — Configuración del sistema base
# Copia archivos de configuración al rootfs del sistema,
# genera locales y establece la zona horaria.
# Debe ejecutarse después de 03-base-system.sh
# ============================================================

source "$(dirname "$0")/00-env.sh"

log_info "=== Configurando sistema base HyperPenguinOS ==="

CONFIG_SRC="$(cd "$(dirname "$0")/.." && pwd)/config/rootfs"

# Verificar que el rootfs existe
if [ ! -d "$LFS_ROOTFS" ]; then
    log_error "Rootfs no encontrado: $LFS_ROOTFS"
    log_error "Ejecuta primero 03-base-system.sh"
    exit 1
fi

# Copiar archivos de configuración
log_info "Copiando archivos de configuración al rootfs..."
mkdir -pv "$LFS_ROOTFS/etc"
for f in "$CONFIG_SRC"/etc/*; do
    if [ -f "$f" ]; then
        cp -v "$f" "$LFS_ROOTFS/etc/"
    fi
done

# Red network systemd
if [ -d "$CONFIG_SRC/etc/systemd" ]; then
    cp -rv "$CONFIG_SRC/etc/systemd" "$LFS_ROOTFS/etc/"
fi

# Establecer zona horaria (por defecto Europe/Madrid)
TZ="${TZ:-Europe/Madrid}"
if [ -f "$LFS_ROOTFS/usr/share/zoneinfo/$TZ" ]; then
    ln -sf "/usr/share/zoneinfo/$TZ" "$LFS_ROOTFS/etc/localtime"
    log_info "Zona horaria: $TZ"
else
    log_warning "Zona horaria $TZ no encontrada en rootfs, saltando"
fi

# Generar locales
log_info "Generando locales..."
if [ -x "$LFS_ROOTFS/usr/bin/localedef" ]; then
    chroot "$LFS_ROOTFS" /usr/bin/env -i PATH=/usr/bin:/usr/sbin \
        localedef -i en_US -f UTF-8 en_US.UTF-8 2>/dev/null || true
    chroot "$LFS_ROOTFS" /usr/bin/env -i PATH=/usr/bin:/usr/sbin \
        localedef -i es_ES -f UTF-8 es_ES.UTF-8 2>/dev/null || true
    log_success "Locales generados"
else
    log_warning "localedef no encontrado en rootfs, los locales se generarán más tarde"
fi

log_success "Configuración del sistema base completada"
