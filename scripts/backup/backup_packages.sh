#!/bin/bash
# --------------------------------------------
# SCRIPT: backup_packages.sh  
# DESCRIPCIÓN: Genera listas de todos los paquetes instalados
# USO: ./backup_packages.sh
# --------------------------------------------

echo "📦 Generando listas de paquetes..."
# Configuración con RUTAS RELATIVAS
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
PACKAGES_DIR="$PROJECT_ROOT/output/packages_lists"
REPORT_DIR="$PROJECT_ROOT/output/reports"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Función para mensajes de log con actitud
log_info() { echo -e "${BLUE}🔄 [INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}✅ [SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠️  [WARNING]${NC} $1"; }
log_error() { echo -e "${RED}❌ [ERROR]${NC} $1"; }
log_debug() { echo -e "${CYAN}🐛 [DEBUG]${NC} $1"; }

# Función para verificar si se ejecuta como root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Este script NO debe ejecutarse como root"
        exit 1
    fi
}

# Función principal
main() {
    log_info "Iniciando respaldo de paquetes..."
    log_info "Guardando en: $PACKAGES_DIR"
    
    # Crear directorios
    mkdir -p "$PACKAGES_DIR"
    mkdir -p "$REPORT_DIR"
    
    # 1. Generar listas de paquetes
    log_info "Generando listas de paquetes..."
    
    # Paquetes oficiales (explicitamente instalados)
    log_info "Buscando paquetes oficiales..."
    pacman -Qqe | grep -v "$(pacman -Qqm)" > "$PACKAGES_DIR/pacman_packages.txt"
    OFFICIAL_COUNT=$(wc -l < "$PACKAGES_DIR/pacman_packages.txt")
    log_success "📦 Paquetes oficiales: $OFFICIAL_COUNT"
    
    # Paquetes AUR
    log_info "Buscando paquetes AUR..."
    pacman -Qqm > "$PACKAGES_DIR/aur_packages.txt"
    AUR_COUNT=$(wc -l < "$PACKAGES_DIR/aur_packages.txt")
    log_success "🏗️  Paquetes AUR: $AUR_COUNT"
    
    # Lista completa (para referencia)
    pacman -Qq > "$PACKAGES_DIR/all_packages.txt"
    TOTAL_COUNT=$(wc -l < "$PACKAGES_DIR/all_packages.txt")
    log_success "📊 Total de paquetes: $TOTAL_COUNT"
    
    # 2. Crear script de reinstalación automática
    log_info "Creando script de reinstalación automática..."
    cat > "$PACKAGES_DIR/reinstall_packages.sh" << 'EOF'
#!/bin/bash
# ==============================================================================
# SCRIPT: reinstall_packages.sh - REINSTALACIÓN AUTOMÁTICA 🔥
# ==============================================================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}🔄 [INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}✅ [SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}❌ [ERROR]${NC} $1"; }

# Verificar archivos
if [ ! -f "pacman_packages.txt" ]; then
    log_error "No se encuentra pacman_packages.txt"
    exit 1
fi

if [ ! -f "aur_packages.txt" ]; then
    log_error "No se encuentra aur_packages.txt"
    exit 1
fi

log_info "Iniciando reinstalación de paquetes..."

# Instalar paquetes oficiales
log_info "Instalando paquetes oficiales..."
sudo pacman -S --needed --noconfirm - < pacman_packages.txt

# Instalar paquetes AUR (si existen)
if [ -s "aur_packages.txt" ]; then
    log_info "Instalando paquetes AUR..."
    
    # Verificar si tenemos yay o paru
    if command -v yay &> /dev/null; then
        yay -S --needed --noconfirm - < aur_packages.txt
    elif command -v paru &> /dev/null; then
        paru -S --needed --noconfirm - < aur_packages.txt
    else
        log_info "Instalando yay primero..."
        sudo pacman -S --needed git base-devel --noconfirm
        git clone https://aur.archlinux.org/yay-bin.git
        cd yay-bin && makepkg -si --noconfirm && cd ..
        yay -S --needed --noconfirm - < aur_packages.txt
    fi
fi

log_success "🎉 ¡Reinstalación completada!"
echo "=========================================="
echo "✅ Paquetes oficiales: $(wc -l < pacman_packages.txt)"
echo "✅ Paquetes AUR: $(wc -l < aur_packages.txt)"
echo "=========================================="
EOF

    # Hacer ejecutable el script de reinstalación
    chmod +x "$PACKAGES_DIR/reinstall_packages.sh"
    log_success "Script de reinstalación creado y hecho ejecutable"

    # 3. Reporte final
    log_info "Generando reporte de paquetes..."
    cat > "$REPORT_DIR/package_report.txt" << EOF
=== 📦 REPORTE DE PAQUETES ===
📅 Fecha: $(date)
👤 Usuario: $(whoami)
📊 Paquetes oficiales: $OFFICIAL_COUNT
🏗️  Paquetes AUR: $AUR_COUNT
📈 Total paquetes: $TOTAL_COUNT

=== 🎯 PAQUETES OFICIALES ===
$(head -10 "$PACKAGES_DIR/pacman_packages.txt")
... (total: $OFFICIAL_COUNT)

=== 🏗️  PAQUETES AUR ===
$(cat "$PACKAGES_DIR/aur_packages.txt")
EOF

    # Resultado final
    echo ""
    log_success "=========================================="
    log_success "🎉 ¡RESPALDO DE PAQUETES COMPLETADO!"
    log_success "📦 Paquetes oficiales: $OFFICIAL_COUNT"
    log_success "🏗️  Paquetes AUR: $AUR_COUNT" 
    log_success "📊 Total: $TOTAL_COUNT"
    log_success "📁 Archivos en: $PACKAGES_DIR"
    log_success "=========================================="
    
    # Mostrar archivos creados
    echo ""
    log_info "📋 Archivos generados:"
    ls -la "$PACKAGES_DIR" | grep -E "(.txt|.sh)$"
}

# Manejo de señales
trap 'log_error "Script interrumpido por el usuario"; exit 1' INT TERM

# Verificaciones iniciales
check_root

# Ejecutar función principal
main "$@"
echo "✅ Listas de paquetes generadas"