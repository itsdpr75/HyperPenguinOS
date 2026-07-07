# HyperPenguinOS — Plan Completo de Construcción

## Visión General

HyperPenguinOS es una distribución Linux inmutable construida desde LFS puro con:
- **Kernel CachyOS** (parches misc, x86-64-v3)
- **KDE Plasma 6 sobre Wayland** (sin X11 legacy)
- **Sistema de archivos A/B BTRFS** (actualizaciones atómicas con rollback)
- **Estructura `/user/{usuario}/`** (config/, home/, apps/)
- **Sin gestor de paquetes nativo**: solo AppImage, Flatpak, Linyaps (vía `hpk`)
- **Contenedores cross-distro**: Podman rootless (vía `hbox`)
- **Instalador Calamares** con módulos custom
- **Licencia**: AGPL-3.0

---

## Entorno de Build

| Item | Valor |
|---|---|
| **Host** | Garuda Linux (Arch-based) |
| **CPU** | AMD Ryzen 7 7730U, 16 cores |
| **RAM** | 14 GB |
| **GCC host** | 16.1.1 |
| **Go** | 1.26.4 |
| **MAKEFLAGS** | -j16 |

---

## Fases de Construcción (15 scripts)

### Fase 0: Preparación
| Script | Estado | Descripción |
|--------|--------|-------------|
| `00-env.sh` | ✅ | Variables de entorno, ccache, checkpoints, helpers cmake/meson |
| `01-download-sources.sh` | ✅ | ~82 paquetes LFS + kernel 6.18.37 + parches CachyOS + Qt6/KF6/Plasma/Mesa/Calamares |

### Fase 1: Toolchain Cruzada
| Script | Estado | Descripción |
|--------|--------|-------------|
| `02-toolchain.sh` | ✅ | binutils → gcc-pass1 → glibc → libstdc++ → gcc-pass2 |

### Fase 2: Sistema Base LFS
| Script | Estado | Descripción |
|--------|--------|-------------|
| `03-base-system.sh` | ✅ | 83 paquetes LFS en chroot con checkpoints (man-pages, glibc, zlib, gcc, bash, systemd, dbus, btrfs-progs, dracut, e2fsprogs, kmod, etc.) |

### Fase 3: Kernel CachyOS
| Script | Estado | Descripción |
|--------|--------|-------------|
| `04-kernel-cachyos.sh` | ✅ | Kernel 6.18.37 con parches CachyOS misc (sin BORE/hardened/nvidia). vmlinuz + dracut initramfs instalados en rootfs. |

### Fase 4: Sistema Inmutable A/B
| Script | Estado | Descripción |
|--------|--------|-------------|
| `05-ab-btrfs.sh` | ✅ | Scripts: `penguin-update`, `penguin-rollback`, `penguin-firstboot` + systemd service |

### Fase 5: Sistema de Archivos /user/
| Script | Estado | Descripción |
|--------|--------|-------------|
| `06-user-fs.sh` | ✅ | Variables XDG → `/user/{user}/`, PAM (mkhomedir), /etc/skel (config/, home/, apps/), useradd defaults |

### Fase 6: Wayland + Mesa + Gráficos
| Script | Estado | Descripción |
|--------|--------|-------------|
| `07-wayland-mesa.sh` | ⬜ | libdrm, wayland, wayland-protocols, libxkbcommon, Mesa (radeonsi + swrast + vulkan amd + llvm, solo Wayland), libinput. **Sin XWayland.** |

### Fase 7: Qt6
| Script | Estado | Descripción |
|--------|--------|-------------|
| `08-qt6.sh` | ⬜ | 13 módulos Qt 6.7.2 con checkpoints + ccache (qtbase, qtdeclarative, qtshadertools, qtquick3d, qtwayland, qtsvg, qtimageformats, qt5compat, qtmultimedia, qttools, qttranslations, qtwebsockets, qthttpserver) |

### Fase 8: KDE Frameworks 6
| Script | Estado | Descripción |
|--------|--------|-------------|
| `09-kf6.sh` | ⬜ | ~45 módulos KF6 en 3 tiers con checkpoints + ccache. **Sin khtml (deprecado en KF6).** |

### Fase 9: KDE Plasma 6
| Script | Estado | Descripción |
|--------|--------|-------------|
| `10-plasma-6.sh` | ⬜ | 21 módulos Plasma + 3 apps KDE (dolphin, konsole, kate). SDDM Wayland. Red vía systemd-networkd. **Sin bluedevil, sin plasma-nm.** |

### Fase 10: hpk (HyperPenguin Kommander)
| Script | Estado | Descripción |
|--------|--------|-------------|
| `11-build-hpk.sh` | ✅ | Submodule `src/hpk` (Go). Compila y copia a rootfs. |

### Fase 11: hbox (Cross-Distro Containers)
| Script | Estado | Descripción |
|--------|--------|-------------|
| `12-build-hbox.sh` | ✅ | Submodule `src/hbox` (Go). Compila y copia a rootfs. |

### Fase 12: KCM Rollback
| Script | Estado | Descripción |
|--------|--------|-------------|
| `13-build-kcm.sh` | ✅ | Fuente en `src/kcm-rollback/`. cmake + install con ccache. |

### Fase 13: Calamares Installer
| Script | Estado | Descripción |
|--------|--------|-------------|
| `14-calamares.sh` | ⬜ | yaml-cpp + kpmcore + Calamares con checkpoints y ccache. Boost copiado del host. Módulos custom: partition-hyperpenguin, users-hyperpenguin, bootloader-hyperpenguin. |

### Fase 14: ISO Generation
| Script | Estado | Descripción |
|--------|--------|-------------|
| `15-build-iso.sh` | ⬜ | Squashfs rootfs + initramfs live con dracut dmsquash-live + GRUB BIOS/UEFI + grub-mkrescue |

### Testing
| Script | Estado | Descripción |
|--------|--------|-------------|
| `test-vm.sh` | ✅ | Lanzador QEMU con KVM |

---

## Arquitectura del Sistema

### Capas

```
+-------------------------------------------+
|  KDE Plasma 6 (Wayland)                   |
|  SDDM, KWin, System Settings, KCM         |
+-------------------------------------------+
|  hpk  |  hbox  |  Flatpak / AppImage      |
+-------------------------------------------+
|  systemd  |  udev  |  D-Bus               |
+-------------------------------------------+
|  Kernel CachyOS (x86-64-v3)               |
+-------------------------------------------+
|  BTRFS (A/B, snapshots, compresión)       |
+-------------------------------------------+
```

### Particionamiento A/B

| Subvolumen | Mount | Tipo | Propósito |
|---|---|---|---|
| @rootfs-A | / | ro | Sistema activo |
| @rootfs-B | / | ro | Sistema inactivo (backup) |
| @etc | /etc | rw | Configuración (snapshottable) |
| @var | /var | rw | Logs, cachés, datos variables |
| @user | /user | rw | Datos de usuario |
| @snapshots | /.snapshots | rw | Snapshots BTRFS |
| ESP | /boot/efi | rw | Bootloader UEFI |

---

## Checkpoints y ccache

Todos los scripts de compilación pesada (07-10, 14) usan:

- **Checkpoints**: Cada módulo instala un marcador en `/usr/lib/opencode/installed/`. Si el build falla, al reanudar los módulos exitosos se saltan.
- **ccache**: Compilador cacheado en `PROJECT_ROOT/.ccache/` (persistente). En reintentos, solo recompila archivos modificados.

---

## Siguientes Pasos

1. ⬜ Ejecutar `01-download-sources.sh` — descargar ~3-5GB de sources (Qt6, KF6, Plasma, Mesa, Calamares)
2. ⬜ `07-wayland-mesa.sh` — stack gráfico Wayland (1-2h)
3. ⬜ `08-qt6.sh` — Qt6 (6-10h)
4. ⬜ `09-kf6.sh` — KDE Frameworks (2-3h)
5. ⬜ `10-plasma-6.sh` — Plasma 6 + apps (2-3h)
6. ⬜ `14-calamares.sh` — Calamares + deps (30min-1h)
7. ⬜ `15-build-iso.sh` — ISO generada
8. ⬜ Test en QEMU
9. ⬜ Commit final y push a GitHub

---

## Referencias

- `scripts/00-env.sh` — configuración de entorno y variables
- `scripts/02-toolchain.sh` — toolchain (completada, con fixes)
- `scripts/03-base-system.sh` — sistema base LFS (83 paquetes)
- `scripts/04-kernel-cachyos.sh` — kernel con parches CachyOS
- `docs/architecture.md` — arquitectura del sistema
- `docs/building.md` — guía de construcción
- `docs/filesystem.md` — estructura /user/
- `docs/immutable.md` — sistema A/B BTRFS
- `docs/hpk.md` — HyperPenguin Kommander
- `docs/hbox.md` — Cross-distro containers
- `docs/plasma-theming.md` — tematización Plasma
