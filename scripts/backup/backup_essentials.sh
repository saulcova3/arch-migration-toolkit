#!/bin/bash
# --------------------------------------------
# SCRIPT: backup_essentials.sh
# DESCRIPCIÓN: Respaldar SSH, GPG y configuraciones críticas
# USO: ./backup_essentials.sh
# --------------------------------------------

echo "🔐 Respaldando claves y configuraciones críticas..."
# Configuración con RUTAS RELATIVAS
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"  
ESSENTIALS_DIR="$PROJECT_ROOT/output/essentials"
REPORT_DIR="$PROJECT_ROOT/output/reports"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Funciones de log
log_info() { echo -e "${BLUE}🔄 [INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}✅ [SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠️  [WARNING]${NC} $1"; }
log_error() { echo -e "${RED}❌ [ERROR]${NC} $1"; }
log_secret() { echo -e "${MAGENTA}💎 [SECRET]${NC} $1"; }

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "No ejecutar como root"
        exit 1
    fi
}

# Función principal
main() {
    log_secret "Iniciando respaldo de TESOROS PERSONALES..."
    log_secret "Guardando en: $ESSENTIALS_DIR"
    
    mkdir -p "$ESSENTIALS_DIR"
    mkdir -p "$REPORT_DIR"
    
    # 1. 🔐 CLAVES SSH (Accesos remotos)
    log_secret "Respaldando claves SSH..."
    if [ -d "$HOME/.ssh" ]; then
        mkdir -p "$ESSENTIALS_DIR/ssh"
        cp -r "$HOME/.ssh/"* "$ESSENTIALS_DIR/ssh/" 2>/dev/null && \
        log_success "Claves SSH respaldadas" || \
        log_warning "Algunas claves SSH no se copiaron"
    else
        log_warning "No hay claves SSH para respaldar"
    fi
    
    # 2. 🔑 CLAVES GPG (Firma y encriptación)
    log_secret "Respaldando claves GPG..."
    if [ -d "$HOME/.gnupg" ]; then
        mkdir -p "$ESSENTIALS_DIR/gnupg"
        cp -r "$HOME/.gnupg/"* "$ESSENTIALS_DIR/gnupg/" 2>/dev/null && \
        log_success "Claves GPG respaldadas" || \
        log_warning "Algunas claves GPG no se copiaron"
    else
        log_warning "No hay claves GPG para respaldar"
    fi
    
    # 3. 📝 SCRIPTS PERSONALES (Tu magia)
    log_secret "Buscando scripts personales..."
    if [ -d "$HOME/.local/bin" ]; then
        mkdir -p "$ESSENTIALS_DIR/local_bin"
        cp -r "$HOME/.local/bin/"* "$ESSENTIALS_DIR/local_bin/" 2>/dev/null && \
        log_success "Scripts personales respaldados" || \
        log_warning "Algunos scripts no se copiaron"
    fi
    
    # 4. 🌐 CONFIGURACIONES DE RED (WiFi, VPN)
    log_secret "Respaldando configuraciones de red..."
    if [ -d "/etc/NetworkManager/system-connections" ]; then
        mkdir -p "$ESSENTIALS_DIR/network"
        sudo cp -r "/etc/NetworkManager/system-connections/"* "$ESSENTIALS_DIR/network/" 2>/dev/null && \
        log_success "Configuraciones de red respaldadas" || \
        log_warning "No se pudieron copiar configuraciones de red"
    fi
    
    # 5. 📦 REPOSITORIOS AUR PERSONALES (Si tienes)
    log_secret "Buscando repositorios AUR locales..."
    if [ -d "$HOME/aur" ] || [ -d "$HOME/builds" ]; then
        mkdir -p "$ESSENTIALS_DIR/aur_repos"
        [ -d "$HOME/aur" ] && cp -r "$HOME/aur/"* "$ESSENTIALS_DIR/aur_repos/" 2>/dev/null
        [ -d "$HOME/builds" ] && cp -r "$HOME/builds/"* "$ESSENTIALS_DIR/aur_repos/" 2>/dev/null
        log_success "Repositorios AUR respaldados"
    fi
    
    # 6. 📋 REPORTE FINAL
    log_secret "Generando reporte de tesoros..."
    cat > "$REPORT_DIR/essentials_report.txt" << EOF
=== 💎 REPORTE DE TESOROS PERSONALES ===
📅 Fecha: $(date)
👤 Usuario: $(whoami)

=== 📊 INVENTARIO ===
Claves SSH: $(find "$ESSENTIALS_DIR/ssh" -type f 2>/dev/null | wc -l || echo "0")
Claves GPG: $(find "$ESSENTIALS_DIR/gnupg" -type f 2>/dev/null | wc -l || echo "0")
Scripts personales: $(find "$ESSENTIALS_DIR/local_bin" -type f 2>/dev/null | wc -l || echo "0")
Configs red: $(find "$ESSENTIALS_DIR/network" -type f 2>/dev/null | wc -l || echo "0")
Repos AUR: $(find "$ESSENTIALS_DIR/aur_repos" -type f 2>/dev/null | wc -l || echo "0")

=== 🚨 IMPORTANTE ===
Estos archivos contienen información sensible.
Mantén este directorio seguro y encriptado si es posible.
EOF

    # Resultado final
    echo ""
    log_secret "=========================================="
    log_secret "💎 ¡TESOROS PERSONALES RESPALDADOS!"
    log_secret "🔐 Claves SSH y GPG seguras"
    log_secret "📝 Scripts personales guardados" 
    log_secret "🌐 Configuraciones de red protegidas"
    log_secret "📦 Repositorios AUR asegurados"
    log_secret "📍 Ubicación: $ESSENTIALS_DIR"
    log_secret "=========================================="
    
    # Mostrar contenido
    echo ""
    log_info "📋 Contenido respaldado:"
    tree "$ESSENTIALS_DIR" -L 2 2>/dev/null || ls -la "$ESSENTIALS_DIR"
}

# Ejecutar
check_root
main "$@"
echo "✅ Elementos críticos respaldados"