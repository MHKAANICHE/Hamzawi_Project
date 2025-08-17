#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[*] Installing mingw (if in Codespaces)"
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y g++-mingw-w64-x86-64 cmake ninja-build
fi

echo "[*] Configure (Windows x86_64 via MinGW)"
cmake -S "$ROOT/core" -B "$ROOT/build_win" \
  -DCMAKE_TOOLCHAIN_FILE="$ROOT/core/toolchains/x86_64-w64-mingw32.cmake" \
  -DCMAKE_BUILD_TYPE=Release -G "Ninja"

echo "[*] Build"
cmake --build "$ROOT/build_win" --config Release

echo "[*] Done. DLL at: $ROOT/build_win/libea_core.dll"
