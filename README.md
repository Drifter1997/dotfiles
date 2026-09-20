# 🚀 Arch Linux Minimal to Full Sway Desktop — Disaster Recovery Suite

A completely automated, reproducible disaster recovery and dotfiles suite for **Arch Linux** featuring **Sway (Wayland)**, **Waybar**, **Foot**, **LazyVim**, **Yazi**, **SwayOSD**, and **ZRAM**.

If your system crashes or you want to rebuild from scratch:
1. Perform a minimal Arch Linux install in under 5 minutes using `archinstall`.
2. Run `./install.sh`.
3. Your desktop, keybindings, power rules, audio, wallpapers, and tools are restored **identically**.

---

## 📑 Table of Contents
1. [Archinstall Step-by-Step Settings (Minimal Install)](#-1-archinstall-step-by-step-settings-minimal-install)
2. [Restoring Your System After Minimal Install](#-2-restoring-your-system-after-minimal-install)
   - [Method A: From GitHub / GitLab](#method-a-from-git-repository)
   - [Method B: From Local Drive or USB Drive](#method-b-from-local-drive-or-usb)
   - [Method C: Directly from Google Drive (Rclone)](#method-c-directly-from-google-drive)
3. [Google Drive Cloud Backup with Rclone](#-3-google-drive-cloud-backup-with-rclone)
4. [Taking Backups in the Future](#-4-taking-backups-in-the-future)
5. [What Gets Restored](#-5-what-gets-restored)
6. [Desktop Keybindings & Shortcuts Cheat Sheet](#-6-desktop-keybindings--shortcuts-cheat-sheet)

---

## 🛠️ 1. Archinstall Step-by-Step Settings (Minimal Install)

Boot from the official Arch Linux installation USB/ISO and type:
```bash
archinstall
```

Follow these exact choices in the interactive menu:

| Menu Entry | Recommended Choice | Explanation |
|---|---|---|
| **Archinstall language** | `English` | Default |
| **Mirrors** | Choose your Country / Closest region | Fast download speed |
| **Locales** | `en_US.UTF-8` | Default UTF-8 locale |
| **Disk configuration** | Select your internal drive (e.g. `/dev/nvme0n1`) | Use `Wipe all selected drives` -> filesystem `ext4` (or keep your existing `/home` partition if dual-partitioned) |
| **Disk encryption** | `None` (or user preference) | Optional |
| **Bootloader** | `systemd-boot` (or `GRUB`) | `systemd-boot` is modern, fast, and simple for UEFI |
| **Unified Kernel Images** | `False` | Standard kernel image setup |
| **Swap** | `False` / `No swap` | **Do not select swap** (our recovery script automatically configures high-speed zram via `zram-generator` with `zstd`) |
| **Hostname** | `archlinux` | Or your preferred hostname |
| **Root password** | Set a password | Administrator password |
| **User account** | Add user `joji` -> Set password -> **Sudo: YES** | **Crucial:** Mark user as superuser / sudo (`wheel` group) |
| **Profile** | **`Minimal`** | **CRITICAL:** Do **NOT** pick Desktop, Sway, or GNOME here. Selecting Minimal ensures no bloat or conflicting display managers. The script installs everything cleanly. |
| **Audio** | **`Pipewire`** | Configures modern low-latency PipeWire audio stack |
| **Kernels** | `linux` (and `intel-ucode`) | Standard stable Linux kernel + Intel microcode |
| **Network configuration**| **`NetworkManager`** | **Crucial:** Ensures WiFi (`nmtui`) and Ethernet work out of the box |
| **Timezone** | Your local timezone (e.g., `Asia/Kolkata`) | Correct system clock |
| **Automatic time sync** | `True` (systemd-timesyncd) | Keeps system time accurate |
| **Additional packages** | `git` | Optional, saves time during first boot |

Select **Install** -> Press **Enter** to proceed -> When finished, choose **Reboot**.

---

## 🔄 2. Restoring Your System After Minimal Install

Boot into your fresh minimal Arch install and log in at the TTY1 prompt with your username and password.

### Step 1: Connect to the Internet
If using Wi-Fi, connect using NetworkManager's terminal UI:
```bash
nmtui
```
*(Select "Activate a connection" -> Select your Wi-Fi -> Enter password)*

Verify your connection:
```bash
ping -c 2 archlinux.org
```

---

### Step 2: Obtain Your Dotfiles & Run `./install.sh`

Choose whichever method is most convenient:

#### Method A: From Git Repository (Recommended)
If you pushed this `dotfiles` repo to GitHub or GitLab:
```bash
sudo pacman -S --needed --noconfirm git
git clone https://github.com/Drifter1997/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

#### Method B: From Local Drive or USB
If you kept `/home` unformatted or saved `arch-backup-latest.tar.gz` to a USB drive:
```bash
# If from USB, mount it first or copy the archive to ~:
cd ~
tar -xzf arch-backup-latest.tar.gz
cd dotfiles
chmod +x install.sh
./install.sh
```

#### Method C: Directly from Google Drive
If you backed up to Google Drive using `rclone`:
```bash
sudo pacman -S --needed --noconfirm rclone
rclone config
# (Follow prompts to set up 'gdrive', see Section 3)
rclone copy gdrive:ArchLinux-Backup/arch-backup-latest.tar.gz ~/
cd ~
tar -xzf arch-backup-latest.tar.gz
cd dotfiles
chmod +x install.sh
./install.sh
```

---

### Step 3: Launch Your Desktop
Once `install.sh` finishes, everything is set:
```bash
exec sway
# Or reboot:
sudo reboot
```
> Since `~/.bash_profile` contains auto-start logic for tty1, logging in will automatically start your Sway desktop!

---

## ☁️ 3. Google Drive Cloud Backup with Rclone

We have provided an automated sync script `rclone-sync.sh` and pre-installed `rclone`.

### Initial One-Time Setup (Connect Google Drive)
Run the setup helper:
```bash
cd ~/dotfiles
./rclone-sync.sh setup
```
Or directly run `rclone config`:
1. Enter `n` (New remote)
2. Name: `gdrive`
3. Storage type: `drive` (Google Drive)
4. Client ID & Secret: Leave blank (Press `Enter` twice)
5. Scope: `1` (Full access to all files)
6. Service Account: Leave blank (Press `Enter`)
7. Edit advanced config: `n`
8. Automatically authenticate with browser: `y`
   *(Firefox will open. Sign in to your Google Account and click "Allow")*
9. Configure as Shared Drive: `n`
10. Confirm and Keep: `y`, then `q` to quit.

### Uploading / Syncing Backups to Google Drive
Whenever you want to backup your latest setup to Google Drive:
```bash
cd ~/dotfiles
./rclone-sync.sh push
```
This will:
- Create a fresh compressed archive `arch-backup-latest.tar.gz` and timestamped archive in `gdrive:ArchLinux-Backup/archives/`.
- Synchronize your entire `dotfiles/` directory to `gdrive:ArchLinux-Backup/dotfiles/` so you can view individual configs on Google Drive.

### Listing Backups on Google Drive
```bash
./rclone-sync.sh list
```

### Downloading Backup on a Fresh Machine
```bash
./rclone-sync.sh pull
```

---

## 💾 4. Taking Backups in the Future

Whenever you customize a config, tweak your Waybar, add wallpapers, or install new software:

```bash
cd ~/dotfiles
./backup.sh
```
What `./backup.sh` does automatically:
1. Exports current package lists from `pacman` and `yay` (`packages/pacman.txt`, `packages/aur.txt`).
2. Syncs all your `~/.config` directories (Sway, Waybar, Foot, Neovim, SwayOSD, Mako, Yazi, Thunar, etc.).
3. Dumps your current GTK / dconf dark theme settings.
4. Syncs your wallpapers from `~/Pictures/wallpapers`.
5. Syncs system rules from `/etc/udev/rules.d/`, `/etc/systemd/zram-generator.conf`, `/etc/sudoers.d/`, and `/usr/local/bin/*`.
6. Generates a new compressed archive:
   - `~/dotfiles/backups/arch-backup-<timestamp>.tar.gz`
   - `~/arch-backup-latest.tar.gz` (quick-access backup on your local drive)
7. If Google Drive is configured, automatically syncs to the cloud!

### To push your updates to GitHub:
```bash
cd ~/dotfiles
git add .
git commit -m "Update configs & packages"
git push
```

---

## 📦 5. What Gets Restored

| Component | Description |
|---|---|
| **Window Manager** | Sway (Wayland tiling compositor) with smooth scaling & wallpaper daemon |
| **Status Bar** | Waybar with custom idle inhibitor, battery, backlight, network, power mode, and audio modules |
| **Terminal** | Foot with custom dark OLED color palette & font configuration |
| **Editor** | Neovim with full LazyVim IDE configuration |
| **File Managers** | Yazi (terminal file manager with image previews) & Thunar (GUI file manager with custom actions) |
| **Notifications & OSD** | Mako (Wayland notification daemon) & SwayOSD (capsule OSD for volume & brightness) |
| **Session Control** | Wlogout (lock, suspend, reboot, shutdown) & Swaylock |
| **Memory / ZRAM** | Systemd ZRAM generator (zstd compression, RAM/2 allocation) |
| **Power Management** | `power-profiles-daemon` with automatic AC/Battery switching via custom Udev rules |
| **Audio** | Pipewire + Wireplumber + Pipewire-Pulse + Wiremix TUI mixer |
| **Bluetooth** | Bluez + Bluetuith TUI controller + auto-enabled service |
| **Wallpapers** | All 22 custom wallpapers in `~/Pictures/wallpapers` with `current_wallpaper` symlink |
| **Shell & Helpers** | Bash with custom `ytplay` function (Sixel video thumbnail previews + MPV audio streaming) |
| **Custom Scripts** | `idle-toggle`, `powermode-toggle`, `power-profile-auto`, `agyd`, `mpv`, `set-wallpaper.sh` |

---

## ⌨️ 6. Desktop Keybindings & Shortcuts Cheat Sheet

| Keybinding | Action |
|---|---|
| <kbd>Mod4</kbd> + <kbd>Return</kbd> | Open Foot Terminal |
| <kbd>Mod4</kbd> + <kbd>Space</kbd> / <kbd>Mod4</kbd> + <kbd>d</kbd> | Open Application Launcher (`wmenu`) |
| <kbd>Mod4</kbd> + <kbd>w</kbd> / <kbd>Mod4</kbd> + <kbd>Shift</kbd> + <kbd>q</kbd> | Close / Kill Focused Window |
| <kbd>Mod4</kbd> + <kbd>b</kbd> | Launch Firefox |
| <kbd>Mod4</kbd> + <kbd>Shift</kbd> + <kbd>Alt</kbd> + <kbd>b</kbd> | Launch Firefox in Private Window |
| <kbd>Mod4</kbd> + <kbd>Shift</kbd> + <kbd>f</kbd> | Launch Yazi File Manager (Floating popup) |
| <kbd>Mod4</kbd> + <kbd>Shift</kbd> + <kbd>w</kbd> | Wi-Fi Manager (`nmtui` popup) |
| <kbd>Mod4</kbd> + <kbd>Shift</kbd> + <kbd>b</kbd> | Bluetooth Manager (`bluetuith` popup) |
| <kbd>Mod4</kbd> + <kbd>Shift</kbd> + <kbd>m</kbd> / <kbd>Mod4</kbd> + <kbd>Ctrl</kbd> + <kbd>a</kbd> | Audio Mixer (`wiremix` popup) |
| <kbd>Mod4</kbd> + <kbd>Ctrl</kbd> + <kbd>Delete</kbd> | System Monitor (`btop` popup) |
| <kbd>Mod4</kbd> + <kbd>Ctrl</kbd> + <kbd>p</kbd> | Toggle Power Mode (Performance ⚡ / Power-Saver 🍃) |
| <kbd>Mod4</kbd> + <kbd>Shift</kbd> + <kbd>i</kbd> | Toggle Idle Lock (Inhibit screen sleep) |
| <kbd>Mod4</kbd> + <kbd>Escape</kbd> | Power Menu (`wlogout`) |
| <kbd>Mod4</kbd> + <kbd>f</kbd> / <kbd>F11</kbd> | Fullscreen Toggle |
| <kbd>Mod4</kbd> + <kbd>Shift</kbd> + <kbd>Space</kbd> | Floating Window Toggle |
| <kbd>Print</kbd> | Interactive Area Screenshot (`slurp` + `grim` -> `~/Pictures/`) |
| <kbd>XF86AudioRaiseVolume</kbd> / <kbd>Lower</kbd> | Adjust Volume via SwayOSD |
| <kbd>XF86MonBrightnessUp</kbd> / <kbd>Down</kbd> | Adjust Brightness via SwayOSD |
| In **Yazi**: select image and press <kbd>W</kbd> | Set as desktop wallpaper immediately |
| In **Terminal**: type `ytplay <search query>` | Interactive YouTube audio streamer with foot sixel thumbnails |
