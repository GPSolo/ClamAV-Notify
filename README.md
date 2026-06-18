# Real-Time Malware Scanning for Wayland/Hyprland (ClamAV + systemd + D-Bus)

## Overview
A lightweight on-access antivirus layer for Arch-based Wayland desktops (built for CachyOS + Hyprland), using ClamAV's `clamonacc` daemon, a `systemd` user service for lifecycle management, and native desktop notifications delivered over D-Bus when a threat is detected.

Most on-access AV guides assume GNOME/KDE notification daemons. This fills the gap for wlroots-based compositors where `notify-send` / D-Bus session bus wiring isn't handled for you out of the box.

## Features
- Real-time file system scanning via `clamonacc` (no manual `clamscan` invocations)
- systemd user-level service — starts on login, restarts on failure
- D-Bus desktop notification on detection, including filename and signature name
- Configurable exclude paths to avoid scan storms on build directories / package caches
- Documented false-positive handling workflow (e.g. resolving a flagged security-tooling package without disabling protection)
## Architecture
```
clamav-daemon (daemon, malware scan service)
   │
   ▼
clamav-clamonacc (on-access service, watches fanotify events)
   │
   ▼
systemctl --user start clamav-notify (manages clamonacc notification)
   │
   ▼
notify-send / D-Bus session bus → Hyprland notification daemon (mako/dunst)
```

## Requirements
- Arch-based distro (tested on CachyOS) with Hyprland
- `clamav` (+ daemon)
- A D-Bus-aware notification daemon (`mako`, `dunst`, etc.)
- Kernel `fanotify` support (standard on modern kernels)
## Installation
```bash
sudo pacman -S clamav

sudo systemctl enable --now clamav-freshclam
sudo systemctl enable --now clamav-daemon
sudo systemctl enable --now clamav-clamonacc

cp clamonacc-notify.service ~/.config/systemd/user/
cp clamav-notify.sh ~/.local/bin/
systemctl --user enable --now clamonacc-notify.service
```

## Configuration
Add exclude paths relevant to your dev environment to `/etc/clamav/clamd.conf` to avoid false-positive scan storms:
```
OnAccessExcludePath ^/home/[user]/.cache
OnAccessExcludePath ^/home/[user]/dev/.*/node_modules
```

Also, in order to avoid clutter in the clamonacc.log file you might want to filter these files:
```
OnAccessExcludePath /etc/sudoers
OnAccessExcludePath /etc/sudoers.d
OnAccessExcludePath /etc/shadow
OnAccessExcludePath /etc/gshadow
```
This is because of the 'sudo' command and the files it needs to access to properly execute.

Lastly, to enable OnAccess scanning you must pass the paths you want to have scanned on access for the clamav daemon:
```
OnAccessMountPath / # Scan all files and directories
OnAccessMountPath /tmp # Scan temporary files
OnAccessMountPath /home/[user] # Scan home directory
```

## Known Issues / Lessons Learned
- `fanotify`-based scanning needs `CAP_SYS_ADMIN`; the systemd service uses scoped capabilities rather than running as root.
## License
MIT

