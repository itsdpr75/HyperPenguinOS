# Sistema inmutable A/B BTRFS

## Concepto

HyperPenguinOS usa un sistema de particiones A/B similar a Android y ChromeOS.
Hay dos conjuntos de subvolúmenes del sistema: A (activo) y B (inactivo).
Las actualizaciones se aplican en la partición inactiva, y en el siguiente
boot se intercambian los roles.

## Layout de disco

```
/dev/sda
├── sda1: EFI System Partition (vfat, 512MB)
├── sda2: BTRFS pool (resto del disco)
│   ├── @rootfs-A   → /        (read-only)
│   ├── @rootfs-B   → /        (read-only, inactivo)
│   ├── @etc        → /etc     (read-write)
│   ├── @var        → /var     (read-write)
│   ├── @user       → /user    (read-write)
│   └── @snapshots  → /.snapshots
```

## Cómo funciona

### Boot normal

1. GRUB lee la variable `hyperpenguin_active_partition` de la ESP
2. Monta `@rootfs-A` como `/` (read-only)
3. Monta overlay tmpfs sobre `/etc`, `/var` para partes mutables temporales
4. systemd monta los subvolúmenes finales (`@etc`, `@var`, `@user`)
5. El sistema arranca normalmente

### Actualización

1. `penguin-update` descarga la nueva imagen del sistema
2. Extrae la imagen en el subvolumen inactivo (ej: `@rootfs-B`)
3. Actualiza la variable de GRUB: `hyperpenguin_active_partition=B`
4. Crea un snapshot BTRFS de `@etc` antes de migrar configuraciones
5. Reinicia
6. Si el boot falla (kernel panic, systemd crash), GRUB detecta el fallo
   y revierte `hyperpenguin_active_partition` al valor anterior

### Rollback

Desde el KCM de System Settings:
1. El KCM lista los snapshots disponibles de `@rootfs`, `@etc`
2. El usuario selecciona un snapshot
3. Se restaura el subvolumen desde el snapshot
4. Se reinicia

## Scripts del sistema

### penguin-update
```bash
#!/bin/bash
# Descarga y aplica una actualización del sistema
TARGET=$(get_inactive_partition)
wget https://updates.hyperpenguin.os/latest.img -O /tmp/update.img
mkfs.btrfs --rootdir /tmp/update.img /dev/mapper/$TARGET
update-grub
reboot
```

### penguin-rollback
```bash
#!/bin/bash
# CLI básico para rollback
LISTA=$(btrfs subvolume list /.snapshots)
echo "Snapshots disponibles:"
echo "$LISTA"
read -p "ID a restaurar: " ID
btrfs subvolume snapshot /.snapshots/$ID /@rootfs
echo "Reinicia para aplicar cambios."
```

## Consideraciones de seguridad

- `/usr` y `/` son read-only: ni malware ni errores de usuario pueden modificarlos
- `/etc` es snapshoteable: cualquier cambio dañino se puede revertir
- Las actualizaciones son atómicas: o funcionan completamente o no se aplican
- El bootloader tiene fallback: el sistema siempre puede arrancar
