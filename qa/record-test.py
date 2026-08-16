#!/usr/bin/env python3
from __future__ import annotations
import argparse,json
from pathlib import Path

ap=argparse.ArgumentParser(description="Update a FlexOS QA test result.")
ap.add_argument("test_id")
ap.add_argument("status",choices=["pending","pass","fail","blocked"])
ap.add_argument("--notes",default="")
ap.add_argument("--matrix",default="qa/test-matrix.json")
args=ap.parse_args()
p=Path(args.matrix)
d=json.loads(p.read_text(encoding="utf-8"))
for t in d["tests"]:
    if t["id"]==args.test_id:
        t["status"]=args.status
        t["notes"]=args.notes
        p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
        print(f"{args.test_id} -> {args.status}")
        break
else:
    raise SystemExit(f"Unknown test id: {args.test_id}")
