#!/bin/bash
# build_and_package.sh - Build and package GoldenCandleEA for delivery
# Usage: bash build_and_package.sh

set -e

# Paths
ROOT_DIR="$(dirname "$0")/../.."
EA_SRC="$ROOT_DIR/Version2/MT4_integration/expert/GoldenCandleEA_v2.mq4"
DLL_SRC="$ROOT_DIR/Version2/MT4_integration/library/GoldenCandleEA_GUI.cpp"
RC_SRC="$ROOT_DIR/Version2/MT4_integration/library/GoldenCandleEA_GUI.rc"
DELIVERY_DIR="$ROOT_DIR/Delivery_Package"

# Create delivery directory
mkdir -p "$DELIVERY_DIR"

# 1. Compile EA (requires MetaEditor CLI on Windows, placeholder here)
echo "[INFO] Please compile GoldenCandleEA_v2.mq4 in MetaEditor to produce GoldenCandleEA_v2.ex4."
echo "[INFO] Copy the resulting .ex4 file to $DELIVERY_DIR."

# 2. Compile DLL (requires Visual Studio or MinGW, placeholder here)
echo "[INFO] Please compile GoldenCandleEA_GUI.cpp/.rc as GoldenCandleEA_GUI.dll using your C++ toolchain."
echo "[INFO] Copy the resulting .dll file to $DELIVERY_DIR."

# 3. Copy documentation and requirements
cp "$ROOT_DIR/README.md" "$DELIVERY_DIR/"
cp "$ROOT_DIR/Technical_Documentation.md" "$DELIVERY_DIR/"
cp "$ROOT_DIR/Requeriements/EA Forex.pdf" "$DELIVERY_DIR/" || true

# 4. List contents
echo "[INFO] Delivery package contents:"
ls -lh "$DELIVERY_DIR"

echo "[DONE] Please ensure .ex4 and .dll are present in $DELIVERY_DIR before delivery."
