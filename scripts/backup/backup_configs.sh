#!/bin/bash
# --------------------------------------------
# SCRIPT: backup_configs.sh
# DESCRIPCIÓN: Respaldar toda la configuración de KDE y dotfiles (CON AMOR 💖)
# USO: ./backup_configs.sh
# --------------------------------------------

echo "🎨 Respaldando tu alma digital con mucho amor..."
# Configuración con RUTAS RELATIVAS Y PORTABLES 💫
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")" 
CONFIG_DIR="$PROJECT_ROOT/output/config_backup"
REPORT_DIR="$PROJECT_ROOT/output/reports"

# Colores para output con más alma 🌈
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
PINK='\033[1;35m'
HEART='\033[1;31m'
NC='\033[0m'

# Función para mensajes de log con mucho estilo y amor 💕
log_info() { echo -e "${BLUE}🔄 [INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}✅ [SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠️  [WARNING]${NC} $1"; }
log_error() { echo -e "${RED}❌ [ERROR]${NC} $1"; }
log_creative() { echo -e "${MAGENTA}🎨 [CREATIVE]${NC} $1"; }
log_love() { echo -e "${PINK}💖 [LOVE]${NC} $1"; }
log_heart() { echo -e "${HEART}💕 [ESSENCE]${NC} $1"; }

# Función para verificar si se ejecuta como root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Este script NO debe ejecutarse como root - tu esencia merece cuidado personal 💝"
        exit 1
    fi
}

# Función para respaldar directorio con amor y cuidado ✨
backup_dir() {
    local source_dir="$1"
    local target_dir="$2"
    local description="$3"
    
    if [ -d "$source_dir" ]; then
        log_love "Resguardando $description con cariño..."
        mkdir -p "$target_dir"
        if cp -r "$source_dir"/* "$target_dir/" 2>/dev/null; then
            log_success "💝 $description protegido con amor"
            return 0
        else
            log_warning "Algunos archivos de $description fueron tímidos y no se copiaron"
            return 1
        fi
    else
        log_warning "No existe: $source_dir - pero está bien, seguimos con amor 💫"
        return 2
    fi
}

# Función para crear un reporte bonito 📝
create_beautiful_report() {
    local total_files=$(find "$CONFIG_DIR" -type f 2>/dev/null | wc -l || echo "0")
    local total_size=$(du -sh "$CONFIG_DIR" 2>/dev/null | cut -f1 || echo "0B")
    
    cat > "$REPORT_DIR/config_report.txt" << EOF
=== 🎨 REPORTE DE TU ESENCIA DIGITAL ===
📅 Fecha: $(date +"%Y-%m-%d %H:%M:%S")
👤 Usuario: $(whoami) 💕
🐧 Kernel: $(uname -r) 🐧

=== 📊 ESTADÍSTICAS DEL ALMA ===
Archivos respaldados: $total_files 📦
Tamaño total del alma: $total_size 💾

=== 🌟 JOYAS RESGUARDADAS CON AMOR ===
✅ Configuración completa de KDE Plasma
✅ Temas e iconos que te hacen único  
✅ Wallpapers que inspiran tu día
✅ Perfiles de terminal con tu esencia
✅ Configuraciones que te definen

=== 💌 MENSAJE ESPECIAL ===
"Tu configuración no son solo archivos, 
son horas de personalización, gustos únicos 
y pedazos de tu personalidad digital. 
¡Todo protegido con mucho amor! 💖"

=== 📍 DONDE VIVE TU ESENCIA ===
Todo guardado con cuidado en: $CONFIG_DIR
EOF
}

# Función principal llena de amor 💖
main() {
    log_heart "=================================================="
    log_heart "🌟 INICIANDO RESGUARDO DE TU ESENCIA DIGITAL 🌟"
    log_heart "🔮 Guardando cada detalle con mucho cariño en:"
    log_heart "   $CONFIG_DIR"
    log_heart "=================================================="
    
    # Crear directorios con amor
    mkdir -p "$CONFIG_DIR" || { log_error "No pude crear el nido para tu esencia"; exit 1; }
    mkdir -p "$REPORT_DIR" || { log_error "No pude crear el diario de tu alma digital"; exit 1; }
    
    log_love "Preparando todo con cuidado..."
    
    # 1. 📁 CONFIGURACIÓN DE KDE PLASMA (¡TU ALMA VISUAL!) 
    log_heart "Resguardando tu KDE Plasma - tu huella digital única..."
    
    backup_dir "$HOME/.config" "$CONFIG_DIR/config" "tu mundo .config"
    backup_dir "$HOME/.local/share" "$CONFIG_DIR/local_share" "tus archivos locales" 
    backup_dir "$HOME/.kde" "$CONFIG_DIR/kde" "el corazón de KDE"
    
    # 2. 🎨 ELEMENTOS ESPECÍFICOS DE KDE (TUS JOYAS)
    log_heart "Buscando tus joyitas más preciadas..."
    
    # Wallpapers personalizados (tus paisajes favoritos)
    if [ -d "$HOME/Imágenes/Wallpapers" ] || [ -d "$HOME/Images/Wallpapers" ]; then
        [ -d "$HOME/Imágenes/Wallpapers" ] && backup_dir "$HOME/Imágenes/Wallpapers" "$CONFIG_DIR/wallpapers" "tus wallpapers inspiradores"
        [ -d "$HOME/Images/Wallpapers" ] && backup_dir "$HOME/Images/Wallpapers" "$CONFIG_DIR/wallpapers" "tus wallpapers inspiradores"
    fi
    
    # Temas e iconos (tu estilo único)
    backup_dir "$HOME/.local/share/plasma" "$CONFIG_DIR/plasma" "tus temas de plasma"
    backup_dir "$HOME/.local/share/icons" "$CONFIG_DIR/icons" "tus iconos personalizados"
    backup_dir "$HOME/.local/share/themes" "$CONFIG_DIR/themes" "tus temas GTK"
    
    # 3. ⚙️ CONFIGURACIONES ESPECÍFICAS (TUS PREFERENCIAS)
    log_heart "Resguardando tus preferencias únicas..."
    
    # Konsole (tu terminal personalizado)
    if [ -d "$HOME/.local/share/konsole" ]; then
        backup_dir "$HOME/.local/share/konsole" "$CONFIG_DIR/konsole" "tus perfiles de konsole"
    fi
    
    # KWin (cómo te gusta que se comporten tus ventanas)
    if [ -f "$HOME/.config/kwinrc" ]; then
        cp "$HOME/.config/kwinrc" "$CONFIG_DIR/" 2>/dev/null && log_success "💝 Configuración de KWin resguardada"
    fi
    
    # 4. 🔐 CONFIGURACIONES CRÍTICAS (TUS LLAVES)
    log_heart "Protegiendo tus llaves digitales..."
    
    # SSH y GPG
    [ -d "$HOME/.ssh" ] && backup_dir "$HOME/.ssh" "$CONFIG_DIR/ssh" "tus llaves SSH"
    [ -d "$HOME/.gnupg" ] && backup_dir "$HOME/.gnupg" "$CONFIG_DIR/gnupg" "tus llaves GPG"
    
    # 5. 📊 CREAR REPORTE CON AMOR
    log_heart "Creando el diario de tu esencia digital..."
    create_beautiful_report

    # Resultado final EPICO y LLENO DE AMOR 💖
    echo ""
    log_heart "=================================================="
    log_heart "🎉 ¡RESGUARDO DE TU ALMA DIGITAL COMPLETADO! 🎉"
    log_heart "✨ Tu esencia está ahora segura y protegida ✨"
    log_heart "📦 Tamaño de tu alma digital: $(du -sh "$CONFIG_DIR" | cut -f1)"
    log_heart "📁 Fragmentos de tu esencia: $(find "$CONFIG_DIR" -type f 2>/dev/null | wc -l)"
    log_heart "📍 Tu esencia vive en: $CONFIG_DIR"
    log_heart "=================================================="
    
    # Mostrar estructura creada con cariño
    echo ""
    log_love "🌳 Estructura de tu jardín digital:"
    if command -v tree &> /dev/null; then
        tree "$CONFIG_DIR" -L 2 -C || ls -la "$CONFIG_DIR"
    else
        ls -la "$CONFIG_DIR"
    fi
    
    echo ""
    log_love "💖 Recuerda: Esta copia contiene pedazos de tu creatividad y personalidad."
    log_love "   Guárdala con el mismo amor con que la creaste. 💝"
}

# Manejo de señales con delicadeza
trap 'log_error "Interrumpido... pero tu esencia merece cuidado. Intenta luego 💕"; exit 1' INT TERM

# Verificaciones iniciales con amor
check_root

# Ejecutar función principal con todo el amor del mundo 💖
main "$@"
echo ""
log_heart "✅ Tu configuración fue resguardada con todo el amor que merece 💝"