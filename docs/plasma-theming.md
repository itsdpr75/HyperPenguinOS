# Personalización de Plasma

## Temas globales (Look-and-Feel)

Los temas globales de Plasma empaquetan todo en un solo archivo: 
estilo de plasma, decoraciones de ventanas, colores, fondos, splash screen 
y tema SDDM.

### Crear un tema global

```bash
# Después de personalizar en System Settings:
plasma-apply-lookandfeel -o hyperpenguin-lnf.tar.gz

# O manualmente:
mkdir -p mytheme/contents/{desktoptheme,colors,icons,sddm,wallpapers,splash}
# ... completar archivos ...
kpackagetool6 -t Plasma/LookAndFeel -i mytheme.tar.gz
plasma-apply-lookandfeel -a org.hyperpenguin.desktop
```

### Instalar desde el repositorio

```bash
kpackagetool6 -t Plasma/LookAndFeel -i /path/to/tema.tar.gz
plasma-apply-lookandfeel -a org.hyperpenguin.desktop
```

## Temas de Plasma (desktoptheme)

Los temas definen el aspecto de paneles, widgets y la barra de tareas.

Ubicación: `/usr/share/plasma/desktoptheme/` o `~/.local/share/plasma/desktoptheme/`

## Decoraciones de ventanas

- **Breeze**: Tema por defecto, renderizado nativo
- **SierraBreezeEnhanced**: Decoraciones estilo macOS (requiere compilación)
- **Klassy**: Decoraciones modernas con bordes redondeados

## Splash Screen

Ubicación: `/usr/share/plasma/look-and-feel/*/contents/splash/`

Es una animación QML que se muestra durante el inicio de sesión.

## SDDM (Display Manager)

Tema de login: `/usr/share/sddm/themes/`

Configuración: `/etc/sddm.conf.d/`

## Kvantum

Para un theming más avanzado de las aplicaciones Qt, Kvantum permite
estilos con transparencia, bordes redondeados y animaciones.

```bash
kvantummanager  # Interfaz gráfica para gestionar temas
```

## Consejos para un tema único

1. Usa **Breeze** como base (es el más completo y probado)
2. Personaliza colores en `contents/colors/`
3. Crea un wallpaper distintivo en `contents/wallpapers/`
4. Usa **Kvantum** para el estilo de aplicación (más moderno que Breeze nativo)
5. Añade un splash screen QML con el logo de HyperPenguinOS
6. Configura SDDM con fondo y colores del sistema
7. Inspírate en temas como **Fluent** o **Graphite** de la comunidad KDE
