cmake_minimum_required(VERSION 3.20)
project(ea_core LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(ea_core SHARED
    src/state.cpp
    src/ea_core.cpp
)
target_include_directories(ea_core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

# Nom correct de l'artefact sous Windows
if (WIN32)
  set_target_properties(ea_core PROPERTIES OUTPUT_NAME "ea_core")
endif()
