#!/bin/bash

# --- Configuration ---
PORTABLE_EMSDK_DIR="emsdk_portable" 

# --- Raylib Path Variables ---
RAYLIB_LINUX_AMD64="raylib/raylib-5.5_linux_amd64"
RAYLIB_LINUX_I386="raylib/raylib-5.5_linux_i386"
RAYLIB_WIN32="raylib/raylib-5.5_win32_mingw-w64"
RAYLIB_WIN64="raylib/raylib-5.5_win64_mingw-w64"
RAYLIB_WEB="raylib/raylib-5.5_webassembly/raylib-5.5_webassembly"

# --- 1. Detect Flags & Help ---
EMSDK_AUTODETECT=true 
EMSDK_SKIP_WEB=false
SKIP_ERRORS=false
EXTRA_FLAGS=""
FULL_CLEAN=false

show_help() {
    echo "Usage: ./build.sh [options]"
    echo " "
    echo "Options:"
    echo "  -h, --help                Show this help message"
    echo "  -fc                       Full clean: deletes 'builds' directory before starting"
    echo "  --nopemsdk                Disable portable emsdk detection (use system emcc)"
    echo "  --no-web                  Skip the Web/WASM build targets"
    echo "  --skip                    Continue execution even if a build target fails"
    echo "  --Extraflags=\"flags\"      Add additional compiler flags to every target"
    echo " "
    exit 0
}

for arg in "$@"; do
    case "$arg" in
        -h|--help)
            show_help
            ;;
        -fc)
            FULL_CLEAN=true
            ;;
        --nopemsdk)
            EMSDK_AUTODETECT=false
            ;;
        --no-web)
            EMSDK_SKIP_WEB=true
            ;;
        --skip)
            SKIP_ERRORS=true
            ;;
        --Extraflags=*)
            EXTRA_FLAGS="${arg#*=}"
            ;;
    esac
done

# --- Error Handling Wrapper ---
# This function checks the exit code of the last command.
check_status() {
    local exit_code=$?
    local task_name=$1
    if [ $exit_code -ne 0 ]; then
        if [ "$SKIP_ERRORS" = true ]; then
            echo "⚠️  Warning: $task_name failed. Skipping as requested..."
        else
            echo "❌ Error: $task_name failed with exit code $exit_code. Aborting."
            exit $exit_code
        fi
    fi
}

if [ "$FULL_CLEAN" = true ]; then
    echo "Full Clean Detected (-fc). Removing all build artifacts."
    rm -rf builds
    mkdir builds
    check_status "Full Clean"
else
    echo "Standard Build Mode. Use -fc for a Full Clean."
fi

mkdir -p builds
echo "Cleaning builds and archives."
rm -rf builds/*.tar builds/LinuxLatest builds/Linuxi386Latest builds/Win32Latest builds/Win64Latest builds/WebLatest
mkdir -p builds/LinuxLatest builds/Linuxi386Latest builds/Win32Latest builds/Win64Latest builds/WebLatest

# --- Helper Function for Cross-Compiling and Packaging ---
function build_target {
    local TARGET_NAME=$1      
    local COMPILER=$2         
    local RAYLIB_BASE_PATH=$3 
    local STATIC_LIBS=$4      
    local LINK_FLAGS=$5       

    local OUTPUT_DIR="builds/${TARGET_NAME}Latest"
    local OUTPUT_FILE="${OUTPUT_DIR}/Cool${TARGET_NAME}"
    local TARGET_DIR_ROOT="${TARGET_NAME}Latest"

    echo "--- Building $TARGET_NAME ---"

    # Injected EXTRA_FLAGS here
    $COMPILER src/main.c -o $OUTPUT_FILE \
        -I./${RAYLIB_BASE_PATH}/include \
        -L./${RAYLIB_BASE_PATH}/lib \
        ${LINK_FLAGS} \
        ${EXTRA_FLAGS} \
        -lraylib $STATIC_LIBS
    
    check_status "Compilation of $TARGET_NAME"

    echo "Copying assets into $TARGET_NAME release."
    cp -r assets $OUTPUT_DIR/
    check_status "Asset copy for $TARGET_NAME"

    echo "Packing into ${TARGET_NAME}Latest.tar"
    tar -cvf builds/${TARGET_NAME}Latest.tar -C builds $TARGET_DIR_ROOT
    check_status "Packing $TARGET_NAME"
}

# --- 2. NATIVE/CROSS-PLATFORM BUILDS ---

build_target "Linux" "gcc" "${RAYLIB_LINUX_AMD64}" "-lrt -lX11 -lGL -lm -lpthread -ldl" ""
build_target "Linuxi386" "gcc -m32" "${RAYLIB_LINUX_I386}" "-lrt -lX11 -lGL -lm -lpthread -ldl" ""
build_target "Win32" "i686-w64-mingw32-gcc" "${RAYLIB_WIN32}" "-lopengl32 -lgdi32 -lwinmm" "-static"
build_target "Win64" "x86_64-w64-mingw32-gcc" "${RAYLIB_WIN64}" "-lopengl32 -lgdi32 -lwinmm" "-static"

# --- 3. WEB BUILDS ---

if [ "$EMSDK_SKIP_WEB" = false ]; then
    EMSDK_ENV_SCRIPT="${PORTABLE_EMSDK_DIR}/emsdk_env.sh"

    if $EMSDK_AUTODETECT && [ -f "$EMSDK_ENV_SCRIPT" ]; then
        source "$EMSDK_ENV_SCRIPT"
    elif $EMSDK_AUTODETECT; then
        echo "Portable emsdk NOT found."
        read -r -p "Proceed with system 'emcc' if available? Y/N: " PROCEED_WEB
        [[ ! "$PROCEED_WEB" =~ ^[Yy]$ ]] && EMSDK_SKIP_WEB=true
    fi

    if [ "$EMSDK_SKIP_WEB" = false ]; then
        if ! command -v emcc &> /dev/null; then
            echo "❌ Error: 'emcc' not found."
            [ "$SKIP_ERRORS" = true ] && EMSDK_SKIP_WEB=true || exit 1
        fi
    fi

    if [ "$EMSDK_SKIP_WEB" = false ]; then
        # WASM build with EXTRA_FLAGS
        emcc src/main.c -o builds/WebLatest/CoolWebWASM.html \
            -s USE_GLFW=3 -s ASYNCIFY -s SINGLE_FILE=1 -s FORCE_FILESYSTEM=1 \
            -s ALLOW_MEMORY_GROWTH=1 -lraylib ${EXTRA_FLAGS} \
            -I./${RAYLIB_WEB}/include -L./${RAYLIB_WEB}/lib \
            --shell-file src/minimalui.html --embed-file assets
        check_status "Web WASM build"

        # JS build with EXTRA_FLAGS
        emcc src/main.c -o builds/WebLatest/CoolWebJS.html \
            -s USE_GLFW=3 -s ASYNCIFY -s SINGLE_FILE=1 -s FORCE_FILESYSTEM=1 \
            -s ALLOW_MEMORY_GROWTH=1 -s WASM=0 -lraylib ${EXTRA_FLAGS} \
            -I./${RAYLIB_WEB}/include -L./${RAYLIB_WEB}/lib \
            --shell-file src/minimalui.html --embed-file assets
        check_status "Web JS build"

        tar -cvf builds/WebLatest.tar -C builds WebLatest
        check_status "Web Packaging"
    fi
fi

# --- 4. Final Packaging ---

echo "Packing AllBuilds.tar"
tar -cvf builds/AllBuilds.tar builds/*.tar builds/LinuxLatest builds/Linuxi386Latest builds/Win32Latest builds/Win64Latest builds/WebLatest
check_status "Final Tarball"

echo "Packing AllBuilds.zip"
zip -r -9 builds/AllBuilds.zip builds -x "builds/AllBuilds.tar"
check_status "Final Zip"

echo "Build Process Complete."
