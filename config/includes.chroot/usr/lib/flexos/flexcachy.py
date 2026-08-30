#!/usr/bin/env python3
from __future__ import annotations
import json, os, platform, shutil, subprocess
from pathlib import Path


def run(cmd, timeout=15):
    try:
        p=subprocess.run(cmd,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=timeout)
        return p.returncode,(p.stdout or '').strip()
    except Exception as e:
        return 127,str(e)


def cmd(name): return shutil.which(name) is not None

def pkg(name):
    rc,_=run(['dpkg-query','-W','-f=${db:Status-Abbrev}',name])
    return rc==0

def service(name):
    if not cmd('systemctl'): return 'unavailable'
    rc,out=run(['systemctl','is-active',name])
    return 'active' if rc==0 else (out or 'inactive')

def sched_ext_available():
    return Path('/sys/kernel/sched_ext').exists() or Path('/sys/kernel/sched_ext/root/ops').exists()

def scx_status():
    lines=[f"sched_ext: {'available' if sched_ext_available() else 'unavailable'}",
           f"scx_loader: {service('scx_loader.service')}"]
    if cmd('scxctl'):
        rc,out=run(['scxctl','get'])
        lines.append('scxctl: '+(out if rc==0 and out else 'installed; no active scheduler'))
    else: lines.append('scxctl: not installed')
    cfg=Path('/etc/flexos/scx.json')
    if cfg.exists():
        try:
            d=json.loads(cfg.read_text())
            lines.append(f"configured: {d.get('scheduler','auto')} / {d.get('mode','Auto')} / enabled={d.get('enabled',False)}")
        except Exception: pass
    return '\n'.join(lines)

def ananicy_status():
    installed=cmd('ananicy-cpp')
    rules=Path('/etc/ananicy.d/00-default').exists()
    return f"ananicy-cpp: {'installed' if installed else 'not installed'}\nservice: {service('ananicy-cpp.service')}\nCachyOS rules: {'installed' if rules else 'not installed'}"

def gaming_status():
    packages=['gamemode','mangohud','goverlay','lutris','steam-installer','gamescope']
    lines=[f"{p}: {'installed' if pkg(p) else 'not installed'}" for p in packages]
    arches=run(['dpkg','--print-foreign-architectures'])[1]
    lines.append(f"i386 multiarch: {'enabled' if 'i386' in arches.split() else 'disabled'}")
    lines.append(f"umu-run: {'installed' if cmd('umu-run') else 'not installed'}")
    compat=Path.home()/'.local/share/Steam/compatibilitytools.d'
    proton=list(compat.glob('*Cachy*'))+list(compat.glob('*cachy*')) if compat.exists() else []
    lines.append(f"Proton-CachyOS: {'installed' if proton else 'not installed'}")
    lines.append(f"NTSYNC: {'available' if Path('/dev/ntsync').exists() or Path('/sys/module/ntsync').exists() else 'not active'}")
    return '\n'.join(lines)

def repo_status():
    p=Path('/etc/flexos/optimized-repo')
    level=cpu_level()
    selected=p.read_text(errors='ignore').strip() if p.exists() else 'baseline'
    return f"CPU ISA: {level}\nSelected FlexOS optimized repository: {selected}"

def cpu_level():
    try: flags=set(next(x.split(':',1)[1].split() for x in Path('/proc/cpuinfo').read_text(errors='ignore').splitlines() if x.startswith('flags')))
    except Exception: return 'baseline'
    v3={'avx','avx2','bmi1','bmi2','f16c','fma','movbe','xsave'}
    v4={'avx512f','avx512bw','avx512cd','avx512dq','avx512vl'}
    if v3|v4 <= flags: return 'x86-64-v4'
    if v3 <= flags: return 'x86-64-v3'
    return 'baseline'

def secureboot_status():
    sb='unknown'
    if cmd('mokutil'):
        _,out=run(['mokutil','--sb-state']); sb='enabled' if 'enabled' in out.lower() else 'disabled'
    key=Path('/var/lib/flexos/secureboot/MOK.key').exists()
    cert=Path('/var/lib/flexos/secureboot/MOK.der').exists()
    return f"Secure Boot: {sb}\nFlexOS MOK: {'prepared' if key and cert else 'not prepared'}"

def handheld_status():
    fields=[]
    for n in ('sys_vendor','product_name','product_version','board_name'):
        p=Path('/sys/class/dmi/id')/n
        try: fields.append(p.read_text(errors='ignore').strip())
        except Exception: pass
    s=' '.join(fields).lower()
    kind='none'
    if 'steam deck' in s or 'jupiter' in s or 'galileo' in s: kind='steam-deck'
    elif 'rog ally' in s or ('asus' in s and 'rc71' in s): kind='rog-ally'
    elif 'legion go' in s or ('lenovo' in s and '83e1' in s): kind='legion-go'
    elif any(x in s for x in ('ayaneo','gpd win','onexplayer')): kind='generic-handheld'
    return kind

def hwd_status():
    if not cmd('flex-hwd'): return 'flex-hwd unavailable'
    return run(['flex-hwd'],30)[1]

def extended_report():
    return '\n\n'.join([
        'CACHYOS-DERIVED PERFORMANCE\n'+scx_status(),
        'PROCESS PRIORITIZATION\n'+ananicy_status(),
        'GAMING STACK\n'+gaming_status(),
        'OPTIMIZED REPOSITORY\n'+repo_status(),
        'SECURE BOOT / MOK\n'+secureboot_status(),
        'HANDHELD PROFILE\n'+handheld_status(),
    ])
