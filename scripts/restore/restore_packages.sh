#!/bin/bash
# --------------------------------------------
# SCRIPT: restore_packages.sh
# DESCRIPCIÓN: Reinstala todos los paquetes en el nuevo sistema con verificación
# USO: ./restore_packages.sh
# --------------------------------------------

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Funciones de log
log_info() { echo -e "${BLUE}🔄 $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_package() { echo -e "${CYAN}📦 $1${NC}"; }

# Obtener directorio de restauración
get_restore_dir() {
    echo "$HOME/migration_restore"
}

# Verificar e instalar AUR helper si es necesario
ensure_aur_helper() {
    if command -v yay &> /dev/null; then
        echo "yay"
        return 0
    elif command -v paru &> /dev/null; then
        echo "paru"
        return 0
    else
        log_warning "No se encontró yay ni paru"
        log_info "Instalando yay..."
        
        if ! sudo pacman -S --needed git base-devel --noconfirm; then
            log_error "Error instalando dependencias para yay"
            return 1
        fi
        
        if git clone https://aur.archlinux.org/yay-bin.git; then
            cd yay-bin
            if makepkg -si --noconfirm; then
                cd .. && rm -rf yay-bin
                echo "yay"
                return 0
            else
                log_error "Error compilando yay"
                return 1
            fi
        else
            log_error "Error clonando repositorio de yay"
            return 1
        fi
    fi
}

# Función para instalar paquetes con progreso
install_packages() {
    local package_file="$1"
    local installer="$2"
    local description="$3"
    
    if [ ! -f "$package_file" ]; then
        log_warning "No se encuentra: $package_file"
        return 1
    fi
    
    local package_count=$(wc -l < "$package_file")
    if [ "$package_count" -eq 0 ]; then
        log_warning "Archivo vacío: $package_file"
        return 1
    fi
    
    log_package "Instalando $description ($package_count paquetes)..."
    
    if $installer -S --needed --noconfirm - < "$package_file"; then
        log_success "$description instalados correctamente"
        return 0
    else
        log_error "Error instalando $description"
        return 1
    fi
}

# Función principal
main() {
    local restore_dir=$(get_restore_dir)
    local packages_dir="$restore_dir/output/packages_lists"
    
    echo "🚀 Iniciando instalación de paquetes..."
    echo "========================================"
    
    # Verificar que existen los archivos de paquetes
    if [ ! -d "$packages_dir" ]; then
        log_error "No se encuentra el directorio de paquetes en: $packages_dir"
        log_warning "Asegúrate de que copiaste la carpeta 'output/' a: $restore_dir/"
        exit 1
    fi
    
    # Verificar archivos específicos
    local aur_file="$packages_dir/aur_packages.txt"
    local pacman_file="$packages_dir/pacman_packages.txt"
    
    if [ ! -f "$pacman_file" ]; then
        log_error "No se encuentra: $pacman_file"
        exit 1
    fi
    
    # Obtener AUR helper
    log_info "Buscando helper de AUR..."
    local aur_helper=$(ensure_aur_helper)
    if [ $? -ne 0 ]; then
        log_error "No se pudo obtener un helper de AUR"
        exit 1
    fi
    
    log_success "Usando: $aur_helper"
    
    # 1. 📦 Instalar paquetes oficiales PRIMERO (más estables)
    log_info "Instalando paquetes oficiales..."
    if ! install_packages "$pacman_file" "sudo pacman" "paquetes oficiales"; then
        log_error "Fallo crítico en instalación de paquetes oficiales"
        exit 1
    fi
    
    # 2. 🏗️ Instalar paquetes AUR (si existen)
    if [ -f "$aur_file" ] && [ -s "$aur_file" ]; then
        log_info "Instalando paquetes AUR..."
        if ! install_packages "$aur_file" "$aur_helper" "paquetes AUR"; then
            log_warning "Algunos paquetes AUR fallaron, continuando..."
        fi
    else
        log_info "No hay paquetes AUR para instalar"
    fi
    
    # 3. 🧹 Limpieza opcional
    log_info "Realizando limpieza..."
    if sudo pacman -Sc --noconfirm; then
        log_success "Limpieza completada"
    fi
    
    # Resultado final
    echo ""
    log_success "=========================================="
    log_success "🎉 INSTALACIÓN DE PAQUETES COMPLETADA"
    log_success "📦 Paquetes oficiales: $(wc -l < "$pacman_file")"
    if [ -f "$aur_file" ]; then
        log_success "🏗️  Paquetes AUR: $(wc -l < "$aur_file")"
    fi
    log_success "=========================================="
    
    # Mostrar estadísticas finales
    echo ""
    log_info "📊 Estadísticas del sistema:"
    log_info "Total paquetes instalados: $(pacman -Q | wc -l)"
    log_info "Paquetes explícitos: $(pacman -Qe | wc -l)"
    log_info "Paquetes AUR: $(pacman -Qm | wc -l)"
}

# Manejo de errores
set -euo pipefail

# Ejecutar función principal
main "$@"