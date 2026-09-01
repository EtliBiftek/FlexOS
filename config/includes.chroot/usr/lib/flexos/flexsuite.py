#!/usr/bin/env python3
from __future__ import annotations
import json, os, platform, shutil, subprocess, time, zipfile
from pathlib import Path

APPS=Path("/usr/share/flexos/apps.json")
PROFILE=Path("/etc/flexos/profile")
IDENTITY=Path("/usr/share/flexos/identity.json")
DESKTOP_PROFILE=Path("/etc/flexos/desktop-profile")
MAX_BACKUP_ENTRY=64*1024*1024
MAX_BACKUP_TOTAL=256*1024*1024
MAX_BACKUP_RATIO=200

def run(cmd,timeout=12):
    try:
        p=subprocess.run(cmd,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=timeout)
        return p.returncode,(p.stdout or "").strip()
    except subprocess.TimeoutExpired:
        return 124,"Zaman aşımı"
    except Exception as e:
        return 127,str(e)

def command(x): return shutil.which(x) is not None

def load_json(p,d=None):
    try:return json.loads(Path(p).read_text(encoding="utf-8"))
    except Exception:return {} if d is None else d

def identity(): return load_json(IDENTITY)

def current_profile():
    try:return PROFILE.read_text().strip() or "balanced"
    except Exception:return "balanced"

def current_desktop():
    try:profile=DESKTOP_PROFILE.read_text(encoding="utf-8").strip().lower()
    except Exception:profile="kde"
    return {"kde":"KDE Plasma","gnome":"GNOME","hyprland":"Hyprland"}.get(profile,profile or "Unknown")

def hardware():
    d={
        "cpu":"Unknown","ram_gib":0.0,"gpus":[],"network":[],"battery":False,"virt":"none",
        "boot":"UEFI" if Path("/sys/firmware/efi").exists() else "BIOS/Legacy",
        "kernel":platform.release(),"arch":platform.machine(),
    }
    try:
        for x in Path("/proc/cpuinfo").read_text(errors="ignore").splitlines():
            if x.lower().startswith("model name"):
                d["cpu"]=x.split(":",1)[1].strip();break
    except Exception:pass
    try:
        m=Path("/proc/meminfo").read_text()
        kb=int(next(x.split()[1] for x in m.splitlines() if x.startswith("MemTotal:")))
        d["ram_gib"]=round(kb/1024/1024,1)
    except Exception:pass
    if command("lspci"):
        _,out=run(["lspci"])
        for x in out.splitlines():
            low=x.lower()
            if any(v in low for v in ("vga compatible controller","3d controller","display controller")):
                d["gpus"].append(x.split(": ",1)[-1])
            if "network controller" in low or "ethernet controller" in low:
                d["network"].append(x.split(": ",1)[-1])
    d["battery"]=any(Path("/sys/class/power_supply").glob("BAT*"))
    if command("systemd-detect-virt"):
        rc,out=run(["systemd-detect-virt"])
        if rc==0 and out:d["virt"]=out
    return d

def hardware_text():
    h=hardware()
    a=[
        f"CPU: {h['cpu']}",f"RAM: {h['ram_gib']} GiB",f"Kernel: {h['kernel']}",
        f"Mimari: {h['arch']}",f"Boot: {h['boot']}",f"Sanallaştırma: {h['virt']}",
        f"Batarya: {'Var' if h['battery'] else 'Yok'}"
    ]
    if h["gpus"]:a+=["GPU:"]+[f"  - {x}" for x in h["gpus"]]
    if h["network"]:a+=["Ağ:"]+[f"  - {x}" for x in h["network"]]
    return "\n".join(a)

def root_filesystem():
    rc,out=run(["findmnt","-n","-o","FSTYPE,SOURCE,OPTIONS","/"])
    return out if rc==0 else "Bilinmiyor"

def microcode_status():
    cpu=hardware()["cpu"].lower()
    wanted="amd64-microcode" if "amd" in cpu else "intel-microcode" if "intel" in cpu else ""
    installed="Bilinmiyor"
    if wanted:
        rc,out=run(["dpkg-query","-W","-f=${Version}",wanted])
        installed=out if rc==0 else "kurulu değil"
    runtime=""
    try:
        for line in Path("/proc/cpuinfo").read_text(errors="ignore").splitlines():
            if line.lower().startswith("microcode"):
                runtime=line.split(":",1)[1].strip();break
    except Exception:pass
    return f"Önerilen paket: {wanted or 'CPU üreticisi belirlenemedi'}\nPaket: {installed}\nRuntime microcode: {runtime or 'raporlanmadı'}"

def firmware_warnings():
    if not command("journalctl"):
        return "journalctl bulunamadı."
    rc,out=run(["journalctl","-k","-b","--no-pager","-g","firmware|failed to load|Direct firmware load","-n","80"],10)
    if rc not in (0,1):
        return "Kernel firmware logu okunamadı."
    return out or "Bu boot için belirgin firmware yükleme uyarısı görülmedi."

def recommendations():
    h=hardware();r=[];gpu=" ".join(h["gpus"]).lower()
    if "nvidia" in gpu:
        r.append(("OK","NVIDIA proprietary sürücüsü etkin.")) if command("nvidia-smi") else r.append(("ACTION","NVIDIA GPU algılandı; Flex Driver Manager proprietary sürücüyü kurabilir."))
    if h["ram_gib"] and h["ram_gib"]<=16:
        r.append(("ACTION",f"{h['ram_gib']} GiB RAM için zRAM faydalı olabilir."))
    if h["battery"]:
        r.append(("TIP","Dizüstü algılandı; Balanced veya Battery profili önerilir."))
    fs=run(["findmnt","-n","-o","FSTYPE","/"])[1] if command("findmnt") else ""
    if fs=="btrfs":r.append(("ACTION","Btrfs algılandı; Flex Snapshot kullanılabilir."))
    else:r.append(("INFO","Snapshot rollback için Btrfs önerilir."))
    if h["virt"]!="none":
        r.append(("INFO",f"Sanal makine algılandı: {h['virt']}. GPU sürücü önerileri gerçek donanımı temsil etmeyebilir."))
    return r

def security_status():
    sb="Bilinmiyor"
    if command("mokutil"):
        _,o=run(["mokutil","--sb-state"]);sb="Etkin" if "enabled" in o.lower() else "Kapalı"
    src=run(["findmnt","-n","-o","SOURCE","/"])[1]
    enc="Evet" if src.startswith("/dev/mapper/") else "Hayır / algılanmadı"
    ufw="Etkin" if Path("/etc/ufw/ufw.conf").exists() and "ENABLED=yes" in Path("/etc/ufw/ufw.conf").read_text(errors="ignore") else "Kapalı"
    au="Etkin" if Path("/etc/apt/apt.conf.d/20auto-upgrades").exists() else "Kapalı"
    return f"Secure Boot: {sb}\nDisk şifreleme: {enc}\nFirewall: {ufw}\nOtomatik güvenlik güncellemeleri: {au}"

def driver_status():
    h=hardware();a=h["gpus"][:] or ["GPU algılanamadı"]
    if any("nvidia" in x.lower() for x in h["gpus"]):
        if command("nvidia-smi"):
            rc,o=run(["nvidia-smi","--query-gpu=name,driver_version","--format=csv,noheader"])
            a.append("NVIDIA: "+(o if rc==0 else "sürücü komutu hata verdi"))
        else:
            a.append("NVIDIA proprietary driver: kurulu değil")
            rc,o=run(["lsmod"])
            if rc==0 and "nouveau" in o:a.append("Nouveau: yüklü")
            else:a.append("Nouveau: aktif görünmüyor")
    elif any("amd" in x.lower() or "ati" in x.lower() for x in h["gpus"]):
        a.append("AMD: kernel/Mesa açık kaynak yığını.")
    elif any("intel" in x.lower() for x in h["gpus"]):
        a.append("Intel: kernel/Mesa açık kaynak yığını.")
    a+=["","CPU MICROCODE",microcode_status(),"","FIRMWARE WARNINGS",firmware_warnings()]
    return "\n".join(a)

def update_preview():
    if not command("apt"):return "APT bulunamadı."
    _,o=run(["bash","-lc","apt list --upgradable 2>/dev/null | tail -n +2 | head -n 120"],20)
    return o or "Bekleyen güncelleme görünmüyor."

def snapshot_supported():
    return run(["findmnt","-n","-o","FSTYPE","/"])[1]=="btrfs"

def snapshot_status():
    if not snapshot_supported():return "Kök dosya sistemi Btrfs değil."
    rc,fsroot=run(["findmnt","-n","-o","FSROOT","/"])
    if rc==0 and fsroot.strip() in ("","/"):
        return "Btrfs kökü top-level olarak bağlı; güvenli FlexOS rollback devre dışı. Beta için /@ gibi bir root subvolume gerekir."
    if not command("snapper"):return "Snapper kurulu değil."
    return "Btrfs root subvolume + Snapper hazır." if Path("/etc/snapper/configs/root").exists() else "Btrfs root subvolume hazır; Snapper root config henüz oluşturulmadı."

def kernel_status():
    _,o=run(["bash","-lc","dpkg-query -W -f='${Package} ${Version}\\n' 'linux-image-*' 2>/dev/null | grep '^linux-image-[0-9]' | tail -n 20"])
    return f"Çalışan kernel: {platform.release()}\n\nKurulu kernel paketleri:\n{o or 'Bulunamadı'}"

def flexos_package_status():
    rc,o=run(["bash","-lc","dpkg-query -W -f='${Package} ${Version}\\n' 'flexos-*' 2>/dev/null | sort"],15)
    if rc==0 and o:return o
    return "FlexOS bileşenleri henüz dpkg tarafından sahiplenilmemiş olabilir; ilk component update bunu dönüştürür."

def install_info():
    p=Path("/etc/flexos/install-info")
    return p.read_text(errors="ignore").strip() if p.exists() else "Kurulum bilgisi kaydedilmemiş."

def logs_summary():
    out=[]
    if command("systemctl"):
        _,o=run(["systemctl","--failed","--no-legend"]);out.append("FAILED SERVICES\n"+(o or "Yok"))
    if command("journalctl"):
        _,o=run(["journalctl","-b","-p","warning","--no-pager","-n","120"],10)
        out.append("\nBOOT WARNINGS\n"+(o or "Yok / erişilemedi"))
    return "\n".join(out)

def temperature_text():
    if command("sensors"):
        _,o=run(["sensors","-A"],8);return o or "Sensör verisi yok."
    return "lm-sensors bulunamadı."

def app_catalog():return load_json(APPS,[])

def flatpak_ready():
    if not command("flatpak"):return False
    rc,o=run(["flatpak","remotes","--user"]);return rc==0 and "flathub" in o.lower()

def enable_flathub_user():
    return run(["flatpak","remote-add","--user","--if-not-exists","flathub","https://flathub.org/repo/flathub.flatpakrepo"],60)

def install_flatpak_user(appid):
    if not flatpak_ready():
        rc,o=enable_flathub_user()
        if rc:return rc,o
    return run(["flatpak","install","--user","-y","flathub",appid],1800)

def create_backup(dest):
    dest=Path(dest);dest.parent.mkdir(parents=True,exist_ok=True);home=Path.home()
    with zipfile.ZipFile(dest,"w",zipfile.ZIP_DEFLATED) as z:
        z.writestr("manifest.json",json.dumps({
            "format":2,"created":int(time.time()),"profile":current_profile(),
            "desktop":current_desktop(),"flexos":identity()
        },indent=2,ensure_ascii=False))
        for p in [
            home/".config/flexos",home/".config/kdeglobals",home/".config/kwinrc",
            home/".config/plasmarc",home/".config/konsole",home/".local/share/konsole"
        ]:
            if not p.exists():continue
            if p.is_file():z.write(p,"files/"+str(p.relative_to(home)))
            else:
                for f in p.rglob("*"):
                    if f.is_file():z.write(f,"files/"+str(f.relative_to(home)))
    return dest

def restore_backup(src):
    home=Path.home();n=0;total=0
    with zipfile.ZipFile(src) as z:
        for i in z.infolist():
            if not i.filename.startswith("files/") or i.is_dir():continue
            rel=i.filename[6:]
            if rel.startswith("/") or ".." in Path(rel).parts:continue
            if not (rel.startswith(".config/") or rel.startswith(".local/share/konsole/")):continue
            if i.file_size>MAX_BACKUP_ENTRY:
                raise ValueError(f"Backup entry is too large: {i.filename}")
            ratio=i.file_size/max(1,i.compress_size)
            if ratio>MAX_BACKUP_RATIO:
                raise ValueError(f"Backup entry compression ratio is unsafe: {i.filename}")
            total+=i.file_size
            if total>MAX_BACKUP_TOTAL:
                raise ValueError("Backup expands beyond the allowed size limit")
            t=home/rel;t.parent.mkdir(parents=True,exist_ok=True)
            with z.open(i,"r") as source,t.open("wb") as target:
                shutil.copyfileobj(source,target,1024*1024)
            n+=1
    return n

def report_text():
    i=identity()
    return "\n".join([
        "FlexOS System Report","====================",
        f"Product: {i.get('version','unknown')} ({i.get('build_id','unknown')})",
        f"Channel: {i.get('channel','unknown')}",
        f"Created by: {i.get('creator','Pifo')}",
        "",
        "INSTALL INFO",install_info(),
        "",
        "HARDWARE",hardware_text(),
        "",
        "ROOT FILESYSTEM",root_filesystem(),
        "",
        "RECOMMENDATIONS",*[f"[{s}] {m}" for s,m in recommendations()],
        "",
        "SECURITY",security_status(),
        "",
        "DRIVERS / FIRMWARE",driver_status(),
        "",
        "KERNEL",kernel_status(),
        "",
        "FLEXOS COMPONENT PACKAGES",flexos_package_status(),
        "",
        "SNAPSHOT",snapshot_status(),
        "",
        "LOG SUMMARY",logs_summary()
    ])
