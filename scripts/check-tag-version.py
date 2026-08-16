#!/usr/bin/env python3
import os,sys
from pathlib import Path

tag=os.environ.get("GITHUB_REF_NAME","")
version=Path("VERSION").read_text(encoding="utf-8").strip()

if not tag:
    raise SystemExit("GITHUB_REF_NAME is missing")
expected="v"+version
if tag!=expected:
    print(f"Tag/version mismatch: tag={tag}, VERSION={version}, expected={expected}",file=sys.stderr)
    raise SystemExit(1)
if version.endswith("-dev"):
    print("A -dev VERSION may not be published as a versioned beta release.",file=sys.stderr)
    raise SystemExit(1)
print(f"Tag matches VERSION: {tag}")
