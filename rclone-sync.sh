#!/usr/bin/env bash
# ==============================================================================
# Google Drive Backup & Recovery via Rclone
# Automates backing up your Arch Linux setup & archives directly to Google Drive
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE_NAME="${RCLONE_REMOTE:-gdrive}"
REMOTE_DIR="${REMOTE_NAME}:ArchLinux-Backup"

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

check_rclone() {
    if ! command -v rclone >/dev/null 2>&1; then
        log_warn "rclone is not installed. Installing via pacman..."
        sudo pacman -S --needed --noconfirm rclone
    fi
}

check_remote() {
    check_rclone
    if ! rclone listremotes 2>/dev/null | grep -q "^${REMOTE_NAME}:"; then
        log_error "Remote '${REMOTE_NAME}:' is not configured in rclone!"
        echo -e "\nPlease run the setup wizard to connect your Google Drive:"
        echo -e "   ${YELLOW}$0 setup${RESET}\n"
        exit 1
    fi
}

setup_remote() {
    check_rclone
    echo -e "${BOLD}======================================================${RESET}"
    echo -e "${BOLD}        Google Drive Setup Wizard for Rclone          ${RESET}"
    echo -e "${BOLD}======================================================${RESET}\n"
    
    if rclone listremotes 2>/dev/null | grep -q "^${REMOTE_NAME}:"; then
        log_success "Remote '${REMOTE_NAME}:' is already configured in rclone!"
        rclone about "${REMOTE_NAME}:" 2>/dev/null || true
        read -rp "Do you want to reconfigure it? [y/N]: " choice
        case "$choice" in
            [yY][eE][sS]|[yY]) ;;
            *) exit 0 ;;
        esac
    fi

    echo -e "Starting automated Google Drive authorization..."
    echo -e "Your web browser (Firefox) will open automatically."
    echo -e "Sign in to your Google Account and click ${BOLD}'Allow'${RESET} to grant access.\n"
    
    if rclone config create "${REMOTE_NAME}" drive; then
        log_success "Google Drive remote '${REMOTE_NAME}' configured successfully!"
    else
        log_warn "Automated authorization was interrupted. Launching interactive rclone config..."
        rclone config
    fi
    
    if rclone listremotes 2>/dev/null | grep -q "^${REMOTE_NAME}:"; then
        echo -e "\n${GREEN}${BOLD}Google Drive connection successful!${RESET}"
        rclone mkdir "${REMOTE_DIR}" 2>/dev/null || true
    else
        log_warn "Remote '${REMOTE_NAME}:' was not detected after configuration."
    fi
}

push_backup() {
    check_remote
    echo -e "${BOLD}Uploading backup to Google Drive (${REMOTE_DIR})...${RESET}\n"

    # 1. Ensure latest backup archive exists
    LATEST_ARCHIVE="$HOME/arch-backup-latest.tar.gz"
    if [ ! -f "$LATEST_ARCHIVE" ]; then
        log_info "Creating fresh backup archive first..."
        bash "$SCRIPT_DIR/backup.sh"
    fi

    # 2. Upload latest and timestamped archives (both .tar.gz and .zip)
    log_info "Uploading compressed backup archives (.tar.gz and .zip)..."
    rclone copy "$LATEST_ARCHIVE" "${REMOTE_DIR}/" --progress
    if [ -f "$HOME/arch-setup.zip" ]; then
        rclone copy "$HOME/arch-setup.zip" "${REMOTE_DIR}/" --progress
    fi
    if [ -d "$SCRIPT_DIR/backups" ]; then
        rclone copy "$SCRIPT_DIR/backups/" "${REMOTE_DIR}/archives/" --progress
    fi
    log_success "Backup archives uploaded to Google Drive."

    # 3. Sync dotfiles tree directly (for easy browsing and individual file recovery)
    log_info "Syncing dotfiles folder structure to ${REMOTE_DIR}/dotfiles/..."
    rclone sync "$SCRIPT_DIR" "${REMOTE_DIR}/dotfiles/" \
        --exclude=".git/**" \
        --exclude="backups/**" \
        --exclude="*.log" \
        --progress
    log_success "Dotfiles tree synced."

    echo -e "\n${GREEN}${BOLD}Google Drive upload complete!${RESET}"
    echo -e "Your backup is safely stored in: ${YELLOW}${REMOTE_DIR}${RESET}\n"
}

pull_backup() {
    check_remote
    echo -e "${BOLD}Downloading latest backup from Google Drive...${RESET}\n"
    TARGET_DIR="${1:-$HOME}"
    mkdir -p "$TARGET_DIR"

    log_info "Fetching arch-setup.zip and arch-backup-latest.tar.gz..."
    rclone copy "${REMOTE_DIR}/arch-setup.zip" "$TARGET_DIR/" --progress 2>/dev/null || true
    rclone copy "${REMOTE_DIR}/arch-backup-latest.tar.gz" "$TARGET_DIR/" --progress 2>/dev/null || true
    log_success "Downloaded to: $TARGET_DIR"

    echo -e "\nTo unpack and install this backup on a minimal Arch system, run:"
    echo -e "   ${YELLOW}cd $TARGET_DIR${RESET}"
    echo -e "   ${YELLOW}unzip -q arch-setup.zip -d dotfiles && cd dotfiles && ./install.sh${RESET}"
    echo -e "   (Or: ${YELLOW}tar -xzf arch-backup-latest.tar.gz && cd dotfiles && ./install.sh${RESET})\n"
}

list_backups() {
    check_remote
    echo -e "${BOLD}Contents of ${REMOTE_DIR}:${RESET}\n"
    rclone lsf "${REMOTE_DIR}" || true
    echo -e "\n${BOLD}Archives available:${RESET}"
    rclone lsf "${REMOTE_DIR}/archives/" 2>/dev/null || true
}

usage() {
    echo -e "Usage: $0 [setup|push|pull|list]"
    echo -e ""
    echo -e "Commands:"
    echo -e "  setup   - Connect your Google Drive account with rclone"
    echo -e "  push    - Upload latest local backup & dotfiles to Google Drive"
    echo -e "  pull    - Download the latest backup from Google Drive to restore"
    echo -e "  list    - View existing backups stored on Google Drive"
    echo -e ""
}

case "${1:-}" in
    setup)
        setup_remote
        ;;
    push)
        push_backup
        ;;
    pull)
        pull_backup "${2:-$HOME}"
        ;;
    list)
        list_backups
        ;;
    *)
        usage
        exit 1
        ;;
esac
