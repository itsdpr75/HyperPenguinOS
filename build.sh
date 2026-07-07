#!/bin/bash
set -euo pipefail

# ============================================================
# HyperPenguinOS Build Orchestrator
# Ejecuta las fases de construcción en orden.
# Opciones:
#   ./build.sh            → Construye todo excepto kernel+
#   ./build.sh full       → Construye todo completo
#   ./build.sh phase=N    → Empieza desde fase N (ej: phase=4)
#   ./build.sh list       → Muestra las fases disponibles
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")/scripts" && pwd)"
export SCRIPT_DIR

PHASES=(
    "01-download-sources.sh:Descargar fuentes"
    "02-toolchain.sh:Toolchain cruzada"
    "03-base-system.sh:Sistema base LFS Chapter 8"
    "00.5-setup-config.sh:Configuración del sistema"
    "04-kernel-cachyos.sh:Kernel + CachyOS patches"
    "05-ab-btrfs.sh:Sistema A/B BTRFS"
    "06-user-fs.sh:Filesystem de usuario"
    "07-wayland-mesa.sh:Wayland + Mesa"
    "08-qt6.sh:Qt 6"
    "09-kf6.sh:KDE Frameworks 6"
    "10-plasma-6.sh:KDE Plasma 6"
    "11-build-hpk.sh:HPK package manager"
    "12-build-hbox.sh:HBox containers"
    "13-build-kcm.sh:KCM"
    "14-calamares.sh:Calamares installer"
    "15-build-iso.sh:ISO final"
)

list_phases() {
    echo "Fases de construcción de HyperPenguinOS:"
    echo ""
    for i in "${!PHASES[@]}"; do
        num=$((i + 1))
        script="${PHASES[$i]%%:*}"
        desc="${PHASES[$i]#*:}"
        printf "  %2d. [%s] %s\n" "$num" "$script" "$desc"
    done
    echo ""
    echo "Uso:"
    echo "  ./build.sh              Construye desde fase 1"
    echo "  ./build.sh full         Construye todo (kernel+)"
    echo "  ./build.sh phase=5      Construye desde fase 5"
}

# Parse args
START_PHASE=1
FULL=false
for arg in "$@"; do
    case "$arg" in
        list|--list|-l) list_phases; exit 0 ;;
        full|--full|-f) FULL=true ;;
        phase=*) START_PHASE="${arg#phase=}" ;;
        --help|-h) list_phases; exit 0 ;;
        *) echo "Opción desconocida: $arg"; list_phases; exit 1 ;;
    esac
done

# Determinar rango de fases
if [ "$FULL" = true ]; then
    END_PHASE=${#PHASES[@]}
else
    END_PHASE=4  # Hasta 00.5-setup-config.sh (sin kernel+)
fi

echo "=============================="
echo " HyperPenguinOS Build"
echo "=============================="
echo "Iniciando desde fase $START_PHASE hasta $END_PHASE"
echo ""

for i in "${!PHASES[@]}"; do
    num=$((i + 1))
    if [ "$num" -lt "$START_PHASE" ]; then
        continue
    fi
    if [ "$num" -gt "$END_PHASE" ]; then
        break
    fi

    script="${PHASES[$i]%%:*}"
    desc="${PHASES[$i]#*:}"
    script_path="$SCRIPT_DIR/$script"

    if [ ! -f "$script_path" ]; then
        echo "  [SKIP] $script — no encontrado"
        continue
    fi

    echo "============================================"
    echo "  Fase $num: $desc ($script)"
    echo "============================================"
    if ! bash "$script_path"; then
        echo "ERROR: Fase $num ($script) falló"
        exit 1
    fi
    echo ""
done

echo "=============================="
echo " Build completado exitosamente"
echo "=============================="
