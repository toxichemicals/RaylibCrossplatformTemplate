#!/bin/bash

# --- Configuration ---
PORTABLE_EMSDK_DIR="emsdk_portable"
RAYLIB_WEB="raylib/raylib-5.5_webassembly/raylib-5.5_webassembly"

# Raylib Pre-compiled Paths (Used for Headers and Libs)
RAY_LIN64="raylib/raylib-5.5_linux_amd64"
RAY_LIN32="raylib/raylib-5.5_linux_i386"
RAY_WIN64="raylib/raylib-5.5_win64_mingw-w64"
RAY_WIN32="raylib/raylib-5.5_win32_mingw-w64"

# --- 1. Detect Flags ---
DYNAMIC_LINKING=false
FULL_CLEAN=false
SKIP_ERRORS=false
EXTRA_FLAGS=""

show_help() {
    echo "Usage: ./build.sh [options]"
    echo " "
    echo "Options:"
    echo "  -h, --help                Show this help message"
    echo "  -d, --dynamic             Use dynamic linking (.so/.dll)"
    echo "  -fc                       Full clean: deletes 'builds' directory"
    echo "  --skip                    Continue even if a target fails"
    echo "  --Extraflags=\"flags\"      Add custom compiler flags"
    exit 0
}

for arg in "$@"; do
    case "$arg" in
        -h|--help) show_help ;;
        -d|--dynamic) DYNAMIC_LINKING=true ;;
        -fc) FULL_CLEAN=true ;;
        --skip) SKIP_ERRORS=true ;;
        --Extraflags=*) EXTRA_FLAGS="${arg#*=}" ;;
    esac
done

# --- 2. Setup & Status Check ---
check_status() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        if [ "$SKIP_ERRORS" = true ]; then
            echo "⚠️  Warning: $1 failed. Skipping..."
        else
            echo "❌ Error: $1 failed. Aborting."
            exit $exit_code
        fi
    fi
}

[ "$FULL_CLEAN" = true ] && rm -rf builds
mkdir -p builds/{Linux,Linuxi386,Win32,Win64,Web}Latest

# --- 3. Helper Function ---
function build_target {
    local TARGET_NAME=$1
    local COMPILER=$2
    local TARGET_DIR=$3    # The specific raylib distribution folder
    local LINK_FLAGS=$4
    
    local OUTPUT_DIR="builds/${TARGET_NAME}Latest"
    local EXT=""
    [[ "$TARGET_NAME" == Win* ]] && EXT=".exe"
    local OUTPUT_FILE="${OUTPUT_DIR}/Cool${TARGET_NAME}${EXT}"

    # Set up paths based on your tree structure
    local INC_PATH="./${TARGET_DIR}/include"
    local LIB_PATH="./${TARGET_DIR}/lib"

    if [ "$DYNAMIC_LINKING" = true ]; then
        echo "--- Building $TARGET_NAME (Dynamic) ---"
        $COMPILER src/main.c -o "$OUTPUT_FILE" \
            -I"$INC_PATH" \
            -L"$LIB_PATH" \
            -lraylib ${LINK_FLAGS} ${EXTRA_FLAGS}
        
        # Copy shared libs so the executable can actually run
        cp ${LIB_PATH}/libraylib.{so*,dll} "$OUTPUT_DIR/" 2>/dev/null
    else
        echo "--- Building $TARGET_NAME (Static) ---"
        # We point directly to the libraylib.a inside the distribution folder
        $COMPILER src/main.c -o "$OUTPUT_FILE" \
            -I"$INC_PATH" \
            "${LIB_PATH}/libraylib.a" \
            ${LINK_FLAGS} \
            ${EXTRA_FLAGS}
    fi

    check_status "Compilation of $TARGET_NAME"

    [ -d "assets" ] && cp -r assets "$OUTPUT_DIR/" 2>/dev/null
    tar -cvf "builds/${TARGET_NAME}Latest.tar" -C builds "${TARGET_NAME}Latest" > /dev/null
}

# --- 4. Run Build Targets ---
# Args: Name, Compiler, Raylib-Dist-Folder, Link-Flags
build_target "Linux"     "gcc"                   "$RAY_LIN64" "-lGL -lm -lpthread -ldl -lrt -lX11"
build_target "Linuxi386" "gcc -m32"              "$RAY_LIN32" "-lGL -lm -lpthread -ldl -lrt -lX11"
build_target "Win64"     "x86_64-w64-mingw32-gcc" "$RAY_WIN64" "-lopengl32 -lgdi32 -lwinmm"
build_target "Win32"     "i686-w64-mingw32-gcc"   "$RAY_WIN32" "-lopengl32 -lgdi32 -lwinmm"

# --- 5. Web Builds ---
if [ "$EMSDK_SKIP_WEB" = false ]; then
    [ -f "${PORTABLE_EMSDK_DIR}/emsdk_env.sh" ] && source "${PORTABLE_EMSDK_DIR}/emsdk_env.sh"
    
    if command -v emcc &> /dev/null; then
        echo "--- Building Web WASM & JS ---"
        local WEB_INC="./${RAYLIB_WEB}/include"
        local WEB_LIB="./${RAYLIB_WEB}/lib"

        # WASM build
        emcc src/main.c -o builds/WebLatest/index.html \
            -s USE_GLFW=3 -s ASYNCIFY -s SINGLE_FILE=1 -s FORCE_FILESYSTEM=1 \
            -s ALLOW_MEMORY_GROWTH=1 -lraylib ${EXTRA_FLAGS} \
            -I"$WEB_INC" -L"$WEB_LIB" \
            --shell-file src/minimalui.html --embed-file assets
        check_status "Web Build"
        
        tar -cvf builds/WebLatest.tar -C builds WebLatest > /dev/null
    fi
fi

# --- 6. Final Packaging ---
echo "--- Finalizing Packages ---"
tar -cvf builds/AllBuilds.tar builds/*.tar > /dev/null
if command -v zip &> /dev/null; then
    zip -r -9 builds/AllBuilds.zip builds -x "builds/AllBuilds.tar" > /dev/null
fi

echo "Build Process Complete."
