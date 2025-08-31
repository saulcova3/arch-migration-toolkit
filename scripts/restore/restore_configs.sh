#!/bin/bash
# --------------------------------------------
# SCRIPT: restore_configs.sh
# DESCRIPCIÓN: Restaura la configuración de KDE y aplicaciones con cuidado
# USO: ./restore_configs.sh
# --------------------------------------------

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Funciones de log
log_info() { echo -e "${BLUE}🔄 $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_creative() { echo -e "${MAGENTA}🎨 $1${NC}"; }

# Obtener directorio de restauración
get_restore_dir() {
    echo "$HOME/migration_restore"
}

# Función para hacer backup de archivos existentes
backup_existing() {
    local file_path="$1"
    local backup_dir="$2"
    
    if [ -e "$file_path" ]; then
        mkdir -p "$backup_dir"
        mv "$file_path" "$backup_dir/" 2>/dev/null && \
        log_info "Backup de: $(basename "$file_path")" || \
        log_warning "No se pudo hacer backup de: $file_path"
    fi
}

# Función principal
main() {
    local restore_dir=$(get_restore_dir)
    local config_source="$restore_dir/output/config_backup"
    local backup_dir="$restore_dir/config_backup_old"
    
    echo "🎨 Iniciando restauración de configuración..."
    echo "============================================="
    
    # Verificar que existe el respaldo
    if [ ! -d "$config_source" ]; then
        log_error "No se encuentra el respaldo de configuración en: $config_source"
        log_warning "Asegúrate de que copiaste la carpeta 'output/' a: $restore_dir/"
        exit 1
    fi
    
    log_creative "Respaldo encontrado! Iniciando restauración con cuidado..."
    
    # Crear backup de configuraciones existentes
    log_info "Creando backup de configuraciones actuales..."
    mkdir -p "$backup_dir"
    
    # Restaurar .config
    if [ -d "$config_source/config" ]; then
        log_info "Restaurando configuración de ~/.config..."
        for item in "$config_source/config"/*; do
            if [ -e "$item" ]; then
                local item_name=$(basename "$item")
                backup_existing "$HOME/.config/$item_name" "$backup_dir/.config"
                cp -r "$item" "$HOME/.config/" && \
                log_success "Restaurado: $item_name" || \
                log_error "Error restaurando: $item_name"
            fi
        done
    fi
    
    # Restaurar .local/share
    if [ -d "$config_source/local_share" ]; then
        log_info "Restaurando archivos locales de ~/.local/share..."
        for item in "$config_source/local_share"/*; do
            if [ -e "$item" ]; then
                local item_name=$(basename "$item")
                backup_existing "$HOME/.local/share/$item_name" "$backup_dir/.local_share"
                cp -r "$item" "$HOME/.local/share/" && \
                log_success "Restaurado: $item_name" || \
                log_error "Error restaurando: $item_name"
            fi
        done
    fi
    
    # Restaurar otros directorios importantes
    local important_dirs=("kde" "plasma" "icons" "themes" "konsole" "wallpapers")
    for dir in "${important_dirs[@]}"; do
        if [ -d "$config_source/$dir" ]; then
            log_info "Restaurando $dir..."
            case $dir in
                "kde")
                    backup_existing "$HOME/.kde" "$backup_dir"
                    cp -r "$config_source/$dir" "$HOME/.kde" && \
                    log_success "Restaurado: .kde" || \
                    log_error "Error restaurando: .kde"
                    ;;
                "wallpapers")
                    mkdir -p "$HOME/Imágenes"
                    cp -r "$config_source/$dir" "$HOME/Imágenes/" && \
                    log_success "Restaurado: wallpapers" || \
                    log_error "Error restaurando: wallpapers"
                    ;;
                *)
                    # Para temas, iconos, etc.
                    target_dir="$HOME/.local/share/$dir"
                    backup_existing "$target_dir" "$backup_dir"
                    cp -r "$config_source/$dir" "$target_dir" && \
                    log_success "Restaurado: $dir" || \
                    log_error "Error restaurando: $dir"
                    ;;
            esac
        fi
    done
    
    # Resultado final
    echo ""
    log_success "=========================================="
    log_success "🎉 RESTAURACIÓN DE CONFIGURACIÓN COMPLETADA"
    log_success "📁 Backup de configs antiguas en: $backup_dir"
    log_success "📍 Reinicia las aplicaciones para aplicar los cambios"
    log_success "=========================================="
    
    # Mostrar estadísticas
    local restored_count=$(find "$config_source" -type f 2>/dev/null | wc -l)
    log_info "📊 Archivos restaurados: $restored_count"
}

# Manejo de errores
set -euo pipefail

# Ejecutar función principal
main "$@"