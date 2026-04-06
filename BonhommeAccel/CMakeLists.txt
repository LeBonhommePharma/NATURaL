cmake_minimum_required(VERSION 3.20)
project(BonhommeAccel
    VERSION 1.0.0
    LANGUAGES CXX
    DESCRIPTION "GPU/SIMD accelerated Shannon entropy and statistics for NATURaL/FlexAIDdS"
)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ═══════════════════════════════════════════════════════════════════════════
# Options
# ═══════════════════════════════════════════════════════════════════════════

option(BA_BUILD_TESTS    "Build Catch2 tests"                  ON)
option(BA_ENABLE_OPENMP  "Enable OpenMP backend"               ON)
option(BA_ENABLE_CUDA    "Enable CUDA backend"                 OFF)
option(BA_ENABLE_ROCM    "Enable ROCm/HIP backend"             OFF)
option(BA_ENABLE_METAL   "Enable Metal backend (Apple only)"   OFF)
option(BA_ENABLE_AVX2    "Enable AVX2 SIMD backend"            ON)
option(BA_ENABLE_AVX512  "Enable AVX-512 SIMD backend"         ON)
option(BA_ENABLE_NEON    "Enable ARM NEON SIMD backend"        ON)

# ═══════════════════════════════════════════════════════════════════════════
# Core library sources (always compiled)
# ═══════════════════════════════════════════════════════════════════════════

set(CORE_SOURCES
    src/core/entropy.cpp
    src/core/correlation.cpp
    src/core/statistics.cpp
    src/core/incomplete_beta.cpp
    src/core/pairwise.cpp
    src/dispatch/dispatch.cpp
    src/api/bonhomme_accel.cpp
)

# ═══════════════════════════════════════════════════════════════════════════
# Backend sources (conditionally compiled)
# ═══════════════════════════════════════════════════════════════════════════

set(BACKEND_SOURCES "")

# SIMD backends
if(BA_ENABLE_AVX2 AND (CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64"))
    list(APPEND BACKEND_SOURCES src/backends/simd/entropy_avx2.cpp)
    list(APPEND BACKEND_SOURCES src/backends/simd/correlation_simd.cpp)
endif()

if(BA_ENABLE_NEON AND (CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|ARM64|arm64"))
    list(APPEND BACKEND_SOURCES src/backends/simd/entropy_neon.cpp)
endif()

# OpenMP
if(BA_ENABLE_OPENMP)
    find_package(OpenMP QUIET)
    if(OpenMP_CXX_FOUND)
        list(APPEND BACKEND_SOURCES src/backends/openmp/entropy_omp.cpp)
        list(APPEND BACKEND_SOURCES src/backends/openmp/pairwise_omp.cpp)
    endif()
endif()

# CUDA
if(BA_ENABLE_CUDA)
    enable_language(CUDA)
    list(APPEND BACKEND_SOURCES src/backends/cuda/entropy_cuda.cu)
    list(APPEND BACKEND_SOURCES src/backends/cuda/correlation_cuda.cu)
    list(APPEND BACKEND_SOURCES src/backends/cuda/pairwise_cuda.cu)
    add_compile_definitions(BA_HAS_CUDA)
endif()

# ROCm/HIP
if(BA_ENABLE_ROCM)
    find_package(hip QUIET)
    if(hip_FOUND)
        list(APPEND BACKEND_SOURCES src/backends/rocm/entropy_hip.cpp)
        add_compile_definitions(BA_HAS_ROCM)
    endif()
endif()

# ═══════════════════════════════════════════════════════════════════════════
# Library target
# ═══════════════════════════════════════════════════════════════════════════

# Filter out non-existent backend sources (Phase 2-4 files not yet created)
set(ALL_SOURCES ${CORE_SOURCES})
foreach(src ${BACKEND_SOURCES})
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${src}")
        list(APPEND ALL_SOURCES ${src})
    endif()
endforeach()

add_library(BonhommeAccel STATIC ${ALL_SOURCES})

target_include_directories(BonhommeAccel
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        ${CMAKE_CURRENT_SOURCE_DIR}/src/core
        ${CMAKE_CURRENT_SOURCE_DIR}/src/dispatch
)

target_compile_features(BonhommeAccel PUBLIC cxx_std_20)

# Compiler warnings
target_compile_options(BonhommeAccel PRIVATE
    $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:
        -Wall -Wextra -Wpedantic -Wno-unused-parameter
        -O3
    >
    $<$<CXX_COMPILER_ID:MSVC>:
        /W4 /O2 /fp:fast
    >
)

# AVX2 flags for SIMD sources
if(BA_ENABLE_AVX2 AND (CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64"))
    foreach(src src/backends/simd/entropy_avx2.cpp src/backends/simd/correlation_simd.cpp)
        if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${src}")
            set_source_files_properties(${src} PROPERTIES
                COMPILE_FLAGS "$<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-mavx2 -mfma>"
            )
        endif()
    endforeach()
endif()

# AVX-512 flags
if(BA_ENABLE_AVX512 AND (CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64"))
    # AVX-512 sources would get -mavx512f flag here
endif()

# OpenMP linking
if(BA_ENABLE_OPENMP AND OpenMP_CXX_FOUND)
    target_link_libraries(BonhommeAccel PRIVATE OpenMP::OpenMP_CXX)
    target_compile_definitions(BonhommeAccel PRIVATE BA_HAS_OPENMP)
endif()

# Metal linking (Apple only)
if(BA_ENABLE_METAL AND APPLE)
    target_link_libraries(BonhommeAccel PRIVATE
        "-framework Metal"
        "-framework Foundation"
    )
    target_compile_definitions(BonhommeAccel PRIVATE BA_HAS_METAL)
endif()

# ═══════════════════════════════════════════════════════════════════════════
# Tests
# ═══════════════════════════════════════════════════════════════════════════

if(BA_BUILD_TESTS)
    include(FetchContent)
    FetchContent_Declare(
        Catch2
        GIT_REPOSITORY https://github.com/catchorg/Catch2.git
        GIT_TAG        v3.5.2
    )
    FetchContent_MakeAvailable(Catch2)

    add_executable(ba_tests
        tests/test_entropy.cpp
        tests/test_correlation.cpp
        tests/test_pairwise.cpp
        tests/test_incomplete_beta.cpp
    )

    target_link_libraries(ba_tests PRIVATE
        BonhommeAccel
        Catch2::Catch2WithMain
    )

    target_include_directories(ba_tests PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        ${CMAKE_CURRENT_SOURCE_DIR}/tests
    )

    include(CTest)
    include(Catch)
    catch_discover_tests(ba_tests)
endif()

# ═══════════════════════════════════════════════════════════════════════════
# Install
# ═══════════════════════════════════════════════════════════════════════════

install(TARGETS BonhommeAccel
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
)

install(FILES include/BonhommeAccel.h
    DESTINATION include
)
