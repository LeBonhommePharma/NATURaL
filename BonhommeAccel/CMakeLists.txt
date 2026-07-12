cmake_minimum_required(VERSION 3.20)
project(BonhommeAccel
    VERSION 1.1.1
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
# Metal defaults ON on Apple hosts (production GPU path on Apple Silicon).
if(APPLE)
    option(BA_ENABLE_METAL "Enable Metal backend (Apple only)" ON)
else()
    option(BA_ENABLE_METAL "Enable Metal backend (Apple only)" OFF)
endif()
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
set(BA_HAS_AVX2_BACKEND OFF)
set(BA_HAS_NEON_BACKEND OFF)

# Host processor and CMAKE_OSX_ARCHITECTURES (cross-compile iOS/watchOS arm64).
set(_BA_TARGET_X86 FALSE)
set(_BA_TARGET_ARM64 FALSE)
if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
    set(_BA_TARGET_X86 TRUE)
endif()
if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|ARM64|arm64")
    set(_BA_TARGET_ARM64 TRUE)
endif()
if(CMAKE_OSX_ARCHITECTURES MATCHES "x86_64")
    set(_BA_TARGET_X86 TRUE)
endif()
if(CMAKE_OSX_ARCHITECTURES MATCHES "arm64")
    set(_BA_TARGET_ARM64 TRUE)
endif()

if(BA_ENABLE_AVX2 AND _BA_TARGET_X86 AND NOT _BA_TARGET_ARM64)
    list(APPEND BACKEND_SOURCES src/backends/simd/entropy_avx2.cpp)
    list(APPEND BACKEND_SOURCES src/backends/simd/correlation_simd.cpp)
    set(BA_HAS_AVX2_BACKEND ON)
endif()

if(BA_ENABLE_NEON AND _BA_TARGET_ARM64)
    list(APPEND BACKEND_SOURCES src/backends/simd/entropy_neon.cpp)
    # NEON Pearson lives in correlation_simd.cpp (same TU as AVX2 kernels)
    list(APPEND BACKEND_SOURCES src/backends/simd/correlation_simd.cpp)
    set(BA_HAS_NEON_BACKEND ON)
endif()

# OpenMP
set(BA_HAS_OPENMP_BACKEND OFF)
if(BA_ENABLE_OPENMP)
    find_package(OpenMP QUIET)
    if(OpenMP_CXX_FOUND)
        list(APPEND BACKEND_SOURCES src/backends/openmp/entropy_omp.cpp)
        list(APPEND BACKEND_SOURCES src/backends/openmp/pairwise_omp.cpp)
        set(BA_HAS_OPENMP_BACKEND ON)
    endif()
endif()

# CUDA
set(BA_HAS_CUDA_BACKEND OFF)
if(BA_ENABLE_CUDA)
    include(CheckLanguage)
    check_language(CUDA)
    if(CMAKE_CUDA_COMPILER)
        enable_language(CUDA)
        set(CMAKE_CUDA_STANDARD 17)
        set(CMAKE_CUDA_STANDARD_REQUIRED ON)
        list(APPEND BACKEND_SOURCES
            src/backends/cuda/entropy_cuda.cu
            src/backends/cuda/correlation_cuda.cu
            src/backends/cuda/pairwise_cuda.cu
        )
        set(BA_HAS_CUDA_BACKEND ON)
    else()
        message(WARNING "BA_ENABLE_CUDA=ON but no CUDA compiler found; CUDA backend disabled")
    endif()
endif()

# ROCm/HIP
set(BA_HAS_ROCM_BACKEND OFF)
if(BA_ENABLE_ROCM)
    # Prefer modern HIP language support when available
    include(CheckLanguage)
    check_language(HIP)
    if(CMAKE_HIP_COMPILER)
        enable_language(HIP)
        list(APPEND BACKEND_SOURCES
            src/backends/rocm/entropy_hip.cpp
            src/backends/rocm/correlation_hip.cpp
        )
        set_source_files_properties(
            src/backends/rocm/entropy_hip.cpp
            src/backends/rocm/correlation_hip.cpp
            PROPERTIES LANGUAGE HIP
        )
        set(BA_HAS_ROCM_BACKEND ON)
    else()
        find_package(hip QUIET)
        if(hip_FOUND)
            list(APPEND BACKEND_SOURCES
                src/backends/rocm/entropy_hip.cpp
                src/backends/rocm/correlation_hip.cpp
            )
            set(BA_HAS_ROCM_BACKEND ON)
        else()
            message(WARNING "BA_ENABLE_ROCM=ON but HIP not found; ROCm backend disabled")
        endif()
    endif()
endif()

# Metal (Apple only)
set(BA_HAS_METAL_BACKEND OFF)
if(BA_ENABLE_METAL AND APPLE)
    enable_language(OBJCXX)
    list(APPEND BACKEND_SOURCES
        src/backends/metal/metal_runtime.mm
        src/backends/metal/entropy_metal.mm
        src/backends/metal/correlation_metal.mm
        src/backends/metal/pairwise_metal.mm
    )
    set(BA_HAS_METAL_BACKEND ON)
elseif(BA_ENABLE_METAL AND NOT APPLE)
    message(WARNING "BA_ENABLE_METAL=ON is only supported on Apple platforms")
endif()

# ═══════════════════════════════════════════════════════════════════════════
# Library target
# ═══════════════════════════════════════════════════════════════════════════

set(ALL_SOURCES ${CORE_SOURCES})
foreach(src ${BACKEND_SOURCES})
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${src}")
        list(APPEND ALL_SOURCES ${src})
    else()
        message(WARNING "Backend source missing, skipped: ${src}")
    endif()
endforeach()

add_library(BonhommeAccel STATIC ${ALL_SOURCES})

# Required for static libs linked into iOS/watchOS/tvOS apps.
set_target_properties(BonhommeAccel PROPERTIES
    POSITION_INDEPENDENT_CODE ON
    OUTPUT_NAME BonhommeAccel
)

target_include_directories(BonhommeAccel
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        ${CMAKE_CURRENT_SOURCE_DIR}/src/core
        ${CMAKE_CURRENT_SOURCE_DIR}/src/dispatch
        ${CMAKE_CURRENT_SOURCE_DIR}/src/backends
)

target_compile_features(BonhommeAccel PUBLIC cxx_std_20)

# Surface cross-compile intent in the configure log.
if(CMAKE_SYSTEM_NAME MATCHES "iOS|watchOS|tvOS")
    message(STATUS "BonhommeAccel cross-compile: SYSTEM=${CMAKE_SYSTEM_NAME} "
                   "SYSROOT=${CMAKE_OSX_SYSROOT} ARCH=${CMAKE_OSX_ARCHITECTURES}")
endif()

# Compiler warnings / optimization for C++ and ObjC++
target_compile_options(BonhommeAccel PRIVATE
    $<$<COMPILE_LANGUAGE:CXX,OBJCXX>:
        $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:
            -Wall -Wextra -Wpedantic -Wno-unused-parameter
            -O3
        >
    >
    $<$<COMPILE_LANGUAGE:CXX>:
        $<$<CXX_COMPILER_ID:MSVC>:
            /W4 /O2 /fp:fast
        >
    >
)

# Public compile defs so API/dispatch can select compiled backends
if(BA_HAS_AVX2_BACKEND)
    target_compile_definitions(BonhommeAccel PRIVATE BA_HAS_AVX2)
endif()
if(BA_HAS_NEON_BACKEND)
    target_compile_definitions(BonhommeAccel PRIVATE BA_HAS_NEON)
endif()

# AVX2 flags for SIMD sources
if(BA_HAS_AVX2_BACKEND)
    foreach(src src/backends/simd/entropy_avx2.cpp src/backends/simd/correlation_simd.cpp)
        if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${src}")
            set_source_files_properties(${src} PROPERTIES
                COMPILE_FLAGS "$<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-mavx2 -mfma>"
            )
        endif()
    endforeach()
endif()

# AVX-512 flags (kernels not yet implemented — flag reserved)
if(BA_ENABLE_AVX512 AND (CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64"))
    # Future: dedicated AVX-512 TUs would get -mavx512f here
endif()

# OpenMP linking
if(BA_HAS_OPENMP_BACKEND)
    target_link_libraries(BonhommeAccel PRIVATE OpenMP::OpenMP_CXX)
    target_compile_definitions(BonhommeAccel PRIVATE BA_HAS_OPENMP)
endif()

# CUDA linking
if(BA_HAS_CUDA_BACKEND)
    target_compile_definitions(BonhommeAccel PRIVATE BA_HAS_CUDA)
    find_package(CUDAToolkit QUIET)
    if(TARGET CUDA::cudart)
        target_link_libraries(BonhommeAccel PRIVATE CUDA::cudart)
    else()
        target_link_libraries(BonhommeAccel PRIVATE cudart)
    endif()
    set_target_properties(BonhommeAccel PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON
        POSITION_INDEPENDENT_CODE ON
    )
endif()

# ROCm/HIP linking
if(BA_HAS_ROCM_BACKEND)
    target_compile_definitions(BonhommeAccel PRIVATE BA_HAS_ROCM)
    if(TARGET hip::host)
        target_link_libraries(BonhommeAccel PRIVATE hip::host)
    elseif(TARGET hip::device)
        target_link_libraries(BonhommeAccel PRIVATE hip::device)
    endif()
endif()

# Metal linking (Apple only)
if(BA_HAS_METAL_BACKEND)
    target_link_libraries(BonhommeAccel PRIVATE
        "-framework Metal"
        "-framework Foundation"
    )
    target_compile_definitions(BonhommeAccel PRIVATE BA_HAS_METAL)
    # ARC for Objective-C++ Metal TUs
    foreach(src
        src/backends/metal/metal_runtime.mm
        src/backends/metal/entropy_metal.mm
        src/backends/metal/correlation_metal.mm
        src/backends/metal/pairwise_metal.mm
    )
        set_source_files_properties(${src} PROPERTIES
            COMPILE_OPTIONS "-fobjc-arc"
        )
    endforeach()
endif()

# Status summary
message(STATUS "BonhommeAccel backends:")
message(STATUS "  NEON   = ${BA_HAS_NEON_BACKEND}")
message(STATUS "  AVX2   = ${BA_HAS_AVX2_BACKEND}")
message(STATUS "  OpenMP = ${BA_HAS_OPENMP_BACKEND}")
message(STATUS "  Metal  = ${BA_HAS_METAL_BACKEND}")
message(STATUS "  CUDA   = ${BA_HAS_CUDA_BACKEND}")
message(STATUS "  ROCm   = ${BA_HAS_ROCM_BACKEND}")

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
