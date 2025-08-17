FROM mcr.microsoft.com/devcontainers/cpp:ubuntu-22.04

# MinGW for cross-compile Windows DLL + CMake/Ninja
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        cmake ninja-build g++ gcc \
        binutils-mingw-w64 g++-mingw-w64-x86-64 gcc-mingw-w64-x86-64 \
    && rm -rf /var/lib/apt/lists/*
