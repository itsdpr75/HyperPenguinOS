# Construcción de HyperPenguinOS

## Requisitos del sistema host

- **CPU**: x86-64 (con soporte para al menos x86-64-v2)
- **RAM**: Mínimo 4GB, recomendado 16GB+ (Qt6 necesita mucha RAM para compilar)
- **Disco**: Mínimo 60GB libres (~30GB para sources, ~20GB para rootfs)
- **Sistema**: Cualquier distribución Linux reciente

### Paquetes necesarios

```bash
# Arch Linux / Garuda
sudo pacman -S --needed base-devel bison flex gawk texinfo \
  gzip xz bzip2 make patch perl python3 ninja meson cmake \
  pkg-config chrpath help2man xsltproc go podman qemu-full \
  ccache wget

# Debian / Ubuntu
sudo apt install build-essential bison flex gawk texinfo \
  gzip xz-utils bzip2 make patch perl python3 ninja-build \
  meson cmake pkg-config chrpath help2man xsltproc golang \
  podman qemu-system-x86 ccache wget
```

## Estructura de construcción

```
HyperPenguinOS/
├── config/             # Archivos de configuración del sistema (versionado)
│   └── rootfs/etc/     #  fstab, hostname, locale, network, shells, etc.
├── lfs/                # Directorio de construcción (NO versionado)
│   ├── sources/        # Tarballs descargados (~3-5GB)
│   ├── tools/          # Herramientas temporales (toolchain cruzada)
│   └── rootfs/         # Sistema destino final (rootfs completo)
├── scripts/            # Build scripts (fases 0.5 a 15)
├── kernel/             # Parches CachyOS + configuración del kernel
│   ├── config/         # kernel .config base
│   └── cachyos-patches/# parches misc para 6.18
├── src/                # Submódulos de código fuente
│   ├── hbox/           # https://github.com/itsdpr75/hbox-indev
│   ├── hpk/            # https://github.com/itsdpr75/HPK-indev
│   └── kcm-rollback/   # KCM de snapshots BTRFS (C++/QML)
├── .ccache/            # Caché de compilación ccache (NO versionado)
├── build.sh            # Orquestador de build
└── docs/               # Documentación del proyecto
```

> **Nota:** `lfs/` y `.ccache/` están en `.gitignore` porque contienen
> binarios compilados y tarballs descargados. Para construir desde cero
> solo necesitas clonar el repo + ejecutar `./build.sh`.

## Checkpoints

Cada paquete instalado crea un checkpoint en `/usr/lib/opencode/installed/`
dentro del chroot. Si el build se interrumpe y se reanuda, los paquetes ya
instalados se saltan automáticamente.

## ccache

ccache se integra automáticamente en todos los scripts de compilación
pesada (Qt6, KF6, Plasma, Mesa). La caché persiste en `PROJECT_ROOT/.ccache/`
(10GB máximo). En reintentos, solo se recompilan los archivos modificados.

## Orden de construcción

### Opción 1: Build orquestado

```bash
# Ver fases disponibles
./build.sh list

# Construir todo (toolchain + sistema base + kernel + escritorio + ISO)
./build.sh
```

### Opción 2: Fases individuales

```bash
# 00. Preparación
./scripts/01-download-sources.sh    # ~3-5GB de descargas

# 01. Toolchain (requiere sudo)
sudo ./scripts/02-toolchain.sh

# 02. Sistema base LFS (~6-10 horas)
sudo ./scripts/03-base-system.sh

# 03. Configuración del sistema
sudo ./scripts/00.5-setup-config.sh

# 04. Kernel CachyOS (~2 horas la primera vez)
sudo ./scripts/04-kernel-cachyos.sh

# 05. Sistema A/B BTRFS (scripts de update/rollback)
sudo ./scripts/05-ab-btrfs.sh

# 06. Estructura /user/ (PAM, XDG, skel)
sudo ./scripts/06-user-fs.sh

# 07. Wayland + Mesa (~1-2 horas)
./scripts/07-wayland-mesa.sh

# 08. Qt6 (~6-10 horas, reanudable con checkpoints)
./scripts/08-qt6.sh

# 09. KDE Frameworks 6 (~2-3 horas)
./scripts/09-kf6.sh

# 10. KDE Plasma 6 + SDDM + apps (~2-3 horas)
./scripts/10-plasma-6.sh

# 11-13. Herramientas propias: hpk, hbox, KCM
./scripts/11-build-hpk.sh
./scripts/12-build-hbox.sh
./scripts/13-build-kcm.sh

# 14. Calamares Installer
./scripts/14-calamares.sh

# 15. ISO generada
./scripts/15-build-iso.sh
```

## Reanudar después de un error

Todos los scripts de compilación usan checkpoints. Si el build falla:

```bash
# 1. Corregir el error
# 2. Re-ejecutar el mismo script
./scripts/08-qt6.sh  # solo compila los módulos pendientes
```

Si necesitas reiniciar un módulo específico:

```bash
# Eliminar su checkpoint y re-ejecutar
sudo rm -f /path/to/lfs/rootfs/usr/lib/opencode/installed/qtbase-everywhere-src-6.7.2
./scripts/08-qt6.sh
```

## Pruebas con QEMU

```bash
./scripts/test-vm.sh
# Lanza HyperPenguinOS.iso en una máquina virtual QEMU con KVM
```

## Personalización visual

Después de tener la VM corriendo, ver `docs/ref/plasma-theming.md`.
