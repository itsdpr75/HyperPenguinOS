# HyperPenguinOS

Una distribución Linux inmutable basada en LFS con enfoque en eficiencia,
seguridad y una estructura de archivos centrada en el usuario.

## Características

- **Inmutable**: Sistema A/B BTRFS con actualizaciones atómicas y rollback
- **Estructura `/user/`**: Sistema de archivos rediseñado centrado en el usuario
- **HyperPenguin Kommander (hpk)**: Gestor unificado de AppImage, Flatpak y Linyaps
- **hbox**: Contenedores cross-distro con Podman para instalar paquetes .deb/.rpm
- **Wayland + KDE Plasma 6**: Escritorio moderno con KCM de rollback integrado
- **Calamares**: Instalador gráfico amigable
- **Kernel CachyOS**: Parches de rendimiento misc para kernel 6.18 LTS

## Estado del proyecto

| Componente | Estado |
|---|---|
| Toolchain LFS | ✅ Completa |
| Sistema base (83 paquetes) | ✅ Completo |
| Kernel 6.18 CachyOS | ✅ Compilado e instalado |
| Sistema A/B BTRFS | ✅ Scripts listos |
| Estructura /user/ | ✅ Configurada |
| Wayland + Mesa | ⬜ Pendiente |
| Qt6 | ⬜ Pendiente (~6-10h compilación) |
| KDE Frameworks 6 | ⬜ Pendiente |
| KDE Plasma 6 | ⬜ Pendiente |
| hpk, hbox, KCM | ✅ Código listo (submódulos) |
| Calamares | ⬜ Pendiente |
| ISO | ⬜ Pendiente |

## Estructura del proyecto

```
HyperPenguinOS/
├── config/           # Archivos de configuración del sistema
│   └── rootfs/etc/   #  (fstab, hostname, locale, network, etc.)
├── lfs/              # Build temporal del sistema (no entra en git)
├── scripts/          # Build scripts (fases 0.5 a 15)
├── kernel/           # Parches CachyOS + config del kernel
├── src/              # Submódulos
│   ├── hpk/          # HyperPenguin Kommander (Go)
│   ├── hbox/         # Cross-distro container manager (Go)
│   └── kcm-rollback/ # KCM de snapshots BTRFS (C++/QML)
├── packages/         # Temas, configs por defecto
├── .ccache/          # Caché de compilación (ccache)
├── build.sh          # Orquestador de build
└── docs/             # Documentación del proyecto
```

## Construcción

Clona el repositorio y ejecuta:

```bash
git clone --recursive https://github.com/tu-usuario/HyperPenguinOS.git
cd HyperPenguinOS

# Build completo (toolchain + sistema base + kernel + escritorio + ISO)
sudo ./build.sh
```

Ver [docs/building.md](docs/building.md) para instrucciones detalladas
por fase y opciones de reanudación.

## Licencia

Copyright (C) 2026 HyperPenguinOS

GNU Affero General Public License v3.0. Ver [LICENSE](LICENSE).
