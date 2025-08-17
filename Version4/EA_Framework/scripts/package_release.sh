#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/release"
VER=$(date +%Y%m%d_%H%M)

mkdir -p "$OUT"
cp "$ROOT/build_win/libea_core.dll" "$OUT/ea_core.dll"
mkdir -p "$OUT/mql4/Include" "$OUT/mql4/Experts"
cp "$ROOT/mql4/Include/MT4Adapter.mqh" "$OUT/mql4/Include/"
cp "$ROOT/mql4/Experts/GoldenShell.mq4" "$OUT/mql4/Experts/"
cp "$ROOT/README.md" "$OUT/"
cp "$ROOT/DeveloperGuide.md" "$OUT/"

cd "$OUT"
zip -r "../EA_Framework_${VER}.zip" .
echo "Release package: $ROOT/EA_Framework_${VER}.zip"
