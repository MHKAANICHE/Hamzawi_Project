cmake_minimum_required(VERSION 3.10)
project(GoldenCandleStrategy)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Add source files
set(SOURCES
    GoldenCandleStrategy.cpp
)

# Create shared library
add_library(GoldenCandleStrategy SHARED ${SOURCES})

# Set Windows-specific properties
if(WIN32)
    # Set output name without lib prefix
    set_target_properties(GoldenCandleStrategy PROPERTIES PREFIX "")
endif()
