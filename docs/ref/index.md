# HyperPenguinOS Documentation

## Índice

1. [Arquitectura del sistema](architecture.md)
2. [Estructura de archivos /user/](filesystem.md)
3. [Sistema inmutable A/B BTRFS](immutable.md)
4. [HyperPenguin Kommander (hpk)](hpk.md)
5. [hbox - Contenedores cross-distro](hbox.md)
6. [Personalización de Plasma](plasma-theming.md)
7. [Construcción del sistema](building.md)
8. [Estado del proyecto](PLAN.md)

## Visión general

HyperPenguinOS es una distribución Linux construida desde cero con Linux From Scratch (LFS).
Su objetivo es ofrecer un sistema inmutable, eficiente y seguro, con una estructura de
archivos rediseñada centrada en el usuario.

### Principios de diseño

- **Inmutabilidad**: El sistema base es de solo lectura, las actualizaciones son atómicas
- **Usuario como centro**: Todo el contenido del usuario vive bajo `/user/{username}/`
- **Contenedores first-class**: Las aplicaciones externas se ejecutan en contenedores
- **Simplicidad**: Herramientas CLI ligeras, sin demonios innecesarios
- **Rollback nativo**: Snapshots BTRFS accesibles desde System Settings de Plasma

### Estado actual

| Componente | Estado |
|---|---|
| Toolchain + Sistema base (83 paquetes) | ✅ Completado |
| Kernel 6.18 CachyOS | ✅ Compilado + initramfs |
| Sistema A/B + /user/ | ✅ Configurado |
| Wayland + Mesa + Qt6 + KF6 + Plasma | ⬜ Pendiente |
| hpk, hbox, KCM | ✅ Submódulos listos |
| Calamares + ISO | ⬜ Pendiente |

### Tecnologías clave

- **Base**: Linux From Scratch 13.0-systemd, GCC 15.2.0, glibc 2.43
- **Kernel**: Linux 6.18.37 + parches CachyOS (misc)
- **Gráficos**: Wayland + Mesa + KDE Plasma 6
- **Tooling**: Go (hpk, hbox), C++/QML (KCM)
- **Instalador**: Calamares 3.3.7
- **Sistema archivos**: BTRFS con snapshots y actualizaciones A/B
