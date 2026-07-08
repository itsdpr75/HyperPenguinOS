# hbox — Contenedores Cross-Distro

`hbox` es el gestor de contenedores cross-distro de HyperPenguinOS. 
Permite ejecutar aplicaciones de otras distribuciones Linux dentro de
contenedores Podman, integrándolas de forma transparente en el escritorio.

## Comandos

### Crear un contenedor
```bash
hbox create ubuntu --image ubuntu:24.04
hbox create fedora --image fedora:40
hbox create arch --image archlinux:latest
```

### Instalar un paquete en un contenedor
```bash
hbox install ubuntu firefox
hbox install fedora gimp
```

### Ejecutar una aplicación desde un contenedor
```bash
hbox run ubuntu firefox
```

### Buscar un paquete en todos los contenedores
```bash
hbox search firefox
```

### Listar contenedores
```bash
hbox list
```

### Listar aplicaciones disponibles en un contenedor
```bash
hbox list ubuntu
```

### Eliminar un contenedor
```bash
hbox remove ubuntu
```

## Registro JSON

El registro se almacena en `/user/{user}/apps/boxes/registry.json`:

```json
{
  "containers": {
    "ubuntu": {
      "image": "ubuntu:24.04",
      "created": "2026-07-04T12:00:00Z",
      "apps": {
        "firefox": {
          "binary": "/usr/bin/firefox",
          "desktop": "firefox.desktop",
          "installed": "2026-07-04T12:05:00Z"
        }
      }
    }
  }
}
```

## Integración con el escritorio

- Cada aplicación instalada en un contenedor genera un .desktop file
- Al hacer clic en el menú de Plasma, se ejecuta `hbox run contenedor app`
- Wayland, PulseAudio/PipeWire y GPU se montan automáticamente en el contenedor

## Requisitos

- Podman (sin daemon, rootless)
- Los contenedores se almacenan en `/user/{user}/apps/boxes/`
