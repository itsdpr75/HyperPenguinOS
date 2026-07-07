#!/bin/bash

# ============================================================
# Lanza HyperPenguinOS en QEMU para testing
# ============================================================

source "$(dirname "$0")/00-env.sh"

ISO_PATH="$PROJECT_ROOT/iso/hyperpenguin.iso"

if [ ! -f "$ISO_PATH" ]; then
    log_error "ISO no encontrada en $ISO_PATH"
    log_info "Ejecuta primero 15-build-iso.sh"
    exit 1
fi

MEM=${VM_MEMORY:-4096}
CPUS=${VM_CPUS:-4}

log_info "Iniciando HyperPenguinOS en QEMU..."
log_info "  ISO: $ISO_PATH"
log_info "  RAM: ${MEM}M"
log_info "  CPUs: $CPUS"
log_info ""

qemu-system-x86_64 \
    -enable-kvm \
    -cpu host \
    -smp $CPUS \
    -m $MEM \
    -drive file="$ISO_PATH",format=raw,media=cdrom \
    -virtfs local,path="$PWD/packages",security_model=passthrough,mount_tag=packages \
    -virtfs local,path="$PWD/src",security_model=passthrough,mount_tag=src \
    -display gtk,gl=on \
    -vga virtio \
    -soundhw hda \
    -device virtio-net,netdev=net0 \
    -netdev user,id=net0 \
    -usb \
    -device usb-tablet \
    -audiodev pa,id=snd0 \
    "$@"
