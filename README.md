# 🚀 Arch Linux Sway — Minimal Keyboard & Terminal-Centric Setup

> **A reproducible, ultra-fast, and minimal Wayland desktop built around pure keyboard workflows, tiling window management, Foot terminal, Neovim, and custom-crafted CLI tools.**

[![Arch Linux](https://img.shields.io/badge/OS-Arch%20Linux-blue.svg?logo=arch-linux)](https://archlinux.org)
[![Window Manager](https://img.shields.io/badge/WM-Sway%20(Wayland)-green.svg)](https://swaywm.org)
[![Terminal](https://img.shields.io/badge/Terminal-Foot%20(Sixel)-orange.svg)](https://codeberg.org/dnkl/foot)
[![Editor](https://img.shields.io/badge/Editor-Neovim%20(LazyVim)-57A143.svg?logo=neovim)](https://neovim.io)
[![Workflow](https://img.shields.io/badge/Workflow-100%25%20Keyboard%20%26%20Terminal-purple.svg)]()

---

## 🎯 Philosophy & Overview

This setup is engineered for speed, minimalism, and uninterrupted focus. Every application in this ecosystem is **terminal- and keyboard-centric**, eliminating heavy GUI frameworks, Electron bloat, and mouse dependency:

- **100% Keyboard-Driven**: Window navigation, workspaces, media playback, audio mixing, networking, and chats are controlled entirely via intuitive keybindings.
- **Wayland Native**: Built on **Sway**, **Foot**, **Waybar**, and **SwayOSD** for tear-free rendering, fractional scaling, and minimal resource usage (~400MB base idle RAM).
- **Custom-Crafted CLI Ecosystem**: Custom terminal tools built from scratch for Instagram DMs, TikTok streaming, Slowed + Reverb music production, and YouTube audio streaming.

---

## 🛠️ Custom-Crafted CLI Tools

Alongside standard Unix utilities, this environment integrates custom terminal applications designed specifically for keyboard and terminal workflows:

| Tool | Description | Highlights |
|---|---|---|
| 📱 [**`i-cli`**](https://github.com/Drifter1997/i-cli) | **Minimal Instagram CLI / TUI** | Vanish Mode (`shh_mode`), RAM-only ephemeral media playback (`imv`/`mpv`), voice note mic recording, inline terminal thumbnails (`chafa`), and isolated credential storage (`~/.config/i-cli/session.json`). |
| 🎬 [**`tik-cli`**](https://github.com/Drifter1997/tik-cli) | **Terminal TikTok Client** | In-terminal video playback with Sixel/TrueColor graphics (`mpv`), 0-login browsing for FYP & creator channels, zero disk writes (100% RAM tmpfs), and vim-style navigation. |
| 🎧 [**`slowed-cli`**](https://github.com/Drifter1997/slowed-cli) | **Slowed + Reverb Audio Studio** | YouTube search, `librosa` dynamic BPM & brightness analysis, Spotify `pedalboard` 32-bit DSP engine with bass-protection filters, and 320kbps MP3 exports with album artwork. |
| 🎵 **`ytplay`** | **YouTube Sixel Audio Streamer** | Built directly into `~/.bashrc`. Features `fzf` fuzzy interactive search, high-res Sixel video thumbnails, and background MPV audio streaming. |

---

## 💻 Terminal & Keyboard Applications Stack

| Category | Application | Role |
|---|---|---|
| **Window Manager** | [Sway](https://swaywm.org/) | Wayland i3-compatible tiling compositor with vi-style navigation. |
| **Terminal** | [Foot](https://codeberg.org/dnkl/foot) | Fast, lightweight Wayland terminal with native Sixel graphics support. |
| **Status Bar** | [Waybar](https://github.com/Alexays/Waybar) | Highly customized bar with battery, backlight, network, power mode, and audio modules. |
| **Code Editor** | [Neovim](https://neovim.io/) + [LazyVim](https://www.lazyvim.org/) | Fully configured modal IDE for blazing-fast development. |
| **File Manager** | [Yazi](https://github.com/sxyazi/yazi) | Async terminal file manager with inline image previews and custom wallpaper hotkey (`W`). |
| **Audio Mixer** | [WireMix](https://github.com/Guekka/wiremix) | TUI mixer for PipeWire volume, stream routing, and device control. |
| **Bluetooth** | [Bluetuith](https://github.com/darkhz/bluetuith) | TUI Bluetooth manager for pairing and device connection. |
| **Networking** | [Nmtui](https://wiki.archlinux.org/title/NetworkManager) | Interactive terminal Wi-Fi and Ethernet connection manager. |
| **System Monitor**| [Btop](https://github.com/aristocratos/btop) | TUI system resource monitor (CPU, memory, disks, processes). |
| **Calculator** | [Tical](https://github.com/ryanoasis/tical) | Terminal calculator floating popup. |
| **OSD & Feedback**| [SwayOSD](https://github.com/ErikReider/SwayOSD) | Capsule on-screen indicators for volume, brightness, and caps lock. |
| **Power Daemon** | `power-profiles-daemon` | Automated Performance ⚡ / Power-Saver 🍃 switching on AC/battery events. |
| **Memory** | `systemd-zram-generator` | High-speed zstd compressed swap in RAM for smooth multitasking. |

---

## ⌨️ Desktop Keybindings & Hotkeys

### Window & Workspace Management
| Keybinding | Action |
|---|---|
| <kbd>Mod4</kbd> + <kbd>Return</kbd> | Launch Foot Terminal |
| <kbd>Mod4</kbd> + <kbd>Space</kbd> / <kbd>Mod4</kbd> + <kbd>d</kbd> | Application Launcher (`wmenu`) |
| <kbd>Mod4</kbd> + <kbd>w</kbd> / <kbd>Mod4</kbd> + <kbd>Shift</kbd> + <kbd>q</kbd> | Close / Kill Focused Window |
| <kbd>Mod4</kbd> + <kbd>h</kbd> / <kbd>j</kbd> / <kbd>k</kbd> / <kbd>l</kbd> | Focus Left / Down / Up / Right (Vim keys) |
| <kbd>Mod4</kbd> + <kbd>Shift</kbd> + <kbd>h</kbd> / <kbd>j</kbd> / <kbd>k</kbd> / <kbd>l</kbd> | Move Window Left / Down / Up / Right |
| <kbd>Mod4</kbd> + <kbd>1</kbd> - <kbd>9</kbd> | Switch to Workspace 1-9 |
| <kbd>Mod4</kbd> + <kbd>Shift</kbd> + <kbd>1</kbd> - <kbd>9</kbd> | Move Window to Workspace 1-9 |
| <kbd>Mod4</kbd> + <kbd>f</kbd> / <kbd>F11</kbd> | Toggle Fullscreen |
| <kbd>Mod4</kbd> + <kbd>Shift</kbd> + <kbd>Space</kbd> | Toggle Floating Window |
| <kbd>Mod4</kbd> + <kbd>Escape</kbd> | Power Menu (`wlogout`: Lock, Suspend, Reboot, Shutdown) |

### Terminal Popup Tools (Instant TUI Access)
| Keybinding | Action |
|---|---|
| <kbd>Mod4</kbd> + <kbd>Shift</kbd> + <kbd>f</kbd> | Launch **Yazi** File Manager (Popup) |
| <kbd>Mod4</kbd> + <kbd>Shift</kbd> + <kbd>m</kbd> / <kbd>Mod4</kbd> + <kbd>Ctrl</kbd> + <kbd>a</kbd> | Launch **WireMix** Audio Mixer (Popup) |
| <kbd>Mod4</kbd> + <kbd>Shift</kbd> + <kbd>w</kbd> | Launch **Nmtui** Wi-Fi Manager (Popup) |
| <kbd>Mod4</kbd> + <kbd>Shift</kbd> + <kbd>b</kbd> | Launch **Bluetuith** Bluetooth Manager (Popup) |
| <kbd>Mod4</kbd> + <kbd>Ctrl</kbd> + <kbd>Delete</kbd> | Launch **Btop** System Monitor (Popup) |
| <kbd>Mod4</kbd> + <kbd>Shift</kbd> + <kbd>c</kbd> | Launch **Tical** Calculator (Popup) |
| <kbd>Mod4</kbd> + <kbd>Ctrl</kbd> + <kbd>p</kbd> | Toggle Power Profile (Performance / Power-Saver) |
| <kbd>Mod4</kbd> + <kbd>Shift</kbd> + <kbd>i</kbd> | Toggle Idle Lock (Inhibit screen blanking) |

### Media & Hardware
| Key | Action |
|---|---|
| <kbd>XF86AudioRaiseVolume</kbd> / <kbd>Lower</kbd> | Volume Up / Down via SwayOSD |
| <kbd>XF86AudioMute</kbd> | Mute Audio via SwayOSD |
| <kbd>XF86MonBrightnessUp</kbd> / <kbd>Down</kbd> | Brightness Up / Down via SwayOSD |
| <kbd>Print</kbd> | Screenshot Area (`slurp` + `grim` saved to `~/Pictures/`) |
| In **Yazi**: press <kbd>W</kbd> | Set selected image as desktop wallpaper immediately |

---

## 🚀 Fresh Installation on Arch Linux

### Step 1: Minimal Arch Linux Base (5 Minutes)
Boot from an official Arch Linux installation USB and run:
```bash
archinstall
```

Recommended settings:
- **Audio**: `PipeWire`
- **Network**: `NetworkManager`
- **Profile**: `Minimal` (no desktop pre-installed)
- **Time sync**: `systemd-timesyncd`
- **User**: Add your primary user with sudo privileges

Reboot into your minimal Arch system and log in at the TTY1 prompt.

### Step 2: Clone Dotfiles & Run Automated Installer
```bash
# 1. Connect to Wi-Fi if needed
nmtui

# 2. Install git
sudo pacman -S --needed --noconfirm git

# 3. Clone this repository
git clone https://github.com/Drifter1997/dotfiles.git ~/dotfiles

# 4. Run the setup script
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

### Step 3: Launch Your Desktop
Once `install.sh` finishes:
```bash
exec sway
# Or reboot:
sudo reboot
```
*(Logging in on TTY1 will automatically start your Sway session via `~/.bash_profile`.)*

---

## ☁️ Cloud & Local Backup Automation

### Google Drive Synchronization via Rclone
This suite includes `rclone-sync.sh` for backing up and restoring your configurations directly with Google Drive:

```bash
cd ~/dotfiles

# One-time Google Drive authentication
./rclone-sync.sh setup

# Upload dotfiles and latest system archive to Google Drive
./rclone-sync.sh push

# Restore from Google Drive on a fresh machine
./rclone-sync.sh pull

# View existing cloud backups
./rclone-sync.sh list
```

### Future Backups
Whenever you tweak your configurations, install new packages, or add wallpapers:
```bash
cd ~/dotfiles
./backup.sh
```
`./backup.sh` automatically:
1. Updates package lists for both `pacman` and AUR (`yay`).
2. Syncs your latest `~/.config` files (Sway, Waybar, Foot, Neovim, Yazi, SwayOSD, etc.).
3. Dumps GTK/dconf dark mode preferences.
4. Syncs custom systemd and udev rules.
5. Generates compressed backup archives (`~/arch-backup-latest.tar.gz`).
6. Syncs changes to Google Drive if configured.

---

## 📁 Repository Structure

```
dotfiles/
├── config/             # TUI & desktop configs (~/.config)
│   ├── sway/          # Sway tiling WM keybindings, rules, and daemons
│   ├── waybar/        # Minimal top bar styling and JSON modules
│   ├── foot/          # Foot terminal settings (Sixel graphics, OLED dark theme)
│   ├── nvim/          # Full LazyVim Neovim configuration
│   ├── yazi/          # Yazi terminal file manager keymaps and flavors
│   ├── mako/          # Wayland notification styling
│   ├── swayosd/       # On-screen volume and brightness pill display
│   └── ...
├── home/              # User home files (.bashrc, .bash_profile with auto-start)
├── packages/          # Complete pacman and AUR package manifests
├── pictures/          # Wallpapers and assets
├── system/            # System-level configs (/etc/udev, zram, sudoers, scripts)
├── install.sh         # One-step automated environment installer
├── backup.sh          # Automated system configuration extractor
├── rclone-sync.sh     # Google Drive synchronization script
└── README.md
```

---

## 📄 License

MIT License. Designed with precision for minimal, keyboard-first computing.
