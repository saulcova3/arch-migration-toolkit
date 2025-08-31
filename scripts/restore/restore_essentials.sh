#!/bin/bash
# --------------------------------------------
# SCRIPT: restore_essentials.sh
# DESCRIPCIÓN: Restaura elementos esenciales (GPG, SSH, scripts) con seguridad
# USO: ./restore_essentials.sh
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
log_secret() { echo -e "${MAGENTA}💎 $1${NC}"; }

# Obtener directorio de restauración
get_restore_dir() {
    echo "$HOME/migration_restore"
}

# Función para restaurar con verificación
restore_essential() {
    local source_path="$1"
    local target_path="$2"
    local description="$3"
    
    if [ -e "$source_path" ]; then
        # Crear backup si existe
        if [ -e "$target_path" ]; then
            backup_path="${target_path}.backup.$(date +%Y%m%d_%H%M%S)"
            mv "$target_path" "$backup_path" 2>/dev/null && \
            log_info "Backup de: $description → $backup_path"
        fi
        
        # Copiar
        if cp -r "$source_path" "$target_path" 2>/dev/null; then
            log_success "Restaurado: $description"
            return 0
        else
            log_error "Error restaurando: $description"
            return 1
        fi
    else
        log_warning "No encontrado para restaurar: $description"
        return 2
    fi
}

# Función para establecer permisos seguros
set_secure_permissions() {
    log_info "Estableciendo permisos seguros..."
    
    # GPG - permisos seguros
    if [ -d "$HOME/.gnupg" ]; then
        chmod 700 "$HOME/.gnupg" 2>/dev/null && \
        find "$HOME/.gnupg" -type f -exec chmod 600 {} \; 2>/dev/null && \
        log_success "Permisos seguros para GPG"
    fi
    
    # SSH - permisos seguros
    if [ -d "$HOME/.ssh" ]; then
        chmod 700 "$HOME/.ssh" 2>/dev/null && \
        find "$HOME/.ssh" -type f -name "*.pub" -exec chmod 644 {} \; 2>/dev/null && \
        find "$HOME/.ssh" -type f -not -name "*.pub" -exec chmod 600 {} \; 2>/dev/null && \
        log_success "Permisos seguros para SSH"
    fi
    
    # Scripts locales - permisos ejecutables
    if [ -d "$HOME/.local/bin" ]; then
        find "$HOME/.local/bin" -type f -exec chmod +x {} \; 2>/dev/null && \
        log_success "Permisos ejecutables para scripts locales"
    fi
}

# Función principal
main() {
    local restore_dir=$(get_restore_dir)
    local essentials_source="$restore_dir/output/essentials"
    
    echo "💎 Iniciando restauración de elementos esenciales..."
    echo "===================================================="
    
    # Verificar que existe el respaldo
    if [ ! -d "$essentials_source" ]; then
        log_error "No se encuentra el respaldo de elementos esenciales en: $essentials_source"
        log_warning "Asegúrate de que copiaste la carpeta 'output/' a: $restore_dir/"
        exit 1
    fi
    
    log_secret "Respaldo encontrado! Restaurando tesoros esenciales..."
    
    # 1. 🔐 Restaurar GPG
    restore_essential "$essentials_source/gnupg" "$HOME/.gnupg" "claves GPG"
    
    # 2. 🔑 Restaurar SSH (si existe en el backup)
    restore_essential "$essentials_source/ssh" "$HOME/.ssh" "claves SSH"
    
    # 3. 📝 Restaurar scripts locales
    restore_essential "$essentials_source/local_bin" "$HOME/.local/bin" "scripts personales"
    
    # 4. 🌐 Restaurar configuraciones de red (si existen)
    if [ -d "$essentials_source/network" ]; then
        log_info "Restaurando configuraciones de red..."
        sudo cp -r "$essentials_source/network/"* "/etc/NetworkManager/system-connections/" 2>/dev/null && \
        log_success "Configuraciones de red restauradas" || \
        log_warning "No se pudieron restaurar configuraciones de red (requiere sudo)"
    fi
    
    # 5. 📦 Restaurar repositorios AUR locales (si existen)
    if [ -d "$essentials_source/aur_repos" ]; then
        log_info "Restaurando repositorios AUR locales..."
        mkdir -p "$HOME/aur" "$HOME/builds"
        cp -r "$essentials_source/aur_repos/"* "$HOME/aur/" 2>/dev/null || \
        cp -r "$essentials_source/aur_repos/"* "$HOME/builds/" 2>/dev/null && \
        log_success "Repositorios AUR restaurados" || \
        log_warning "No se pudieron restaurar repositorios AUR"
    fi
    
    # Establecer permisos seguros
    set_secure_permissions
    
    # Resultado final
    echo ""
    log_success "=========================================="
    log_success "💎 RESTAURACIÓN DE ELEMENTOS ESENCIALES COMPLETADA"
    log_success "🔐 Claves GPG y SSH protegidas"
    log_success "📝 Scripts personales restaurados"
    log_success "🌐 Configuraciones de red aplicadas"
    log_success "=========================================="
}

# Manejo de errores
set -euo pipefail

# Ejecutar función principal
main "$@"