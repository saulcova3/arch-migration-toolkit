#!/bin/bash
# ==============================================================================
# SCRIPT: pre_backup_update.sh - VERSIÓN DEFINITIVA 🎯 (PORTABLE)
# ==============================================================================

echo "🔐 Inicializando la actualización previa"
# Configuración con RUTAS RELATIVAS
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
REPORT_DIR="$PROJECT_ROOT/output/reports"
BACKUP_DIR="$PROJECT_ROOT/output"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Función para mensajes de log con emojis
log_info() { echo -e "${BLUE}🔄 [INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}✅ [SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠️  [WARNING]${NC} $1"; }
log_error() { echo -e "${RED}❌ [ERROR]${NC} $1"; }

# Función para verificar si se ejecuta como root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Este script NO debe ejecutarse como root"
        exit 1
    fi
}

# Función para verificar conexión a internet
check_internet() {
    if ! ping -c 1 google.com &> /dev/null && ! ping -c 1 archlinux.org &> /dev/null; then
        log_error "No hay conexión a internet. Verifica tu conexión."
        exit 1
    fi
}

# Función para verificar si pacman está bloqueado
check_pacman_lock() {
    if [ -f /var/lib/pacman/db.lck ]; then
        log_error "Pacman está bloqueado. ¿Otro proceso de pacman en ejecución?"
        log_error "Ejecuta: sudo rm -f /var/lib/pacman/db.lck"
        exit 1
    fi
}

# Función para esperar si pacman está en uso
wait_for_pacman() {
    local max_attempts=5
    local attempt=1
    
    while pgrep -x pacman &> /dev/null; do
        if [ $attempt -gt $max_attempts ]; then
            log_error "Pacman sigue en uso después de $max_attempts intentos"
            exit 1
        fi
        log_warning "Pacman en uso, esperando... (intento $attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
}

# Función principal
main() {
    log_info "Iniciando actualización pre-respaldo"
    log_info "Reportes se guardarán en: $REPORT_DIR"
    
    # Crear directorios de reportes
    mkdir -p "$REPORT_DIR"
    
    # Capturar estado inicial
    log_info "Capturando estado inicial del sistema"
    echo "=== ESTADO INICIAL ===" > "$REPORT_DIR/01_estado_inicial.txt"
    echo "📅 Fecha: $(date)" >> "$REPORT_DIR/01_estado_inicial.txt"
    echo "👤 Usuario: $(whoami)" >> "$REPORT_DIR/01_estado_inicial.txt"
    echo "🐧 Kernel: $(uname -r)" >> "$REPORT_DIR/01_estado_inicial.txt"
    echo "📦 Paquetes totales: $(pacman -Q | wc -l)" >> "$REPORT_DIR/01_estado_inicial.txt"
    echo "🎯 Paquetes explícitos: $(pacman -Qe | wc -l)" >> "$REPORT_DIR/01_estado_inicial.txt"
    echo "🏗️  Paquetes AUR: $(pacman -Qm | wc -l)" >> "$REPORT_DIR/01_estado_inicial.txt"
    
    # Verificar y esperar por pacman
    check_pacman_lock
    wait_for_pacman
    
    # 1. Actualizar base de datos de pacman
    log_info "Actualizando base de datos de pacman..."
    if sudo pacman -Syy --noconfirm; then
        log_success "Base de datos actualizada"
    else
        log_error "Falló la actualización de la base de datos"
        log_info "Intentando liberar bloqueo de pacman..."
        sudo rm -f /var/lib/pacman/db.lck
        if sudo pacman -Syy --noconfirm; then
            log_success "Base de datos actualizada después de liberar bloqueo"
        else
            log_error "Falló definitivamente la actualización"
            exit 1
        fi
    fi
    
    # 2. Actualizar todos los paquetes
    log_info "Actualizando todos los paquetes del sistema..."
    if sudo pacman -Syu --noconfirm; then
        log_success "Paquetes actualizados correctamente"
    else
        log_warning "Falló la actualización completa, continuando con respaldo..."
    fi
    
    # 3. Actualizar paquetes AUR (si existe yay/paru)
    if command -v yay &> /dev/null; then
        log_info "Actualizando paquetes AUR con yay..."
        if yay -Syu --noconfirm; then
            log_success "Paquetes AUR actualizados"
        else
            log_warning "Hubo problemas con paquetes AUR (continuando...)"
        fi
    elif command -v paru &> /dev/null; then
        log_info "Actualizando paquetes AUR con paru..."
        if paru -Syu --noconfirm; then
            log_success "Paquetes AUR actualizados"
        else
            log_warning "Hubo problemas con paquetes AUR (continuando...)"
        fi
    else
        log_info "No se encontró yay/paru, omitiendo actualización AUR"
    fi
    
    # 4. Limpiar cache de pacman
    log_info "Limpiando cache de pacman..."
    if sudo pacman -Sc --noconfirm; then
        log_success "Cache limpiado"
    else
        log_warning "Problemas al limpiar cache (continuando...)"
    fi
    
    # 5. Identificar y eliminar paquetes huérfanos
    log_info "Buscando paquetes huérfanos..."
    ORPHANS=$(pacman -Qdtq 2>/dev/null || true)
    
    if [[ -n "$ORPHANS" ]]; then
        echo "Paquetes huérfanos encontrados:" > "$REPORT_DIR/05_paquetes_huerfanos.txt"
        echo "$ORPHANS" >> "$REPORT_DIR/05_paquetes_huerfanos.txt"
        log_warning "Encontrados $(echo "$ORPHANS" | wc -w) paquetes huérfanos"
        
        log_info "Eliminando paquetes huérfanos..."
        if sudo pacman -Rns --noconfirm $ORPHANS 2>/dev/null; then
            log_success "Paquetes huérfanos eliminados"
        else
            log_warning "Problemas al eliminar huérfanos (continuando...)"
        fi
    else
        echo "No se encontraron paquetes huérfanos" > "$REPORT_DIR/05_paquetes_huerfanos.txt"
        log_success "No hay paquetes huérfanos"
    fi
    
    # 6. Reporte final
    log_info "Generando reporte final..."
    echo "=== ESTADO FINAL ===" > "$REPORT_DIR/08_estado_final.txt"
    echo "📅 Fecha: $(date)" >> "$REPORT_DIR/08_estado_final.txt"
    echo "📦 Paquetes totales: $(pacman -Q | wc -l)" >> "$REPORT_DIR/08_estado_final.txt"
    echo "🎯 Paquetes explícitos: $(pacman -Qe | wc -l)" >> "$REPORT_DIR/08_estado_final.txt"
    echo "🏗️  Paquetes AUR: $(pacman -Qm | wc -l)" >> "$REPORT_DIR/08_estado_final.txt"
    
    echo ""
    log_success "=========================================="
    log_success "🎉 ACTUALIZACIÓN PRE-RESPALDO COMPLETADA"
    log_success "📦 Paquetes totales: $(pacman -Q | wc -l)"
    log_success "🎯 Paquetes explícitos: $(pacman -Qe | wc -l)"
    log_success "🏗️  Paquetes AUR: $(pacman -Qm | wc -l)"
    log_success "📁 Reportes en: $REPORT_DIR"
    log_success "=========================================="
}

# Manejo de señales
trap 'log_error "Script interrumpido"; exit 1' INT TERM

# Verificaciones iniciales
check_root
check_internet

# Ejecutar función principal
main "$@"
echo "✅ Actualización lista"