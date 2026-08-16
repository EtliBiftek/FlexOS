#!/usr/bin/env python3
import argparse,datetime,re

ap=argparse.ArgumentParser()
ap.add_argument("version")
ap.add_argument("--epoch",default="")
ap.add_argument("--ci-run",default="")  # legacy fallback
ap.add_argument("--sha",default="")
args=ap.parse_args()

v=args.version.strip()
m=re.fullmatch(r"(\d+\.\d+\.\d+)-beta\.(\d+)(-dev)?",v)
if not m:
    print(v.replace("-","~"))
    raise SystemExit(0)

base,beta,dev=m.groups()

if not dev:
    # A promoted beta sorts after every ~git development build.
    print(f"{base}~beta{beta}")
    raise SystemExit(0)

suffix=""
if args.epoch:
    try:
        dt=datetime.datetime.fromtimestamp(int(args.epoch),tz=datetime.timezone.utc)
        suffix="~git"+dt.strftime("%Y%m%d%H%M%S")
    except Exception:
        raise SystemExit("--epoch must be a Unix timestamp")
elif args.ci_run:
    suffix=f"~git{int(args.ci_run):08d}"
else:
    suffix="~dev"

if args.sha and suffix!="~dev":
    suffix+=f"+g{args.sha[:8]}"

print(f"{base}~beta{beta}{suffix}")
