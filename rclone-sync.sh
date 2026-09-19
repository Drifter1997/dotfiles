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

    echo -e "You will now run the interactive rclone configuration."
    echo -e "Follow these quick steps:\n"
    echo -e "  1. Enter: ${YELLOW}n${RESET} (for New remote)"
    echo -e "  2. Name:  ${YELLOW}gdrive${RESET}"
    echo -e "  3. Type:  ${YELLOW}drive${RESET} (Google Drive)"
    echo -e "  4. client_id / client_secret: Press ${YELLOW}Enter${RESET} (leave blank)"
    echo -e "  5. Scope: Choose ${YELLOW}1${RESET} (Full access all files)"
    echo -e "  6. service_account_file: Press ${YELLOW}Enter${RESET} (leave blank)"
    echo -e "  7. Edit advanced config: Press ${YELLOW}n${RESET} (No)"
    echo -e "  8. Use web browser to automatically authenticate: Press ${YELLOW}y${RESET} (Yes)"
    echo -e "     -> Firefox will open. Sign in to your Google account and click Allow."
    echo -e "  9. Configure this as a Shared Drive: Press ${YELLOW}n${RESET} (No)"
    echo -e " 10. Confirm and Keep: Press ${YELLOW}y${RESET} then ${YELLOW}q${RESET} to quit.\n"
    
    read -rp "Press [Enter] to launch 'rclone config' now..."
    rclone config
    
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

    # 2. Upload latest and timestamped archives
    log_info "Uploading compressed backup archives..."
    rclone copy "$LATEST_ARCHIVE" "${REMOTE_DIR}/" --progress
    if [ -d "$SCRIPT_DIR/backups" ]; then
        rclone copy "$SCRIPT_DIR/backups/" "${REMOTE_DIR}/archives/" --progress
    fi
    log_success "Backup archive uploaded to Google Drive."

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

    log_info "Fetching arch-backup-latest.tar.gz..."
    rclone copy "${REMOTE_DIR}/arch-backup-latest.tar.gz" "$TARGET_DIR/" --progress
    log_success "Downloaded to: $TARGET_DIR/arch-backup-latest.tar.gz"

    echo -e "\nTo unpack and install this backup on a minimal Arch system, run:"
    echo -e "   ${YELLOW}cd $TARGET_DIR${RESET}"
    echo -e "   ${YELLOW}tar -xzf arch-backup-latest.tar.gz${RESET}"
    echo -e "   ${YELLOW}cd dotfiles${RESET}"
    echo -e "   ${YELLOW}./install.sh${RESET}\n"
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
