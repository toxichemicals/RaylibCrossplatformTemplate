#!/bin/bash

# --- Configuration ---
PORTABLE_EMSDK_DIR="emsdk_portable" # Directory where portable emsdk is expected

# --- Raylib Path Variables ---
RAYLIB_LINUX_AMD64="raylib/raylib-5.5_linux_amd64"
RAYLIB_LINUX_I386="raylib/raylib-5.5_linux_i386"
RAYLIB_WIN32="raylib/raylib-5.5_win32_mingw-w64"
RAYLIB_WIN64="raylib/raylib-5.5_win64_mingw-w64"

# Note: The web structure still has double nesting
RAYLIB_WEB="raylib/raylib-5.5_webassembly/raylib-5.5_webassembly"

# --- 1. Detect Flags ---
EMSDK_AUTODETECT=true # Default to detecting portable emsdk
EMSDK_SKIP_WEB=false

for arg in "$@"; do
    case "$arg" in
        -fc)
            FULL_CLEAN=true
            ;;
        --nopemsdk)
            EMSDK_AUTODETECT=false
            ;;
        --no-web)
            EMSDK_SKIP_WEB=true
            ;;
    esac # CORRECTED: Must be closed by 'esac'
done

if [ "$FULL_CLEAN" = true ]; then
    echo "Full Clean Detected (-fc). Removing all build artifacts."
    rm -rf builds
    echo "Cleaned build dir."
    mkdir builds
    echo "Build directory recreated."
    # Note: Shift logic for flags is simplified; assuming flags are checked and then build proceeds.
else
    echo "Standard Build Mode. Use -fc for a Full Clean."
fi

# Attempt to make build if not existing
echo "Attempt to make builds directory if not existing"
mkdir -p builds

# --- Clean and Setup Directories for Standard Build ---
echo "Cleaning builds and archives."
# Clean only x86/x64 and Web directories
rm -rf builds/*.tar builds/LinuxLatest builds/Linuxi386Latest builds/Win32Latest builds/Win64Latest builds/WebLatest
# Setup only x86/x64 and Web directories
mkdir -p builds/LinuxLatest builds/Linuxi386Latest builds/Win32Latest builds/Win64Latest builds/WebLatest


# --- Helper Function for Cross-Compiling and Packaging ---
function build_target {
    local TARGET_NAME=$1      # e.g., Linux, Win32
    local COMPILER=$2         # e.g., gcc, i686-w64-mingw32-gcc
    local RAYLIB_BASE_PATH=$3 # e.g., ${RAYLIB_LINUX_AMD64}
    local STATIC_LIBS=$4      # System libraries for linking
    local LINK_FLAGS=$5       # Optional flags like -static

    local OUTPUT_DIR="builds/${TARGET_NAME}Latest"
    local OUTPUT_FILE="${OUTPUT_DIR}/Cool${TARGET_NAME}"
    local TARGET_DIR_ROOT="${TARGET_NAME}Latest"

    echo "--- Building $TARGET_NAME ---"

    # Compile. Link_FLAGS controls static linking for system libs.
    $COMPILER src/main.c -o $OUTPUT_FILE \
        -I./${RAYLIB_BASE_PATH}/include \
        -L./${RAYLIB_BASE_PATH}/lib \
        ${LINK_FLAGS} \
        -lraylib $STATIC_LIBS

    # Copy assets and package
    echo "Copying assets into $TARGET_NAME release."
    cp assets $OUTPUT_DIR/ -r

    echo "Packing into ${TARGET_NAME}Latest.tar"
    cd builds
    tar -cvf ${TARGET_NAME}Latest.tar $TARGET_DIR_ROOT
    cd ..
} # <-- CORRECT CLOSING BRACE

# --- 2. NATIVE/CROSS-PLATFORM BUILDS (STATIC RAYLIB, DYNAMIC SYSTEM LIBS) ---

# --- x86/x64 Builds (Existing) ---
# Linux x64
build_target "Linux" \
    "gcc" \
    "${RAYLIB_LINUX_AMD64}" \
    "-lrt -lX11 -lGL -lm -lpthread -ldl" \
    "" # Dynamic linking for system libraries on Arch/Linux

# Linux x86
build_target "Linuxi386" \
    "gcc -m32" \
    "${RAYLIB_LINUX_I386}" \
    "-lrt -lX11 -lGL -lm -lpthread -ldl" \
    "" # Dynamic linking for system libraries on Arch/Linux

# Windows x86 (Full Static Linking)
build_target "Win32" \
    "i686-w64-mingw32-gcc" \
    "${RAYLIB_WIN32}" \
    "-lopengl32 -lgdi32 -lwinmm" \
    "-static"

# Windows x64 (Full Static Linking)
build_target "Win64" \
    "x86_64-w64-mingw32-gcc" \
    "${RAYLIB_WIN64}" \
    "-lopengl32 -lgdi32 -lwinmm" \
    "-static"


# --- 3. WEB BUILDS (WASM and JS) ---

echo " "
echo "--- Starting Web Build Configuration ---"

if [ "$EMSDK_SKIP_WEB" = true ]; then
    echo "Skipping Web Build (--no-web flag set)."
else
    # --- Check for portable emsdk ---
    EMSDK_ENV_SCRIPT="${PORTABLE_EMSDK_DIR}/emsdk_env.sh"

    if $EMSDK_AUTODETECT && [ -f "$EMSDK_ENV_SCRIPT" ]; then
        echo "Portable emsdk found. Sourcing environment from: ${EMSDK_ENV_SCRIPT}"
        # Source the emsdk environment script in the current shell
        source "$EMSDK_ENV_SCRIPT"
    elif $EMSDK_AUTODETECT; then
        # Portable emsdk not found, ask the user what to do
        echo "Portable emsdk was NOT found in '${PORTABLE_EMSDK_DIR}':"
        echo "1. If on arch linux, use installallarch.sh, then run archemsdk.sh"
        echo "2. If not on arch linux, install emsdk and when running this script pass --nopemsdk"
        
        read -r -p "Proceed with Web Build (will use system 'emcc' if available)? Y/N: " PROCEED_WEB
        
        if [[ ! "$PROCEED_WEB" =~ ^[Yy]$ ]]; then
            echo "Web build skipped by user."
            EMSDK_SKIP_WEB=true
        else
            echo "Proceeding with system 'emcc' check."
        fi
    else
        echo "Portable emsdk check skipped (--nopemsdk flag set). Using system 'emcc'."
    fi

    # --- Execute Web Build if not skipped ---
    if [ "$EMSDK_SKIP_WEB" = false ]; then
        echo "Building for web via EMCC"
        
        # Check if emcc is actually available now
        if ! command -v emcc &> /dev/null
        then
            echo "❌ Error: 'emcc' command not found. Cannot proceed with web build."
            echo "   Please install emscripten or run this script with a properly configured portable emsdk."
            EMSDK_SKIP_WEB=true # Mark as skipped due to failure
        fi
    fi

    if [ "$EMSDK_SKIP_WEB" = false ]; then

        # --- Build the WASM HTML (WebAssembly) ---
        echo "Building the WASM HTML"
        emcc src/main.c -o builds/WebLatest/CoolWebWASM.html \
            -s USE_GLFW=3 \
            -s ASYNCIFY \
            -s SINGLE_FILE=1 \
            -s FORCE_FILESYSTEM=1 \
            -s ALLOW_MEMORY_GROWTH=1 \
            -lraylib \
            -I./${RAYLIB_WEB}/include \
            -L./${RAYLIB_WEB}/lib \
            --shell-file **src/minimalui.html** \
            --embed-file assets

        # --- Build the JS HTML (Pure JavaScript) ---
        echo "Building the JS HTML"
        emcc src/main.c -o builds/WebLatest/CoolWebJS.html \
            -s USE_GLFW=3 \
            -s ASYNCIFY \
            -s SINGLE_FILE=1 \
            -s FORCE_FILESYSTEM=1 \
            -s ALLOW_MEMORY_GROWTH=1 \
            -s WASM=0 \
            -lraylib \
            -I./${RAYLIB_WEB}/include \
            -L./${RAYLIB_WEB}/lib \
            --shell-file **src/minimalui.html** \
            --embed-file assets

        echo "Packing Web into tar"
        cd builds
        tar -cvf WebLatest.tar WebLatest
        cd ..
        echo "Done building Web"
    fi
fi # End of Web Build Configuration

echo " "
# --- 4. Final Packaging ---

echo "Packing all into single tar (AllBuilds.tar)"
# Contains x86/x64 and Web builds
tar -cvf builds/AllBuilds.tar \
    builds/LinuxLatest builds/Linuxi386Latest builds/Win32Latest builds/Win64Latest \
    builds/WebLatest \
    builds/*.tar
echo "Done packing all into single tar"

echo "Packing all into single zip with max compression (-9), excluding AllBuilds.tar"
# Create the zip archive with recursive (-r) and max compression (-9) flags
# The -x flag is used to explicitly exclude the AllBuilds.tar file
zip -r -9 builds/AllBuilds.zip builds -x builds/AllBuilds.tar
echo "Done packing all into single zip"
