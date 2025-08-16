#!/bin/bash

# Create build directory if it doesn't exist
mkdir -p build
cd build

# Configure with CMake
cmake .. -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
    -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
    -DCMAKE_SYSTEM_NAME=Windows

# Build
cmake --build . --config Release

# Create Libraries directory if it doesn't exist
mkdir -p ../MQL4/Libraries/

# Copy DLL to MQL4 directory
cp bin/GoldenCandleStrategy.dll ../MQL4/Libraries/

echo "Build complete!"
