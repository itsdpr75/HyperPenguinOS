# Arquitectura del sistema

## Capas

```
┌─────────────────────────────────────┐
│  KDE Plasma 6 (Wayland)             │  Escritorio
│  SDDM, KWin, System Settings, KCM   │
├─────────────────────────────────────┤
│  hpk  │  hbox  │  Flatpak/AppImage  │  Gestión de apps
├─────────────────────────────────────┤
│  systemd  │  udev  │  D-Bus         │  Init y servicios
├─────────────────────────────────────┤
│  Kernel CachyOS (BORE, x86-64-v3)   │  Kernel
├─────────────────────────────────────┤
│  BTRFS (A/B, snapshots, compresión) │  Sistema de archivos
└─────────────────────────────────────┘
```

## Particionamiento

| Subvolumen | Punto de montaje | Tipo | Propósito |
|---|---|---|---|
| @rootfs-A | / | ro | Sistema activo |
| @rootfs-B | / | ro | Sistema inactivo (backup) |
| @etc | /etc | rw | Configuración del sistema (snapshoteable) |
| @var | /var | rw | Logs, caches, temporales |
| @user | /user | rw | Datos de usuarios |
| @snapshots | /.snapshots | rw | Snapshots BTRFS |
| ESP | /boot/efi | rw | Bootloader UEFI |

## Inmutabilidad

- `/usr` y `/` son de solo lectura en runtime
- `/etc` es mutable pero en subvolumen separado con snapshots
- Las actualizaciones escriben una nueva imagen en la partición inactiva
- GRUB tiene soporte de fallback: si la partición activa falla al bootear, cambia automáticamente a la otra

## Flujo de actualización

1. `penguin-update` descarga la nueva imagen del sistema
2. Escribe la imagen en la partición inactiva (B si A está activa, o viceversa)
3. Actualiza la configuración de GRUB
4. Reinicia el sistema
5. Si el boot falla, GRUB revierte automáticamente a la partición anterior

## Estructura de directorios

| Ruta tradicional | HyperPenguinOS |
|---|---|
| /home/{user} | /user/{user}/ |
| ~/.config/ | /user/{user}/config/ |
| ~/Descargas, Documentos... | /user/{user}/home/ |
| ~/.local/share/flatpak/ | /user/{user}/apps/flatpak/ |
| AppImages | /user/{user}/apps/appimages/ |
| /opt/ | Eliminado |
