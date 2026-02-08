cmake_minimum_required(VERSION 3.20)
project(lldb_copilot VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add libagents if building standalone (not part of monorepo)
if(NOT TARGET libagents)
    add_subdirectory(external/libagents)
endif()

# Auto-fetch settings for Windows when LLDB is missing.
set(LLDB_PINNED_VERSION "18.1.8" CACHE STRING "Pinned LLVM/LLDB version used for Windows auto-fetch")
option(LLDB_AUTO_FETCH "Automatically download a pinned LLVM/LLDB SDK on Windows when LLDB is not found" ON)
set(
    LLDB_WINDOWS_SDK_URL
    "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLDB_PINNED_VERSION}/clang+llvm-${LLDB_PINNED_VERSION}-x86_64-pc-windows-msvc.tar.xz"
    CACHE STRING "Download URL for pinned Windows LLVM/LLDB SDK"
)
set(
    LLDB_WINDOWS_SDK_SHA256
    ""
    CACHE STRING "Optional SHA256 for LLDB_WINDOWS_SDK_URL (leave empty to skip hash verification)"
)

# Find LLDB
# On macOS: /Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework
# On Linux: apt install liblldb-dev
find_package(LLDB QUIET)

if(NOT LLDB_FOUND)
    # Try to find LLDB manually based on platform
    if(WIN32)
        # Windows: try vendored headers + local LLVM installs first
        find_path(LLDB_INCLUDE_DIRS lldb/API/LLDB.h
            PATHS
                "${CMAKE_CURRENT_SOURCE_DIR}/external/lldb-headers/include"
                "$ENV{LLVM_DIR}/include"
                "$ENV{ProgramFiles}/LLVM/include"
                "$ENV{ProgramW6432}/LLVM/include"
                "C:/Program Files/LLVM/include"
            NO_DEFAULT_PATH
        )
        find_library(LLDB_LIBRARIES NAMES liblldb lldb
            PATHS
                "$ENV{LLVM_DIR}/lib"
                "$ENV{ProgramFiles}/LLVM/lib"
                "$ENV{ProgramW6432}/LLVM/lib"
                "C:/Program Files/LLVM/lib"
            NO_DEFAULT_PATH
        )

        if(LLDB_INCLUDE_DIRS AND LLDB_LIBRARIES)
            set(LLDB_FOUND TRUE)
        endif()

        # Auto-fetch pinned LLDB SDK when no local LLDB was found.
        if(NOT LLDB_FOUND AND LLDB_AUTO_FETCH)
            set(LLDB_DEPS_DIR "${CMAKE_BINARY_DIR}/_deps")
            set(LLDB_SDK_ARCHIVE "${LLDB_DEPS_DIR}/llvm-${LLDB_PINNED_VERSION}-windows-x64.tar.xz")
            set(LLDB_SDK_EXTRACTED_DIR "${LLDB_DEPS_DIR}/clang+llvm-${LLDB_PINNED_VERSION}-x86_64-pc-windows-msvc")

            file(MAKE_DIRECTORY "${LLDB_DEPS_DIR}")
            message(STATUS "LLDB not found locally. Auto-fetch enabled (pinned version: ${LLDB_PINNED_VERSION}).")
            message(STATUS "LLDB SDK URL: ${LLDB_WINDOWS_SDK_URL}")

            if(NOT EXISTS "${LLDB_SDK_EXTRACTED_DIR}/lib/liblldb.lib")
                if(LLDB_WINDOWS_SDK_SHA256)
                    file(DOWNLOAD
                        "${LLDB_WINDOWS_SDK_URL}"
                        "${LLDB_SDK_ARCHIVE}"
                        SHOW_PROGRESS
                        EXPECTED_HASH "SHA256=${LLDB_WINDOWS_SDK_SHA256}"
                        STATUS LLDB_DOWNLOAD_STATUS
                        LOG LLDB_DOWNLOAD_LOG
                    )
                else()
                    message(WARNING "LLDB_WINDOWS_SDK_SHA256 is empty. Download integrity is not hash-verified.")
                    file(DOWNLOAD
                        "${LLDB_WINDOWS_SDK_URL}"
                        "${LLDB_SDK_ARCHIVE}"
                        SHOW_PROGRESS
                        STATUS LLDB_DOWNLOAD_STATUS
                        LOG LLDB_DOWNLOAD_LOG
                    )
                endif()

                list(GET LLDB_DOWNLOAD_STATUS 0 LLDB_DOWNLOAD_CODE)
                if(NOT LLDB_DOWNLOAD_CODE EQUAL 0)
                    message(FATAL_ERROR "Failed to download LLDB SDK. Status: ${LLDB_DOWNLOAD_STATUS}\n${LLDB_DOWNLOAD_LOG}")
                endif()

                file(ARCHIVE_EXTRACT
                    INPUT "${LLDB_SDK_ARCHIVE}"
                    DESTINATION "${LLDB_DEPS_DIR}"
                )
            endif()

            find_path(LLDB_INCLUDE_DIRS lldb/API/LLDB.h
                PATHS
                    "${LLDB_SDK_EXTRACTED_DIR}/include"
                    "${CMAKE_CURRENT_SOURCE_DIR}/external/lldb-headers/include"
                NO_DEFAULT_PATH
            )
            find_library(LLDB_LIBRARIES NAMES liblldb lldb
                PATHS
                    "${LLDB_SDK_EXTRACTED_DIR}/lib"
                NO_DEFAULT_PATH
            )

            if(LLDB_INCLUDE_DIRS AND LLDB_LIBRARIES)
                set(LLDB_FOUND TRUE)
                message(STATUS "Using auto-fetched LLDB SDK from: ${LLDB_SDK_EXTRACTED_DIR}")
            endif()
        endif()
    elseif(APPLE)
        set(LLDB_FRAMEWORK "/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework")
        if(EXISTS ${LLDB_FRAMEWORK})
            set(LLDB_INCLUDE_DIRS "${LLDB_FRAMEWORK}/Headers")
            set(LLDB_LIBRARIES "${LLDB_FRAMEWORK}/LLDB")
            set(LLDB_FOUND TRUE)
        endif()
    else()
        # Linux: Search in versioned LLVM directories
        find_path(LLDB_INCLUDE_DIRS lldb/API/LLDB.h
            PATHS
                "$ENV{LLVM_DIR}/include"
                /usr/lib/llvm-18/include
                /usr/lib/llvm-17/include
                /usr/lib/llvm-16/include
                /usr/include
                /usr/local/include
        )
        find_library(LLDB_LIBRARIES NAMES lldb lldb-18 lldb-17 lldb-16
            PATHS
                "$ENV{LLVM_DIR}/lib"
                /usr/lib/x86_64-linux-gnu
                /usr/lib
                /usr/local/lib
        )
        if(LLDB_INCLUDE_DIRS AND LLDB_LIBRARIES)
            set(LLDB_FOUND TRUE)
        endif()
    endif()
endif()

if(NOT LLDB_FOUND)
    if(WIN32)
        message(FATAL_ERROR
            "LLDB not found. Set LLVM_DIR, or keep LLDB_AUTO_FETCH=ON and provide a valid LLDB_WINDOWS_SDK_URL (and optional LLDB_WINDOWS_SDK_SHA256)."
        )
    elseif(APPLE)
        message(FATAL_ERROR "LLDB not found. Install Xcode or Xcode Command Line Tools")
    else()
        message(FATAL_ERROR "LLDB not found. Install liblldb-dev (apt) or set LLVM_DIR environment variable")
    endif()
endif()

message(STATUS "LLDB include: ${LLDB_INCLUDE_DIRS}")
message(STATUS "LLDB library: ${LLDB_LIBRARIES}")

# Enable position-independent code for all targets (required for shared library)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# LLDB Copilot shared library (plugin)
add_library(lldb_copilot SHARED
    lldb_client.cpp
    lldb_commands.cpp
    plugin.cpp
    settings.cpp
    session_store.cpp
)

target_include_directories(lldb_copilot
    PRIVATE
        ${LLDB_INCLUDE_DIRS}
)

target_link_libraries(lldb_copilot
    PRIVATE
        ${LLDB_LIBRARIES}
        libagents         # Unified provider library
)

# On macOS, need to handle framework properly
if(APPLE)
    target_link_options(lldb_copilot PRIVATE -undefined dynamic_lookup)
endif()

# On Windows, export symbol with Itanium-mangled name that LLDB expects
if(WIN32)
    target_sources(lldb_copilot PRIVATE lldb_copilot.def)
endif()

set_target_properties(lldb_copilot PROPERTIES
    PREFIX ""
    OUTPUT_NAME "lldb_copilot"
)
