#!/bin/bash
# ==============================================================================
# SCRIPT: install_yay.sh
# DESCRIPCIÓN: Instala yay y prepara el sistema para la restauración
# USO: ./install_yay.sh
# ==============================================================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funciones de log
log_info() { echo -e "${BLUE}🔄 $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Obtener directorio de restauración
get_restore_dir() {
    echo "$HOME/migration_restore"
}

# Función principal
main() {
    echo "🏗️  Preparando sistema para restauración..."
    echo "=========================================="
    
    local restore_dir=$(get_restore_dir)
    
    # Verificar si yay ya está instalado
    if command -v yay &> /dev/null; then
        log_success "yay ya está instalado"
    else
        log_info "Instalando yay desde AUR..."
        
        # Instalar dependencias
        if ! sudo pacman -S --needed git base-devel --noconfirm; then
            log_error "Error instalando dependencias"
            exit 1
        fi
        
        # Clonar y compilar yay
        if git clone https://aur.archlinux.org/yay-bin.git; then
            cd yay-bin
            if makepkg -si --noconfirm; then
                log_success "yay instalado correctamente"
                cd .. && rm -rf yay-bin
            else
                log_error "Error compilando yay"
                exit 1
            fi
        else
            log_error "Error clonando repositorio de yay"
            exit 1
        fi
    fi
    
    # Crear directorio de restauración
    log_info "Creando directorio para restauración..."
    if mkdir -p "$restore_dir"; then
        log_success "Directorio de restauración creado: $restore_dir"
    else
        log_error "No se pudo crear el directorio de restauración"
        exit 1
    fi
    
    # Mensaje final
    echo ""
    log_success "Sistema preparado para restauración"
    echo ""
    log_info "📋 Próximos pasos:"
    log_info "1. Copia la carpeta 'output/' del disco de respaldo a: $restore_dir/"
    log_info "2. Ejecuta: ./restore_packages.sh"
    log_info "3. Ejecuta: ./restore_configs.sh" 
    log_info "4. Ejecuta: ./restore_essentials.sh"
    log_info "5. Ejecuta: ./verify_restoration.sh"
    echo ""
}

# Manejo de errores
set -euo pipefail

# Ejecutar función principal
main "$@"