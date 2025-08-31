#!/bin/bash
# ==============================================================================
# SCRIPT: migration_manager.sh
# DESCRIPCIÓN: Menú para gestionar migración Arch Linux
# USO: ./migration_manager.sh
# ==============================================================================

# Colores
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

# Obtener ruta del proyecto de forma portable
get_project_root() {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

# Función para hacer respaldo
do_backup() {
    echo ""
    log_info "INICIANDO RESPALDO COMPLETO"
    echo "================================"
    
    local project_root=$(get_project_root)
    cd "$project_root/scripts/backup/"
    
    log_info "Ejecutando pre_backup_update.sh..."
    ./pre_backup_update.sh
    
    log_info "Ejecutando backup_packages.sh..."
    ./backup_packages.sh
    
    log_info "Ejecutando backup_configs.sh..."
    ./backup_configs.sh
    
    log_info "Ejecutando backup_essentials.sh..."
    ./backup_essentials.sh
    
    echo ""
    log_success "RESPALDO COMPLETADO"
    log_success "Copia la carpeta 'output/' a tu disco de respaldo"
    echo ""
}

# Función para hacer restauración
do_restore() {
    echo ""
    log_info "INICIANDO RESTAURACIÓN"
    echo "=========================="
    
    local project_root=$(get_project_root)
    local restore_dir="$HOME/migration_restore"
    
    # Verificar que estamos en el nuevo sistema
    if [ ! -f "$restore_dir/output/packages_lists/pacman_packages.txt" ]; then
        log_error "No se encuentra el respaldo en $restore_dir/output/"
        log_warning "Por favor:"
        log_warning "1. Conecta tu disco de respaldo"
        log_warning "2. Copia la carpeta 'output/' a $restore_dir/"
        log_warning "3. Ejecuta esta opción nuevamente"
        return 1
    fi
    
    cd "$restore_dir/scripts/restore/"
    
    log_info "Ejecutando install_yay.sh..."
    ./install_yay.sh
    
    log_info "Ejecutando restore_packages.sh..."
    ./restore_packages.sh
    
    log_info "Ejecutando restore_configs.sh..."
    ./restore_configs.sh
    
    log_info "Ejecutando restore_essentials.sh..."
    ./restore_essentials.sh
    
    log_info "Ejecutando verify_restoration.sh..."
    ./verify_restoration.sh
    
    echo ""
    log_success "RESTAURACIÓN COMPLETADA"
    log_warning "Reinicia el sistema para aplicar todos los cambios"
    echo ""
}

# Mostrar menú
show_menu() {
    echo ""
    echo "========================================"
    echo "🌐 GESTOR DE MIGRACIÓN ARCH LINUX"
    echo "========================================"
    echo "1️⃣  Realizar RESPALDO (desde sistema actual)"
    echo "2️⃣  Realizar RESTAURACIÓN (en nuevo sistema)"
    echo "3️⃣  Salir"
    echo "========================================"
    read -p "Selecciona una opción (1-3): " choice
    
    case $choice in
        1) do_backup ;;
        2) do_restore ;;
        3) echo "¡Hasta luego! 👋"; exit 0 ;;
        *) log_error "Opción inválida"; show_menu ;;
    esac
}

# Función principal
main() {
    local project_root=$(get_project_root)
    
    # Verificar que estamos en el directorio correcto
    if [ ! -d "$project_root/scripts" ]; then
        log_error "No se encuentra la estructura del proyecto"
        log_warning "Ejecuta este script desde la raíz del proyecto"
        exit 1
    fi
    
    # Mostrar menú principal
    show_menu
}

# Ejecutar función principal
main "$@"