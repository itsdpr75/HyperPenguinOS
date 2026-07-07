#!/bin/bash

# ============================================================
# Fase 5: Estructura /user/ personalizada
# Configura PAM, XDG y esqueletos de usuario
# ============================================================

source "$(dirname "$0")/00-env.sh"

log_info "=== Configurando estructura de archivos /user/ ==="

# 5.1 Perfil del sistema - Variables XDG
mkdir -pv "$LFS_ROOTFS/etc/profile.d"

cat > "$LFS_ROOTFS/etc/profile.d/hyperpenguin.sh" << 'EOF'
# HyperPenguinOS - Variables de entorno

# Configuración de usuario
export XDG_CONFIG_HOME=/user/${USER}/config
export XDG_DATA_HOME=/user/${USER}/apps
export XDG_STATE_HOME=/user/${USER}/config/state
export XDG_CACHE_HOME=/user/${USER}/config/cache

# Directorios de usuario
export XDG_DOCUMENTS_DIR=/user/${USER}/home/Documentos
export XDG_DOWNLOAD_DIR=/user/${USER}/home/Descargas
export XDG_PICTURES_DIR=/user/${USER}/home/Imágenes
export XDG_MUSIC_DIR=/user/${USER}/home/Música
export XDG_VIDEOS_DIR=/user/${USER}/home/Vídeos
export XDG_DESKTOP_DIR=/user/${USER}/home/Escritorio
export XDG_PUBLICSHARE_DIR=/user/${USER}/home/Público
export XDG_TEMPLATES_DIR=/user/${USER}/home/Plantillas

# Directorios de aplicaciones
export APPS_DIR=/user/${USER}/apps
export APPS_APPIMAGE=${APPS_DIR}/appimages
export APPS_FLATPAK=${APPS_DIR}/flatpak
export APPS_LINYAPS=${APPS_DIR}/linyaps
export APPS_BOXES=${APPS_DIR}/boxes

# Añadir apps al PATH
export PATH=${PATH}:${APPS_APPIMAGE}

# Home personalizado
export HOME=/user/${USER}
EOF

# 5.2 PAM configuration
mkdir -pv "$LFS_ROOTFS/etc/pam.d"

cat > "$LFS_ROOTFS/etc/pam.d/system-auth" << 'EOF'
# PAM system-wide configuration for HyperPenguinOS
auth       required     pam_unix.so
account    required     pam_unix.so
password   required     pam_unix.so sha512 shadow
session    required     pam_unix.so
session    optional     pam_mkhomedir.so skel=/etc/skel umask=077
EOF

cat > "$LFS_ROOTFS/etc/pam.d/login" << 'EOF'
auth       include      system-auth
account    include      system-auth
password   include      system-auth
session    include      system-auth
session    required     pam_loginuid.so
EOF

cat > "$LFS_ROOTFS/etc/pam.d/su" << 'EOF'
auth       sufficient   pam_rootok.so
auth       include      system-auth
account    include      system-auth
password   include      system-auth
session    include      system-auth
EOF

cat > "$LFS_ROOTFS/etc/pam.d/sudo" << 'EOF'
auth       include      system-auth
account    include      system-auth
password   include      system-auth
session    include      system-auth
EOF

cat > "$LFS_ROOTFS/etc/pam.d/sddm" << 'EOF'
auth       include      system-auth
account    include      system-auth
password   include      system-auth
session    include      system-auth
session    required     pam_loginuid.so
session    optional     pam_ck_connector.so
EOF

# 5.3 /etc/skel - Esqueleto de usuario
SKEL="$LFS_ROOTFS/etc/skel"
mkdir -pv "$SKEL/config"
mkdir -pv "$SKEL/home"/{Documentos,Descargas,Imágenes,Música,Vídeos,Escritorio,Público,Plantillas,Proyectos}
mkdir -pv "$SKEL/apps"/{appimages,flatpak,linyaps,boxes}

# Configuraciones por defecto de Plasma en skel
cat > "$SKEL/config/kdeglobals" << 'EOF'
[General]
Name=HyperPenguinOS
XftHintStyle=hintmedium
XftSubPixel=none
EOF

cat > "$SKEL/config/kwinrc" << 'EOF'
[Compositing]
OpenGLIsUnsafe=false
Backend=Wayland
EOF

cat > "$SKEL/config/plasmarc" << 'EOF'
[Theme]
name=breeze-hyperpenguin
EOF

# 5.4 Configuración de adduser / useradd
cat > "$LFS_ROOTFS/etc/default/useradd" << 'EOF'
GROUP=100
HOME=/user
INACTIVE=-1
EXPIRE=
SHELL=/bin/bash
SKEL=/etc/skel
CREATE_MAIL_SPOOL=no
EOF

mkdir -pv "$LFS_ROOTFS/etc/login.defs.d"
cat > "$LFS_ROOTFS/etc/login.defs" << 'EOF'
MAIL_DIR        /var/spool/mail
PASS_MAX_DAYS   99999
PASS_MIN_DAYS   0
PASS_WARN_AGE   7
UID_MIN         1000
UID_MAX         60000
SYS_UID_MIN     100
SYS_UID_MAX     999
GID_MIN         1000
GID_MAX         60000
SYS_GID_MIN     100
SYS_GID_MAX     999
CREATE_HOME     yes
HOME_MODE       0750
USERGROUPS_ENAB yes
EOF

log_success "Estructura /user/ configurada"
