# Estructura de archivos /user/

## Motivación

El Filesystem Hierarchy Standard (FHS) tradicional tiene décadas de antigüedad y
dispersa los datos del usuario entre `/home/`, `~/.local/`, `~/.config/`, `/opt/`, etc.
HyperPenguinOS unifica todo lo del usuario bajo `/user/{username}/`.

## Estructura

```
/user/
└── {username}/
    ├── config/              # Configuración del usuario (XDG_CONFIG_HOME)
    │   ├── plasma-workspace/
    │   ├── kwinrc
    │   ├── kdeglobals
    │   └── ...
    ├── home/                # Documentos, proyectos, descargas, imágenes...
    │   ├── Documentos/
    │   ├── Descargas/
    │   ├── Imágenes/
    │   ├── Música/
    │   ├── Vídeos/
    │   ├── Proyectos/
    │   └── ...
    └── apps/                # Aplicaciones del usuario
        ├── appimages/       # AppImages instaladas
        │   ├── firefox.AppImage
        │   └── ...
        ├── flatpak/         # Runtimes y apps Flatpak
        ├── linyaps/         # Aplicaciones Linyaps (玲珑)
        └── boxes/           # Contenedores cross-distro
            ├── ubuntu/      # Contenedor Ubuntu
            │   ├── rootfs/  # Sistema de archivos del contenedor
            │   └── apps/    # .desktop files generados
            ├── fedora/      # Contenedor Fedora
            └── registry.json # Registro global de apps en contenedores
```

## Variables de entorno (configuración en /etc/profile.d/hyperpenguin.sh)

```bash
export XDG_CONFIG_HOME=/user/${USER}/config
export XDG_DATA_HOME=/user/${USER}/apps
export XDG_DOCUMENTS_DIR=/user/${USER}/home/Documentos
export XDG_DOWNLOAD_DIR=/user/${USER}/home/Descargas
export XDG_PICTURES_DIR=/user/${USER}/home/Imágenes
export XDG_MUSIC_DIR=/user/${USER}/home/Música
export XDG_VIDEOS_DIR=/user/${USER}/home/Vídeos
export HOME=/user/${USER}
export APPS_DIR=/user/${USER}/apps
```

## Configuración PAM

```
/etc/pam.d/system-auth:
auth       required   pam_unix.so
account    required   pam_unix.so
password   required   pam_unix.so sha512 shadow
session    required   pam_unix.so
session    optional   pam_mkhomedir.so skel=/etc/skel umask=077
```

## /etc/skel/

Cuando se crea un usuario nuevo, se copia `/etc/skel/` a `/user/{nuevo-user}/`:

```
/etc/skel/
├── config/
│   ├── kdeglobals
│   ├── kwinrc
│   ├── plasmarc
│   └── ...
├── home/
│   ├── Documentos/
│   ├── Descargas/
│   ├── Imágenes/
│   ├── Música/
│   └── Vídeos/
└── apps/
    ├── appimages/
    ├── flatpak/
    ├── linyaps/
    └── boxes/
```

## Beneficios

1. **Limpieza**: Todo lo del usuario está en un solo lugar
2. **Backups**: Un solo rsync de `/user/{username}/` respalda todo
3. **Permisos**: Fácil control de cuotas y permisos por subvolumen
4. **Snapshots**: Snapshots BTRFS a nivel de usuario
5. **Migración**: Mover un usuario a otra máquina es copiar su directorio
