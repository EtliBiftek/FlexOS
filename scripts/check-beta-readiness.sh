#!/usr/bin/env bash
set -Eeuo pipefail
./scripts/validate.sh
python3 ./scripts/beta-gate.py
echo
echo "Development readiness check completed."
echo "Use --strict only for a release candidate/tag:"
echo "  python3 scripts/beta-gate.py --strict"
