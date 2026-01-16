#!/bin/bash

# --- Configuration ---
PORTABLE_EMSDK_DIR="emsdk_portable"
RAYLIB_WEB_DIR="raylib/raylib-5.5_webassembly/raylib-5.5_webassembly"

# Raylib Pre-compiled Paths (Desktop)
RAY_LIN64="raylib/raylib-5.5_linux_amd64"
RAY_LIN32="raylib/raylib-5.5_linux_i386"
RAY_WIN64="raylib/raylib-5.5_win64_mingw-w64"
RAY_WIN32="raylib/raylib-5.5_win32_mingw-w64"

# --- 1. Detect Flags ---
DYNAMIC_LINKING=false
FULL_CLEAN=false
SKIP_ERRORS=false
EXTRA_FLAGS=""

for arg in "$@"; do
    case "$arg" in
        -d|--dynamic) DYNAMIC_LINKING=true ;;
        -fc) FULL_CLEAN=true ;;
        --skip) SKIP_ERRORS=true ;;
        --Extraflags=*) EXTRA_FLAGS="${arg#*=}" ;;
    esac
done

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

# --- 2. Desktop Helper Function ---
function build_target {
    local TARGET_NAME=$1
    local COMPILER=$2
    local TARGET_DIR=$3
    local LINK_FLAGS=$4
    
    local OUTPUT_DIR="builds/${TARGET_NAME}Latest"
    local EXT=""
    [[ "$TARGET_NAME" == Win* ]] && EXT=".exe"
    local OUTPUT_FILE="${OUTPUT_DIR}/Cool${TARGET_NAME}${EXT}"

    local INC_PATH="./${TARGET_DIR}/include"
    local LIB_PATH="./${TARGET_DIR}/lib"

    if [ "$DYNAMIC_LINKING" = true ]; then
        echo "--- Building $TARGET_NAME (Dynamic) ---"
        $COMPILER src/main.c -o "$OUTPUT_FILE" \
            -I"$INC_PATH" \
            -L"$LIB_PATH" \
            -lraylib ${LINK_FLAGS} ${EXTRA_FLAGS}
        cp ${LIB_PATH}/libraylib.{so*,dll} "$OUTPUT_DIR/" 2>/dev/null
    else
        echo "--- Building $TARGET_NAME (Static) ---"
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

# --- 3. Run Desktop Targets ---
build_target "Linux"     "gcc"                   "$RAY_LIN64" "-lGL -lm -lpthread -ldl -lrt -lX11"
build_target "Linuxi386" "gcc -m32"              "$RAY_LIN32" "-lGL -lm -lpthread -ldl -lrt -lX11"
build_target "Win64"     "x86_64-w64-mingw32-gcc" "$RAY_WIN64" "-lopengl32 -lgdi32 -lwinmm"
build_target "Win32"     "i686-w64-mingw32-gcc"   "$RAY_WIN32" "-lopengl32 -lgdi32 -lwinmm"

# --- 4. Web Build Section (JS & WASM) ---
EMSDK_ENV="${PORTABLE_EMSDK_DIR}/emsdk_env.sh"
if [ -f "$EMSDK_ENV" ]; then
    source "$EMSDK_ENV"
fi

if command -v emcc &> /dev/null; then
    echo "--- Building Web Targets (Using src/minimalui.html) ---"
    WEB_INC="./${RAYLIB_WEB_DIR}/include"
    WEB_LIB="./${RAYLIB_WEB_DIR}/lib/libraylib.a"
    WEB_OUT="builds/WebLatest"
    
    # Flags for Single-File HTML with embedded assets
    COMMON_WEB_FLAGS="-s USE_GLFW=3 -s ASYNCIFY -s SINGLE_FILE=1 -s FORCE_FILESYSTEM=1 -s ALLOW_MEMORY_GROWTH=1 --shell-file src/minimalui.html --embed-file assets"

    # A. WASM version
    echo "Compiling CoolWebWASM.html..."
    emcc src/main.c -o "${WEB_OUT}/CoolWebWASM.html" \
        -I"$WEB_INC" "$WEB_LIB" \
        $COMMON_WEB_FLAGS \
        ${EXTRA_FLAGS}
    check_status "Web WASM"

    # B. JS version (WASM=0)
    echo "Compiling CoolWebJS.html..."
    emcc src/main.c -o "${WEB_OUT}/CoolWebJS.html" \
        -I"$WEB_INC" "$WEB_LIB" \
        $COMMON_WEB_FLAGS \
        -s WASM=0 \
        ${EXTRA_FLAGS}
    check_status "Web JS"

    tar -cvf builds/WebLatest.tar -C builds WebLatest > /dev/null
else
    echo "⚠️  emcc not found, skipping Web builds."
fi

# --- 5. Final Packaging ---
echo "--- Finalizing Packages ---"
tar -cvf builds/AllBuilds.tar builds/*.tar > /dev/null
if command -v zip &> /dev/null; then
    zip -r -9 builds/AllBuilds.zip builds -x "builds/AllBuilds.tar" > /dev/null
fi

echo "Build Process Complete."
