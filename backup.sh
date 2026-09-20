#!/usr/bin/env bash
# ==============================================================================
# Arch Linux System & Dotfiles Backup Script
# Captures system state, packages, configs, scripts, and creates local & cloud backups
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DATE="$(date +%Y%m%d_%H%M%S)"
ARCHIVE_NAME="arch-backup-${BACKUP_DATE}.tar.gz"
BACKUP_DIR="$SCRIPT_DIR/backups"

# Styling
BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

log_info()    { echo -e "${BLUE}${BOLD}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}${BOLD}[OK]${RESET}   $1"; }
log_warn()    { echo -e "${YELLOW}${BOLD}[WARN]${RESET} $1"; }
log_error()   { echo -e "${RED}${BOLD}[ERROR]${RESET} $1"; }

echo -e "${BOLD}======================================================${RESET}"
echo -e "${BOLD}         Arch Linux System & Dotfiles Backup          ${RESET}"
echo -e "${BOLD}======================================================${RESET}\n"

# 1. Update Package Lists
log_info "Exporting installed packages list..."
mkdir -p "$SCRIPT_DIR/packages"
pacman -Qqe | grep -vFf <(pacman -Qqm 2>/dev/null || true) | sort > "$SCRIPT_DIR/packages/pacman.txt"
# Ensure essential base dependencies are explicitly captured
for pkg in libnotify playerctl git base-devel; do
    if ! grep -q "^$pkg$" "$SCRIPT_DIR/packages/pacman.txt"; then
        echo "$pkg" >> "$SCRIPT_DIR/packages/pacman.txt"
    fi
done
sort -u "$SCRIPT_DIR/packages/pacman.txt" -o "$SCRIPT_DIR/packages/pacman.txt"

# Export AUR packages (excluding debug symbols)
pacman -Qqm 2>/dev/null | grep -v "\-debug$" | sort > "$SCRIPT_DIR/packages/aur.txt" || true
log_success "Package lists updated ($(wc -l < "$SCRIPT_DIR/packages/pacman.txt") pacman, $(wc -l < "$SCRIPT_DIR/packages/aur.txt") AUR)."

# 2. Sync Configuration Files (~/.config)
log_info "Synchronizing ~/.config files..."
mkdir -p "$SCRIPT_DIR/config"
CONFIG_DIRS=(
    bluetuith btop foot gtk-3.0 gtk-4.0 mako mpv nvim onlyoffice
    sway swaylock swayosd systemd Thunar waybar wlogout wofi xfce4 yay yazi
)

for dir in "${CONFIG_DIRS[@]}"; do
    if [ -d "$HOME/.config/$dir" ]; then
        rm -rf "$SCRIPT_DIR/config/$dir"
        cp -r "$HOME/.config/$dir" "$SCRIPT_DIR/config/"
    fi
done

if [ -f "$HOME/.config/mimeapps.list" ]; then
    cp "$HOME/.config/mimeapps.list" "$SCRIPT_DIR/config/"
fi

# Dump GNOME / GTK dconf
if command -v dconf >/dev/null 2>&1; then
    mkdir -p "$SCRIPT_DIR/config/dconf"
    dconf dump / > "$SCRIPT_DIR/config/dconf/dconf-settings.ini"
fi
log_success "~/.config synchronization complete."

# 3. Sync User Shell & Desktop Files
log_info "Synchronizing user dotfiles and desktop entries..."
mkdir -p "$SCRIPT_DIR/home/.local/share/applications"
[ -f "$HOME/.bashrc" ] && cp "$HOME/.bashrc" "$SCRIPT_DIR/home/.bashrc"
[ -f "$HOME/.bash_profile" ] && cp "$HOME/.bash_profile" "$SCRIPT_DIR/home/.bash_profile"

if [ -d "$HOME/.local/share/applications" ]; then
    cp -r "$HOME/.local/share/applications/"* "$SCRIPT_DIR/home/.local/share/applications/" 2>/dev/null || true
fi
log_success "Shell and application entries synchronized."

# 4. Sync Wallpapers
log_info "Synchronizing wallpapers..."
mkdir -p "$SCRIPT_DIR/pictures/wallpapers"
if [ -d "$HOME/Pictures/wallpapers" ]; then
    cp -r "$HOME/Pictures/wallpapers/"* "$SCRIPT_DIR/pictures/wallpapers/" 2>/dev/null || true
    log_success "Wallpapers synchronized ($(ls -1 "$SCRIPT_DIR/pictures/wallpapers" | wc -l) files)."
fi

# 5. Sync System Configurations & Custom Scripts
log_info "Synchronizing system files (/etc and /usr/local/bin)..."
mkdir -p "$SCRIPT_DIR/system/etc/systemd"
mkdir -p "$SCRIPT_DIR/system/etc/udev/rules.d"
mkdir -p "$SCRIPT_DIR/system/etc/sudoers.d"
mkdir -p "$SCRIPT_DIR/system/usr/local/bin"

[ -f /etc/pacman.conf ] && cp /etc/pacman.conf "$SCRIPT_DIR/system/etc/pacman.conf"
[ -f /etc/systemd/zram-generator.conf ] && cp /etc/systemd/zram-generator.conf "$SCRIPT_DIR/system/etc/systemd/zram-generator.conf" 2>/dev/null || true
[ -d /etc/udev/rules.d ] && cp /etc/udev/rules.d/*.rules "$SCRIPT_DIR/system/etc/udev/rules.d/" 2>/dev/null || true

if sudo -n test -f /etc/sudoers.d/010_nopasswd 2>/dev/null; then
    sudo cp /etc/sudoers.d/010_nopasswd "$SCRIPT_DIR/system/etc/sudoers.d/" 2>/dev/null || true
    sudo chown "$USER:$USER" "$SCRIPT_DIR/system/etc/sudoers.d/010_nopasswd" 2>/dev/null || true
fi

for s in agyd idle-toggle mpv powermode-toggle power-profile-auto power-profile-auto-check; do
    if [ -f "/usr/local/bin/$s" ]; then
        cp "/usr/local/bin/$s" "$SCRIPT_DIR/system/usr/local/bin/"
    fi
done
log_success "System configurations synchronized."

# 6. Create Local Compressed Archives (.tar.gz and .zip for USB)
log_info "Creating compressed disaster recovery archives..."
mkdir -p "$BACKUP_DIR"
ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE_NAME"
LATEST_LINK="$HOME/arch-backup-latest.tar.gz"
ZIP_PATH="$BACKUP_DIR/arch-setup-${BACKUP_DATE}.zip"
LATEST_ZIP="$HOME/arch-setup.zip"

tar -czf "$ARCHIVE_PATH" \
    --exclude='.git' \
    --exclude='backups' \
    --exclude='*.log' \
    -C "$(dirname "$SCRIPT_DIR")" "$(basename "$SCRIPT_DIR")"

cp "$ARCHIVE_PATH" "$LATEST_LINK"

# Create .zip archive (ideal for extracting directly onto a USB drive)
(
    cd "$SCRIPT_DIR"
    zip -r -q -9 "$ZIP_PATH" . -x ".git/*" "backups/*" "*.log"
)
cp "$ZIP_PATH" "$LATEST_ZIP"

log_success "Archives created successfully:"
echo -e "   -> ${YELLOW}$ARCHIVE_PATH${RESET}"
echo -e "   -> ${YELLOW}$LATEST_LINK${RESET} (Tarball archive)"
echo -e "   -> ${YELLOW}$LATEST_ZIP${RESET} (USB-ready .zip archive: extract and run ./install.sh)"

# 7. Google Drive Cloud Sync via Rclone (Opt-in with --cloud)
CLOUD_FLAG="${1:-}"
if [ "$CLOUD_FLAG" = "--cloud" ]; then
    if [ -f "$SCRIPT_DIR/rclone-sync.sh" ]; then
        log_info "Initiating Google Drive synchronization..."
        bash "$SCRIPT_DIR/rclone-sync.sh" push || log_warn "Google Drive sync encountered an issue. Run './rclone-sync.sh setup' to configure."
    fi
else
    log_info "Google Drive sync was skipped. (Pass ${YELLOW}--cloud${RESET} to upload to Google Drive)."
fi

# 8. Git Status
if [ -d "$SCRIPT_DIR/.git" ]; then
    echo -e "\n${BOLD}--- Git Repository Status ---${RESET}"
    git -C "$SCRIPT_DIR" status --short
fi

echo -e "\n${GREEN}${BOLD}Backup process completed successfully!${RESET}\n"
