#!/bin/bash

# Función genérica para compilar un paquete LFS/BLFS
# Uso: build_package <nombre> <versión> [opciones]

build_package() {
    local name="$1"
    local version="$2"
    shift 2
    local options="$@"

    local archive="$LFS_SOURCES/$name-$version.tar.*"
    local build_dir="$LFS/build/$name-$version"

    log_info "Construyendo $name-$version..."

    # Encontrar el archivo comprimido
    local tarball=$(ls $archive 2>/dev/null | head -1)
    if [ -z "$tarball" ]; then
        log_error "Archivo fuente no encontrado para $name-$version"
        return 1
    fi

    rm -rf "$build_dir"
    mkdir -pv "$LFS/build"
    tar -xf "$tarball" -C "$LFS/build"
    cd "$build_dir"

    # Ejecutar configuración y compilación
    if [ -f configure ]; then
        ./configure $options
    fi
    make $MAKEFLAGS
    make install

    cd "$LFS"
    rm -rf "$build_dir"
    log_success "$name-$version compilado correctamente"
}

export -f build_package
