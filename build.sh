#!/bin/bash

# --- Configuration ---
PORTABLE_EMSDK_DIR="emsdk_portable"
RAY_HEADERS="raylibsrc/src"
RAYLIB_WEB="raylib/raylib-5.5_webassembly/raylib-5.5_webassembly"

# --- 0. Static Library Check ---
REQUIRED_LIBS=("libraylib_linux64.a" "libraylib_linux32.a" "libraylib_win64.a" "libraylib_win32.a")
MISSING=false
for lib in "${REQUIRED_LIBS[@]}"; do
    [ ! -f "src/$lib" ] && MISSING=true
done

if [ "$MISSING" = true ]; then
    echo "⚠️  Some static libraries are missing in src/"
    read -r -p "Run ./buildray.sh to generate all 4 architectures? (y/n): " RUN_GEN
    if [[ "$RUN_GEN" =~ ^[Yy]$ ]]; then
        ./buildray.sh
    else
        echo "❌ Aborting." && exit 1
    fi
fi

# --- 1. Flags & Help ---
EMSDK_AUTODETECT=true
EMSDK_SKIP_WEB=false
SKIP_ERRORS=false
EXTRA_FLAGS=""
FULL_CLEAN=false

for arg in "$@"; do
    case "$arg" in
        -fc) FULL_CLEAN=true ;;
        --nopemsdk) EMSDK_AUTODETECT=false ;;
        --no-web) EMSDK_SKIP_WEB=true ;;
        --skip) SKIP_ERRORS=true ;;
        --Extraflags=*) EXTRA_FLAGS="${arg#*=}" ;;
    esac
done

check_status() {
    [ $? -ne 0 ] && { [ "$SKIP_ERRORS" = true ] && echo "⚠️  $1 failed. Skipping..." || { echo "❌ $1 failed. Aborting."; exit 1; }; }
}

[ "$FULL_CLEAN" = true ] && rm -rf builds
mkdir -p builds/LinuxLatest builds/Linuxi386Latest builds/Win32Latest builds/Win64Latest builds/WebLatest

# --- 2. Helper Function ---
function build_target {
    local TARGET_NAME=$1
    local COMPILER=$2
    local STATIC_LIB=$3
    local LINK_FLAGS=$4
    local OUTPUT_DIR="builds/${TARGET_NAME}Latest"
    local EXT=""
    [[ "$TARGET_NAME" == Win* ]] && EXT=".exe"
    local OUTPUT_FILE="${OUTPUT_DIR}/Cool${TARGET_NAME}${EXT}"

    echo "--- Building $TARGET_NAME (Static) ---"
    $COMPILER src/main.c -o "$OUTPUT_FILE" -I"$RAY_HEADERS" "$STATIC_LIB" ${LINK_FLAGS} ${EXTRA_FLAGS}
    check_status "Compilation of $TARGET_NAME"

    [ -d "assets" ] && cp -r assets "$OUTPUT_DIR/" 2>/dev/null
    tar -cvf "builds/${TARGET_NAME}Latest.tar" -C builds "${TARGET_NAME}Latest" > /dev/null
}

# --- 3. Run Build Targets ---
build_target "Linux"     "gcc"                   "src/libraylib_linux64.a" "-lGL -lm -lpthread -ldl -lrt -lX11"
build_target "Linuxi386" "gcc -m32"              "src/libraylib_linux32.a" "-lGL -lm -lpthread -ldl -lrt -lX11"
build_target "Win64"     "x86_64-w64-mingw32-gcc" "src/libraylib_win64.a"   "-lopengl32 -lgdi32 -lwinmm -static"
build_target "Win32"     "i686-w64-mingw32-gcc"   "src/libraylib_win32.a"   "-lopengl32 -lgdi32 -lwinmm -static"

# --- 4. Web Builds ---
if [ "$EMSDK_SKIP_WEB" = false ]; then
    [ -f "${PORTABLE_EMSDK_DIR}/emsdk_env.sh" ] && source "${PORTABLE_EMSDK_DIR}/emsdk_env.sh"
    if command -v emcc &> /dev/null; then
        echo "--- Building Web WASM & JS ---"
        emcc src/main.c -o builds/WebLatest/CoolWebWASM.html -s USE_GLFW=3 -s ASYNCIFY -s SINGLE_FILE=1 -s FORCE_FILESYSTEM=1 -s ALLOW_MEMORY_GROWTH=1 -lraylib ${EXTRA_FLAGS} -I./${RAYLIB_WEB}/include -L./${RAYLIB_WEB}/lib --shell-file src/minimalui.html --embed-file assets
        check_status "Web WASM"
        emcc src/main.c -o builds/WebLatest/CoolWebJS.html -s USE_GLFW=3 -s ASYNCIFY -s SINGLE_FILE=1 -s FORCE_FILESYSTEM=1 -s ALLOW_MEMORY_GROWTH=1 -s WASM=0 -lraylib ${EXTRA_FLAGS} -I./${RAYLIB_WEB}/include -L./${RAYLIB_WEB}/lib --shell-file src/minimalui.html --embed-file assets
        check_status "Web JS"
        tar -cvf builds/WebLatest.tar -C builds WebLatest > /dev/null
    fi
fi

# --- 5. Final Packaging ---
echo "Finalizing Packages..."
tar -cvf builds/AllBuilds.tar builds/*.tar > /dev/null
command -v zip &> /dev/null && zip -r -9 builds/AllBuilds.zip builds -x "builds/AllBuilds.tar" > /dev/null
echo "Build Process Complete."#!/bin/bash

# --- Configuration ---
PORTABLE_EMSDK_DIR="emsdk_portable"
RAY_HEADERS="raylibsrc/src"
RAYLIB_WEB="raylib/raylib-5.5_webassembly/raylib-5.5_webassembly"

# --- 0. Static Library Check ---
REQUIRED_LIBS=("libraylib_linux64.a" "libraylib_linux32.a" "libraylib_win64.a" "libraylib_win32.a")
MISSING=false
for lib in "${REQUIRED_LIBS[@]}"; do
    [ ! -f "src/$lib" ] && MISSING=true
done

if [ "$MISSING" = true ]; then
    echo "⚠️  Some static libraries are missing in src/"
    read -r -p "Run ./buildray.sh to generate all 4 architectures? (y/n): " RUN_GEN
    if [[ "$RUN_GEN" =~ ^[Yy]$ ]]; then
        ./buildray.sh
    else
        echo "❌ Aborting." && exit 1
    fi
fi

# --- 1. Flags & Help ---
EMSDK_AUTODETECT=true
EMSDK_SKIP_WEB=false
SKIP_ERRORS=false
EXTRA_FLAGS=""
FULL_CLEAN=false

for arg in "$@"; do
    case "$arg" in
        -fc) FULL_CLEAN=true ;;
        --nopemsdk) EMSDK_AUTODETECT=false ;;
        --no-web) EMSDK_SKIP_WEB=true ;;
        --skip) SKIP_ERRORS=true ;;
        --Extraflags=*) EXTRA_FLAGS="${arg#*=}" ;;
    esac
done

check_status() {
    [ $? -ne 0 ] && { [ "$SKIP_ERRORS" = true ] && echo "⚠️  $1 failed. Skipping..." || { echo "❌ $1 failed. Aborting."; exit 1; }; }
}

[ "$FULL_CLEAN" = true ] && rm -rf builds
mkdir -p builds/LinuxLatest builds/Linuxi386Latest builds/Win32Latest builds/Win64Latest builds/WebLatest

# --- 2. Helper Function ---
function build_target {
    local TARGET_NAME=$1
    local COMPILER=$2
    local STATIC_LIB=$3
    local LINK_FLAGS=$4
    local OUTPUT_DIR="builds/${TARGET_NAME}Latest"
    local EXT=""
    [[ "$TARGET_NAME" == Win* ]] && EXT=".exe"
    local OUTPUT_FILE="${OUTPUT_DIR}/Cool${TARGET_NAME}${EXT}"

    echo "--- Building $TARGET_NAME (Static) ---"
    $COMPILER src/main.c -o "$OUTPUT_FILE" -I"$RAY_HEADERS" "$STATIC_LIB" ${LINK_FLAGS} ${EXTRA_FLAGS}
    check_status "Compilation of $TARGET_NAME"

    [ -d "assets" ] && cp -r assets "$OUTPUT_DIR/" 2>/dev/null
    tar -cvf "builds/${TARGET_NAME}Latest.tar" -C builds "${TARGET_NAME}Latest" > /dev/null
}

# --- 3. Run Build Targets ---
build_target "Linux"     "gcc"                   "src/libraylib_linux64.a" "-lGL -lm -lpthread -ldl -lrt -lX11"
build_target "Linuxi386" "gcc -m32"              "src/libraylib_linux32.a" "-lGL -lm -lpthread -ldl -lrt -lX11"
build_target "Win64"     "x86_64-w64-mingw32-gcc" "src/libraylib_win64.a"   "-lopengl32 -lgdi32 -lwinmm -static"
build_target "Win32"     "i686-w64-mingw32-gcc"   "src/libraylib_win32.a"   "-lopengl32 -lgdi32 -lwinmm -static"

# --- 4. Web Builds ---
if [ "$EMSDK_SKIP_WEB" = false ]; then
    [ -f "${PORTABLE_EMSDK_DIR}/emsdk_env.sh" ] && source "${PORTABLE_EMSDK_DIR}/emsdk_env.sh"
    if command -v emcc &> /dev/null; then
        echo "--- Building Web WASM & JS ---"
        emcc src/main.c -o builds/WebLatest/CoolWebWASM.html -s USE_GLFW=3 -s ASYNCIFY -s SINGLE_FILE=1 -s FORCE_FILESYSTEM=1 -s ALLOW_MEMORY_GROWTH=1 -lraylib ${EXTRA_FLAGS} -I./${RAYLIB_WEB}/include -L./${RAYLIB_WEB}/lib --shell-file src/minimalui.html --embed-file assets
        check_status "Web WASM"
        emcc src/main.c -o builds/WebLatest/CoolWebJS.html -s USE_GLFW=3 -s ASYNCIFY -s SINGLE_FILE=1 -s FORCE_FILESYSTEM=1 -s ALLOW_MEMORY_GROWTH=1 -s WASM=0 -lraylib ${EXTRA_FLAGS} -I./${RAYLIB_WEB}/include -L./${RAYLIB_WEB}/lib --shell-file src/minimalui.html --embed-file assets
        check_status "Web JS"
        tar -cvf builds/WebLatest.tar -C builds WebLatest > /dev/null
    fi
fi

# --- 5. Final Packaging ---
echo "Finalizing Packages..."
tar -cvf builds/AllBuilds.tar builds/*.tar > /dev/null
command -v zip &> /dev/null && zip -r -9 builds/AllBuilds.zip builds -x "builds/AllBuilds.tar" > /dev/null
echo "Build Process Complete."
