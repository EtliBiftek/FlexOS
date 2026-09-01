#!/usr/bin/env python3
from __future__ import annotations
import importlib.machinery
import importlib.util
import os
import re
import tempfile
import zipfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
USR=ROOT/'config/includes.chroot/usr'

def text(rel):
    return (ROOT/rel).read_text(encoding='utf-8')

def load(name,rel):
    path=ROOT/rel
    loader=importlib.machinery.SourceFileLoader(name,str(path))
    spec=importlib.util.spec_from_loader(name,loader)
    module=importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module

def check(condition,message):
    if not condition:raise AssertionError(message)

# Privileged-session authorization must be bound to the launcher process tree.
launch=text('config/includes.chroot/usr/bin/flex-session-launch')
priv=text('config/includes.chroot/usr/lib/flexos/flex-privileged-session')
check('--launcher-pid' in launch and '--launcher-pid' in priv,'launcher PID binding missing')
check('SO_PEERCRED' in priv and 'is_launcher_process' in priv,'peer process-tree authorization missing')
check('Peer credentials are unavailable; refusing privileged request.' in priv,'peer credential check must fail closed')

# Mirror input and APT source transformations must preserve trust boundaries.
mirror=load('flexos_test_mirror','config/includes.chroot/usr/bin/flex-mirror')
for bad in ('https://evil.example/debian','https://deb.debian.org/debian\nTrusted: yes','file:/tmp/repo/debian'):
    try:mirror.validate_mirror(bad)
    except SystemExit:pass
    else:raise AssertionError(f'unsafe mirror accepted: {bad!r}')
check(mirror.validate_mirror('https://deb.debian.org/debian/')=='https://deb.debian.org/debian','valid mirror normalization failed')
vendor='Types: deb\nURIs: https://vendor.example/repo\nSuites: stable\nComponents: vendor\n'
check(mirror.replace_sources_text(vendor,'https://ftp.de.debian.org/debian')==vendor,'mirror rewrite touched a third-party source')
msrc=text('config/includes.chroot/usr/bin/flex-mirror')
check("if BACKUP.exists():\n        return" in msrc,'mirror backup is not one-time')
check("subprocess.run(['apt-get','update'],check=True)" in msrc,'mirror update must be checked')

# Component updater must stage verified bytes as root, not install caller-owned /tmp files.
self_update=text('config/includes.chroot/usr/bin/flex-self-update')
admin=text('config/includes.chroot/usr/lib/flexos/flex-admin')
check('root-install' in self_update and 'flexos-update-root-' in self_update and 'dir="/var/tmp"' in self_update,'root-owned component staging missing')
check('SHA256 mismatch' in self_update and 'os.fsync' in self_update,'root-side package verification missing')
check('Legacy path-based component updates are disabled.' in admin,'legacy path-based update entrypoint still enabled')

# Hyprdots must never create an unrestricted sudo rule or execute upstream setup with it.
hypr=text('config/includes.chroot/usr/lib/flexos/flex-hyprdots-install')
check('NOPASSWD: ALL' not in hypr,'Hyprdots still grants unrestricted sudo')
check('sudoers' not in hypr.lower(),'Hyprdots still manipulates sudoers')
check('dots/.config' in hypr and 'dots/.local' in hypr,'pinned dotfile copy path missing')

# Secure Boot must fail closed when state/enrollment cannot be proven.
hwd=text('config/includes.chroot/usr/bin/flex-hwd')
check("return 'unknown'" in hwd and 'Cannot determine Secure Boot state safely' in hwd,'Secure Boot unknown state is not fail-closed')
check("['mokutil','--test-key',str(der)]" in hwd,'MOK enrollment is not verified')
install_pos=hwd.index("subprocess.run(['apt-get','install','-y','power-profiles-daemon','gamemode','mangohud'],check=True)")
state_pos=hwd.index("Path('/etc/flexos/handheld-profile').write_text")
check(install_pos<state_pos,'handheld success state is written before package install succeeds')

# Remote gaming assets need a mandatory GitHub SHA-256 digest; vendor sources stay untouched.
gaming=load('flexos_test_gaming','config/includes.chroot/usr/bin/flex-gaming')
try:gaming.download_asset({'name':'x','browser_download_url':'https://example.invalid/x','digest':''},Path('/tmp/never-created'))
except SystemExit:pass
else:raise AssertionError('gaming asset without SHA-256 digest was accepted')
check(gaming.update_sources_text(vendor)==vendor,'gaming source edit touched a third-party Deb822 source')
debian='Types: deb\nURIs: https://deb.debian.org/debian\nSuites: trixie\nComponents: main\n'
updated=gaming.update_sources_text(debian)
check('contrib' in updated and 'non-free-firmware' in updated,'Debian components were not extended')
check('is_debian_archive_uri' in admin,'flex-admin lacks first-party Debian source filtering')

# scx-loader source must be pinned before build.
scx=text('config/includes.chroot/usr/bin/flex-scx')
m=re.search(r"SCX_LOADER_COMMIT='([0-9a-f]{40})'",scx)
check(bool(m),'scx-loader commit is not pinned to a full SHA')
check(m.group(1)=='368845eb73737ea280def513afe46f4447b8983f','unexpected scx-loader pin')
check("'checkout','--detach',SCX_LOADER_COMMIT" in scx,'pinned scx-loader checkout missing')

# Welcome must not acquire an administrator session until an actual privileged action is selected.
first=text('config/includes.chroot/usr/lib/flexos/flexos-first-login')
desktop=text('config/includes.chroot/usr/share/applications/flex-welcome.desktop')
check('flex-session-launch /usr/bin/flex-welcome' not in first,'first login still starts an eager privileged session')
check('Exec=/usr/bin/flex-welcome' in desktop,'Welcome desktop entry still starts an eager privileged session')

# Backup restore must bound decompression and report the selected desktop correctly.
flexsuite=load('flexos_test_suite','config/includes.chroot/usr/lib/flexos/flexsuite.py')
with tempfile.TemporaryDirectory() as td:
    td=Path(td)
    old_home=os.environ.get('HOME')
    os.environ['HOME']=str(td/'home')
    (td/'home').mkdir()
    try:
        archive=td/'oversize.zip'
        with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:z.writestr('files/.config/test',b'123456789')
        flexsuite.MAX_BACKUP_ENTRY=8
        try:flexsuite.restore_backup(archive)
        except ValueError:pass
        else:raise AssertionError('oversized backup entry was extracted')
        profile=td/'desktop-profile';profile.write_text('gnome\n')
        flexsuite.DESKTOP_PROFILE=profile
        check(flexsuite.current_desktop()=='GNOME','backup desktop metadata is not profile-aware')
    finally:
        if old_home is None:os.environ.pop('HOME',None)
        else:os.environ['HOME']=old_home

print('FlexOS userland security regressions: OK')
