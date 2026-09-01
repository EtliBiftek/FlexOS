#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

def text(rel):
    return (ROOT/rel).read_text(encoding='utf-8')

def check(value,message):
    if not value:raise AssertionError(message)

ctx=text('config/includes.chroot/usr/share/flexos/calamares/modules/contextualprocess-flexdesktop.conf')
dots=text('config/includes.chroot/usr/share/flexos/calamares/modules/contextualprocess-hyprdots.conf')
hook=text('config/hooks/live/020-flexos-calamares.hook.chroot')
installer=text('config/includes.chroot/usr/lib/flexos/flex-desktop-install')
post=text('config/includes.chroot/usr/lib/flexos/flex-postinstall')
packages=text('config/package-lists/flexos.list.chroot')

# Calamares must pass the account created by the users module, not the live/root environment USER.
check('${gs[username]}' in ctx,'desktop installer does not receive Calamares username')
check('${USER}' not in ctx,'desktop installer still depends on shell USER')
check('${gs[username]}' in dots and '${USER}' not in dots,'Hyprland dots are not bound to installed username')

# The desktop jobs must run even when a Debian Calamares sequence has no sources-final job.
check('if not insert_after("- sources-final", exec_jobs):' in hook,'desktop exec jobs have no sources-final fallback')
check('insert_before("- umount", exec_jobs)' in hook,'desktop exec jobs are not guaranteed before target unmount')
check('raise SystemExit("Calamares exec sequence has no safe insertion point for FlexOS desktop jobs")' in hook,'missing fail-closed Calamares insertion check')

# GNOME must be a complete Debian desktop and provide a real Wayland session.
for token in ('task-gnome-desktop','gnome-core','gdm3','gnome-session','gnome-shell','xdg-desktop-portal-gnome'):
    check(f'"{token}"' in installer,f'GNOME profile missing {token}')
check('/usr/share/wayland-sessions/gnome.desktop' in installer,'GNOME session is not verified')

# Hyprland needs compositor, portal, Xwayland, session helpers, auth agent and a safe user config.
for token in ('hyprland','uwsm','quickshell','xdg-desktop-portal-hyprland','hypridle','hyprlock','hyprpaper','hyprpolkitagent','xwayland','pipewire','wireplumber','libpam-systemd','dbus-user-session'):
    check(f'"{token}"' in installer,f'Hyprland profile missing {token}')
check('/usr/share/wayland-sessions/hyprland.desktop' in installer,'Hyprland session is not verified')
check('/usr/share/wayland-sessions/hyprland-uwsm.desktop' in installer,'Hyprland UWSM session is not verified')
check('prepare_hyprland_user()' in installer,'Hyprland has no baseline per-user configuration')

# The live image disables APT recommends, so login-session plumbing must be explicit.
check('libpam-systemd' in packages,'live image omits libpam-systemd despite disabled apt recommends')
check('dbus-user-session' in packages,'live image omits dbus-user-session despite disabled apt recommends')

# Debian display-manager state must be explicit and re-checked at post-install.
for source,name in ((installer,'desktop installer'),(post,'post-install')):
    check('/etc/X11/default-display-manager' in source,f'{name} does not set Debian default display manager')
    check('/etc/systemd/system/display-manager.service' in source,f'{name} does not set display-manager.service')
    check('graphical.target' in source,f'{name} does not force graphical boot target')

print('FlexOS desktop-selection regressions: OK')
