#!/bin/bash

# Set directories
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BASE_DIR="$SCRIPT_DIR/.."
INCLUDE_DIR="$SCRIPT_DIR/include"
OUTPUT_DIR="$BASE_DIR/Expert/Libraries"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Compile resource file
echo "Compiling resource file..."
i686-w64-mingw32-windres GoldenCandleEA.rc -O coff -o GoldenCandleEA_res.o

# Compile DLL
echo "Compiling DLL..."
i686-w64-mingw32-g++ -I"$INCLUDE_DIR" \
    -shared \
    -o "$OUTPUT_DIR/GoldenCandleEA.dll" \
    GoldenCandleEA_DLL.cpp \
    GoldenCandleStrategy.cpp \
    GoldenCandleEA_res.o \
    -static-libgcc \
    -static-libstdc++ \
    -luser32 \
    -lgdi32 \
    -mwindows

# Check if compilation was successful
if [ $? -eq 0 ]; then
    echo "Compilation successful!"
    echo "DLL created at: $OUTPUT_DIR/GoldenCandleEA.dll"
else
    echo "Compilation failed!"
    exit 1
fi
