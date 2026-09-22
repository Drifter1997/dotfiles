#!/usr/bin/env bash
# ==============================================================================
# Arch Linux Sway Minimal Keyboard & Terminal-Centric Setup Installer
# Restores Sway, Waybar, Foot, Themes, Wallpapers, ZRAM, Audio, Udev, Packages, and Custom CLI Tools
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/arch_restore_$(date +%Y%m%d_%H%M%S).log"

# Styling
BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

log_info()    { echo -e "${BLUE}${BOLD}[INFO]${RESET} $1" | tee -a "$LOG_FILE"; }
log_success() { echo -e "${GREEN}${BOLD}[OK]${RESET}   $1" | tee -a "$LOG_FILE"; }
log_warn()    { echo -e "${YELLOW}${BOLD}[WARN]${RESET} $1" | tee -a "$LOG_FILE"; }
log_error()   { echo -e "${RED}${BOLD}[ERROR]${RESET} $1" | tee -a "$LOG_FILE"; }

echo -e "${BOLD}====================================================================${RESET}"
echo -e "${BOLD}   Arch Linux Sway Minimal Keyboard & Terminal-Centric Installer    ${RESET}"
echo -e "${BOLD}====================================================================${RESET}"
echo -e "Detailed logs will be saved to: ${YELLOW}${LOG_FILE}${RESET}\n"

# 1. Safety check: Run as normal user with sudo permissions
if [ "$(id -u)" -eq 0 ]; then
    log_error "This script must NOT be run directly as root. Run it as your regular user with sudo privileges!"
    exit 1
fi

log_info "Verifying sudo permissions..."
sudo -v
# Keep sudo alive during installation
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# 2. Check Internet Connectivity
log_info "Testing internet connection..."
if ! ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1 && ! curl -s -m 5 https://archlinux.org >/dev/null 2>&1; then
    log_error "No internet connection detected!"
    echo "Please connect to the internet first (e.g. run 'nmtui' for Wi-Fi) and rerun this script."
    exit 1
fi
log_success "Internet connection is active."

# 3. Optimize pacman configuration
log_info "Optimizing /etc/pacman.conf (ParallelDownloads, Color)..."
sudo sed -i 's/^#Color/Color/' /etc/pacman.conf 2>/dev/null || true
sudo sed -i 's/^#ParallelDownloads = .*/ParallelDownloads = 5/' /etc/pacman.conf 2>/dev/null || true
if ! grep -q "^ParallelDownloads" /etc/pacman.conf; then
    sudo sed -i '/^\[options\]/a ParallelDownloads = 5' /etc/pacman.conf
fi
if ! grep -q "^Color" /etc/pacman.conf; then
    sudo sed -i '/^\[options\]/a Color' /etc/pacman.conf
fi

log_info "Synchronizing pacman package databases..."
sudo pacman -Sy --noconfirm >> "$LOG_FILE" 2>&1

# 4. Install essential prerequisites
log_info "Installing base-devel, git, curl, and prerequisites..."
sudo pacman -S --needed --noconfirm base-devel git curl wget >> "$LOG_FILE" 2>&1
log_success "Base tools installed."

# 5. Install yay (AUR Helper) if not already installed
if ! command -v yay >/dev/null 2>&1; then
    log_info "AUR helper 'yay' is not installed. Building and installing yay-bin..."
    BUILD_DIR="$(mktemp -d /tmp/yay-build-XXXXXX)"
    git clone https://aur.archlinux.org/yay-bin.git "$BUILD_DIR" >> "$LOG_FILE" 2>&1
    (
        cd "$BUILD_DIR"
        makepkg -si --noconfirm >> "$LOG_FILE" 2>&1
    )
    rm -rf "$BUILD_DIR"
    log_success "'yay' installed successfully."
else
    log_success "'yay' is already installed."
fi

# 6. Install Official Pacman Packages
if [ -f "$SCRIPT_DIR/packages/pacman.txt" ]; then
    log_info "Installing official packages from pacman.txt..."
    # Read non-empty, non-comment lines
    mapfile -t PACMAN_PKGS < <(grep -vE '^\s*#|^\s*$' "$SCRIPT_DIR/packages/pacman.txt")
    if [ ${#PACMAN_PKGS[@]} -gt 0 ]; then
        sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" >> "$LOG_FILE" 2>&1 || {
            log_warn "Some pacman packages may have failed. Attempting individually..."
            for pkg in "${PACMAN_PKGS[@]}"; do
                sudo pacman -S --needed --noconfirm "$pkg" >> "$LOG_FILE" 2>&1 || log_warn "Package failed: $pkg"
            done
        }
        log_success "Official pacman packages installed."
    fi
else
    log_warn "packages/pacman.txt not found! Skipping pacman package bulk install."
fi

# 7. Install AUR Packages
if [ -f "$SCRIPT_DIR/packages/aur.txt" ]; then
    log_info "Installing AUR packages from aur.txt via yay..."
    mapfile -t AUR_PKGS < <(grep -vE '^\s*#|^\s*$' "$SCRIPT_DIR/packages/aur.txt")
    if [ ${#AUR_PKGS[@]} -gt 0 ]; then
        yay -S --needed --noconfirm "${AUR_PKGS[@]}" >> "$LOG_FILE" 2>&1 || {
            log_warn "Some AUR packages may have failed. Attempting individually..."
            for pkg in "${AUR_PKGS[@]}"; do
                yay -S --needed --noconfirm "$pkg" >> "$LOG_FILE" 2>&1 || log_warn "AUR Package failed: $pkg"
            done
        }
        log_success "AUR packages installed."
    fi
else
    log_warn "packages/aur.txt not found! Skipping AUR package install."
fi

# 8. Restore System Configurations & Scripts
log_info "Deploying system configuration files (/etc and /usr/local/bin)..."

# ZRAM configuration
if [ -f "$SCRIPT_DIR/system/etc/systemd/zram-generator.conf" ]; then
    sudo mkdir -p /etc/systemd
    sudo cp "$SCRIPT_DIR/system/etc/systemd/zram-generator.conf" /etc/systemd/zram-generator.conf
    sudo systemctl daemon-reload
    sudo systemctl enable --now /dev/zram0 2>/dev/null || true
    log_success "ZRAM configuration applied."
fi

# Udev rules (Backlight and Power profiles)
if [ -d "$SCRIPT_DIR/system/etc/udev/rules.d" ]; then
    sudo mkdir -p /etc/udev/rules.d
    sudo cp "$SCRIPT_DIR/system/etc/udev/rules.d/"*.rules /etc/udev/rules.d/ 2>/dev/null || true
    sudo udevadm control --reload-rules 2>/dev/null || true
    sudo udevadm trigger 2>/dev/null || true
    log_success "Udev rules deployed and reloaded."
fi

# Passwordless sudo for user (wheel group)
if [ -f "$SCRIPT_DIR/system/etc/sudoers.d/010_nopasswd" ]; then
    sudo mkdir -p /etc/sudoers.d
    # Replace hardcoded username if user running the script has a different username
    sed "s/joji/$USER/g" "$SCRIPT_DIR/system/etc/sudoers.d/010_nopasswd" | sudo tee /etc/sudoers.d/010_nopasswd > /dev/null
    sudo chmod 0440 /etc/sudoers.d/010_nopasswd
    log_success "Sudoers permissions configured."
fi

# Custom /usr/local/bin scripts
if [ -d "$SCRIPT_DIR/system/usr/local/bin" ]; then
    sudo mkdir -p /usr/local/bin
    sudo cp "$SCRIPT_DIR/system/usr/local/bin/"* /usr/local/bin/ 2>/dev/null || true
    sudo chmod +x /usr/local/bin/*
    # Ensure onlyoffice symlink exists if onlyoffice-desktopeditors is installed
    if [ -f "/usr/bin/onlyoffice-desktopeditors" ] && [ ! -e "/usr/local/bin/onlyoffice" ]; then
        sudo ln -sf /usr/bin/onlyoffice-desktopeditors /usr/local/bin/onlyoffice
    fi
    log_success "Custom /usr/local/bin scripts installed."
fi

# 9. User Groups & Permissions
log_info "Ensuring user is in required groups (video, wheel, input)..."
for grp in video wheel input; do
    if getent group "$grp" >/dev/null 2>&1; then
        sudo usermod -aG "$grp" "$USER"
    fi
done
log_success "User groups updated."

# 10. Enable System-wide Systemd Services
log_info "Enabling systemd system services..."
SYSTEM_SERVICES=(
    "NetworkManager.service"
    "bluetooth.service"
    "cups.service"
    "cups.path"
    "cups.socket"
    "power-profiles-daemon.service"
    "swayosd-libinput-backend.service"
    "systemd-timesyncd.service"
    "fstrim.timer"
)

for srv in "${SYSTEM_SERVICES[@]}"; do
    sudo systemctl enable "$srv" >> "$LOG_FILE" 2>&1 || log_warn "Could not enable system service: $srv"
done
log_success "System services enabled."

# 11. Restore User Dotfiles and Configs
log_info "Deploying user dotfiles to $HOME..."

# Backup existing config directory if it exists and has content
if [ -d "$HOME/.config" ] && [ "$(ls -A "$HOME/.config" 2>/dev/null)" ]; then
    BACKUP_TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
    log_info "Creating backup of existing ~/.config -> ~/.config.bak.$BACKUP_TIMESTAMP"
    cp -r "$HOME/.config" "$HOME/.config.bak.$BACKUP_TIMESTAMP"
fi

mkdir -p "$HOME/.config"
mkdir -p "$HOME/Pictures/wallpapers"
mkdir -p "$HOME/.local/share/applications"

# Copy configs
if [ -d "$SCRIPT_DIR/config" ]; then
    cp -r "$SCRIPT_DIR/config/"* "$HOME/.config/"
    log_success "~/.config restored."
fi

# Copy shell files
if [ -f "$SCRIPT_DIR/home/.bashrc" ]; then
    cp "$SCRIPT_DIR/home/.bashrc" "$HOME/.bashrc"
    log_success "~/.bashrc restored."
fi

if [ -f "$SCRIPT_DIR/home/.bash_profile" ]; then
    cp "$SCRIPT_DIR/home/.bash_profile" "$HOME/.bash_profile"
    log_success "~/.bash_profile restored."
fi

# Copy local applications
if [ -d "$SCRIPT_DIR/home/.local/share/applications" ]; then
    cp -r "$SCRIPT_DIR/home/.local/share/applications/"* "$HOME/.local/share/applications/" 2>/dev/null || true
    log_success "Desktop entries restored."
fi

# Copy Wallpapers
if [ -d "$SCRIPT_DIR/pictures/wallpapers" ]; then
    cp -r "$SCRIPT_DIR/pictures/wallpapers/"* "$HOME/Pictures/wallpapers/" 2>/dev/null || true
    log_success "Wallpapers restored to ~/Pictures/wallpapers."
fi

# Restore Wallpaper Symlink (Minimal single wallpaper setup)
DEFAULT_WP="$HOME/Pictures/wallpapers/calm-night-minimal.png"
if [ ! -f "$DEFAULT_WP" ]; then
    # Pick first available wallpaper if calm-night-minimal isn't present
    DEFAULT_WP="$(find "$HOME/Pictures/wallpapers" -type f | head -n 1)"
fi

if [ -n "$DEFAULT_WP" ] && [ -f "$DEFAULT_WP" ]; then
    mkdir -p "$HOME/.config/sway"
    ln -sf "$DEFAULT_WP" "$HOME/.config/sway/current_wallpaper"
    log_success "Wallpaper symlink configured."
fi

# Fix permissions on sway scripts
chmod +x "$HOME/.config/sway/set-wallpaper.sh" 2>/dev/null || true
chmod +x "$HOME/.config/sway/scripts/"* 2>/dev/null || true

# 12. Load Dconf Settings (Dark Mode, Scaling, etc.)
if [ -f "$SCRIPT_DIR/config/dconf/dconf-settings.ini" ] && command -v dconf >/dev/null 2>&1; then
    log_info "Applying GNOME/GTK dconf preferences..."
    dconf load / < "$SCRIPT_DIR/config/dconf/dconf-settings.ini" 2>/dev/null || true
    log_success "Dconf preferences loaded."
fi

# 13. Enable User Systemd Services
log_info "Configuring user-level systemd services..."
systemctl --user daemon-reload 2>/dev/null || true
USER_SERVICES=(
    "pipewire.service"
    "pipewire.socket"
    "pipewire-pulse.service"
    "pipewire-pulse.socket"
    "wireplumber.service"
    "xwayland-satellite.service"
)

for usrv in "${USER_SERVICES[@]}"; do
    systemctl --user enable "$usrv" >> "$LOG_FILE" 2>&1 || log_warn "Could not enable user service: $usrv"
done
log_success "User systemd units enabled."

# 14. Ensure bash is the user shell
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
if [ "$CURRENT_SHELL" != "/bin/bash" ] && [ "$CURRENT_SHELL" != "/usr/bin/bash" ]; then
    log_info "Setting default shell to bash..."
    sudo chsh -s /bin/bash "$USER" >> "$LOG_FILE" 2>&1 || true
fi

# 15. Configure Custom Terminal Tools Symlinks
log_info "Configuring custom terminal & keyboard-centric tools..."
mkdir -p "$HOME/.local/bin"
[ -f "$HOME/repo/i-cli/i-cli" ] && ln -sf "$HOME/repo/i-cli/i-cli" "$HOME/.local/bin/i-cli"
[ -f "$HOME/repo/tik-cli/tik-cli" ] && ln -sf "$HOME/repo/tik-cli/tik-cli" "$HOME/.local/bin/tik-cli"
[ -f "$HOME/Music/slowed/slowed" ] && ln -sf "$HOME/Music/slowed/slowed" "$HOME/.local/bin/slowed"
log_success "Custom tools symlinks verified in ~/.local/bin"

echo -e "\n${GREEN}${BOLD}====================================================================${RESET}"
echo -e "${GREEN}${BOLD}   Sway Minimal Keyboard Setup Completed Successfully!             ${RESET}"
echo -e "${GREEN}${BOLD}====================================================================${RESET}"
echo -e "Your Sway desktop environment, Waybar, Foot, Neovim, audio, and custom"
echo -e "terminal-centric tools (i-cli, tik-cli, slowed, ytplay) are ready."
echo -e "\nTo start your new desktop session, you can:"
echo -e "  1. Run:  ${YELLOW}exec sway${RESET}"
echo -e "  2. Or simply reboot: ${YELLOW}sudo reboot${RESET} (auto-starts Sway on tty1)\n"
