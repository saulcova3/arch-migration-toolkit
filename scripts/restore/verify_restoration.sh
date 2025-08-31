#!/bin/bash
# ==============================================================================
# SCRIPT: verify_restoration.sh
# DESCRIPCIÓN: Verifica que la restauración se completó exitosamente
# USO: ./verify_restoration.sh
# ==============================================================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Funciones de log
log_info() { echo -e "${BLUE}🔄 $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_verify() { echo -e "${CYAN}🔍 $1${NC}"; }

# Obtener directorios
get_restore_dir() {
    echo "$HOME/migration_restore"
}

# Función de verificación optimizada
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
        return 0
    else
        echo -e "${RED}❌ $1${NC}"
        return 1
    fi
}

# Verificar paquetes de forma eficiente
verify_packages() {
    local backup_file="$1"
    local package_type="$2"
    
    if [ ! -f "$backup_file" ]; then
        log_warning "No se encuentra: $backup_file"
        return 1
    fi
    
    local total_packages=$(wc -l < "$backup_file")
    local missing_packages=0
    
    if [ "$total_packages" -eq 0 ]; then
        log_warning "Archivo vacío: $backup_file"
        return 1
    fi
    
    # Verificación optimizada: crear lista temporal y comparar
    local temp_file=$(mktemp)
    pacman -Qq > "$temp_file"
    
    while read -r pkg; do
        if ! grep -qx "$pkg" "$temp_file"; then
            if [ "$missing_packages" -lt 5 ]; then  # Mostrar solo primeros 5 faltantes
                echo -e "${YELLOW}   ⚠️  $pkg (Faltante)${NC}"
            fi
            ((missing_packages++))
        fi
    done < "$backup_file"
    
    rm -f "$temp_file"
    
    local installed_count=$((total_packages - missing_packages))
    if [ "$missing_packages" -eq 0 ]; then
        log_success "$package_type: $installed_count/$total_packages paquetes"
    else
        log_warning "$package_type: $installed_count/$total_packages paquetes ($missing_packages faltantes)"
    fi
    
    return $missing_packages
}

# Función principal
main() {
    local restore_dir=$(get_restore_dir)
    local backup_dir="$restore_dir/output"
    
    echo ""
    log_verify "INICIANDO VERIFICACIÓN DE RESTAURACIÓN"
    echo "=========================================="
    
    # Verificar que existe el directorio de backup
    if [ ! -d "$backup_dir" ]; then
        log_error "No se encuentra el directorio de backup: $backup_dir"
        log_warning "Asegúrate de que copiaste la carpeta 'output/' a: $restore_dir/"
        exit 1
    fi
    
    echo ""
    log_info "📦 VERIFICANDO PAQUETES INSTALADOS:"
    echo "-----------------------------------"
    
    # Verificar paquetes oficiales (optimizado)
    local official_missing=0
    local aur_missing=0
    
    if [ -f "$backup_dir/packages_lists/pacman_packages.txt" ]; then
        verify_packages "$backup_dir/packages_lists/pacman_packages.txt" "Paquetes oficiales"
        official_missing=$?
    fi
    
    # Verificar paquetes AUR
    if [ -f "$backup_dir/packages_lists/aur_packages.txt" ]; then
        verify_packages "$backup_dir/packages_lists/aur_packages.txt" "Paquetes AUR"
        aur_missing=$?
    fi
    
    echo ""
    log_info "🎨 VERIFICANDO CONFIGURACIÓN:"
    echo "------------------------------"
    
    # Verificar configuraciones
    check_directory() {
        if [ -d "$1" ]; then
            local item_count=$(find "$1" -type f 2>/dev/null | wc -l)
            echo -e "${GREEN}✅ $2 ($item_count archivos)${NC}"
            return 0
        else
            echo -e "${RED}❌ $2${NC}"
            return 1
        fi
    }
    
    check_directory "$HOME/.config" "Configuración .config"
    check_directory "$HOME/.local/share" "Datos locales"
    [ -d "$HOME/.kde" ] && check_directory "$HOME/.kde" "Configuración KDE"
    
    # Verificar configs específicas de KDE
    if [ -f "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" ]; then
        echo -e "${GREEN}✅ Configuración de Plasma${NC}"
    else
        echo -e "${YELLOW}⚠️  Configuración de Plasma (Faltante)${NC}"
    fi
    
    echo ""
    log_info "🔐 VERIFICANDO ELEMENTOS CRÍTICOS:"
    echo "-----------------------------------"
    
    # Verificar elementos esenciales
    [ -d "$HOME/.gnupg" ] && echo -e "${GREEN}✅ GPG configurado${NC}" || echo -e "${RED}❌ GPG no configurado${NC}"
    [ -d "$HOME/.ssh" ] && echo -e "${GREEN}✅ SSH configurado${NC}" || echo -e "${YELLOW}⚠️  SSH no configurado${NC}"
    
    if [ -d "$HOME/.local/bin" ]; then
        local script_count=$(find "$HOME/.local/bin" -type f 2>/dev/null | wc -l)
        echo -e "${GREEN}✅ Scripts personales ($script_count encontrados)${NC}"
    else
        echo -e "${YELLOW}⚠️  Scripts personales (Faltantes)${NC}"
    fi
    
    echo ""
    log_info "📊 REPORTE FINAL:"
    echo "=========================================="
    
    # Estadísticas
    local official_count=$(pacman -Qqe | grep -v "$(pacman -Qqm)" | wc -l)
    local aur_count=$(pacman -Qqm | wc -l)
    local total_count=$(pacman -Q | wc -l)
    
    echo -e "📦 Paquetes oficiales: $official_count"
    echo -e "🏗️  Paquetes AUR: $aur_count"
    echo -e "📈 Total paquetes: $total_count"
    
    echo ""
    log_info "🎯 ESTADO DE LA MIGRACIÓN:"
    
    # Criterio mejorado de verificación
    local total_missing=$((official_missing + aur_missing))
    
    if [ "$total_missing" -eq 0 ] && [ -d "$HOME/.config" ]; then
        echo -e "${GREEN}✅ ¡RESTAURACIÓN EXITOSA!${NC}"
        echo -e "   Todos los componentes principales están instalados"
    elif [ "$total_missing" -lt 10 ]; then
        echo -e "${GREEN}✅ ¡RESTAURACIÓN CASI COMPLETA!${NC}"
        echo -e "   Faltan solo $total_missing paquetes menores"
    else
        echo -e "${YELLOW}⚠️  RESTAURACIÓN PARCIAL${NC}"
        echo -e "   Faltan $total_missing paquetes"
        echo -e "   Ejecuta: ./restore_packages.sh para reinstalar los faltantes"
    fi
    
    echo ""
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}🔍 Verificación completada. Revisa los resultados arriba.${NC}"
}

# Manejo de errores
set -euo pipefail

# Ejecutar función principal
main "$@"