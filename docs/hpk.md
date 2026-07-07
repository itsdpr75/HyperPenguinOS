# HyperPenguin Kommander (hpk)

`hpk` es el gestor unificado de aplicaciones de HyperPenguinOS. Maneja
AppImage, Flatpak y Linyaps bajo un solo comando, además de integrarse
con hbox para aplicaciones en contenedores cross-distro.

## Comandos

### Instalar una aplicación
```bash
# Detección automática del formato
hpk install firefox

# Forzar un formato específico
hpk install --flatpak org.gimp.GIMP
hpk install --appimage ./Firefox.AppImage
hpk install --linyaps com.example.app

# Instalar desde un contenedor cross-distro
hpk install --box ubuntu firefox
```

### Listar aplicaciones instaladas
```bash
hpk list
```

### Buscar aplicaciones
```bash
hpk search firefox
# Busca en Flathub, AppImageHub, y contenedores configurados
```

### Ejecutar una aplicación
```bash
hpk run firefox
hpk run org.gimp.GIMP
```

### Eliminar una aplicación
```bash
hpk remove firefox
```

## Arquitectura

```
hpk
├── cmd/              # Subcomandos CLI
│   ├── install.go
│   ├── remove.go
│   ├── list.go
│   ├── search.go
│   └── run.go
├── flatpak/          # Integración con Flatpak
├── appimage/         # Instalación y gestión de AppImages
├── linyaps/          # Integración con Linyaps
└── box/              # Integración con hbox
```

## Integración con el sistema

- Los .desktop files se generan automáticamente para cada aplicación instalada
- Las aplicaciones aparecen en el menú de KDE Plasma
- Discover puede gestionar aplicaciones Flatpak a través de hpk
- Las AppImages se almacenan en `/user/{user}/apps/appimages/`
