#!/bin/bash

RAY_SRC="raylibsrc/src"
DEST_DIR="src"

if [ ! -d "$RAY_SRC" ]; then
    echo "Error: $RAY_SRC directory not found."
    exit 1
fi

mkdir -p "$DEST_DIR"

build_ray() {
    local COMPILER=$2
    local OUT_NAME=$3
    local EXTRA_FLAGS=$4

    echo "--- Building Raylib for $OUT_NAME ---"
    cd "$RAY_SRC"
    
    make clean

    # We force the defines for X11 and Desktop into the build command
    # This bypasses the Makefile's detection logic which is currently failing you
    if [[ "$OUT_NAME" == *"linux"* ]]; then
        make PLATFORM=PLATFORM_DESKTOP \
             CC="$COMPILER" \
             RAYLIB_LIBTYPE=STATIC \
             CFLAGS="$EXTRA_FLAGS -D_DEFAULT_SOURCE -D_GNU_SOURCE -DPLATFORM_DESKTOP -D_GLFW_X11" \
             -j$(nproc)
    else
        # For Windows, we force the Win32 and OpenGL defines
        make PLATFORM=PLATFORM_DESKTOP \
             OS=Windows_NT \
             CC="$COMPILER" \
             RAYLIB_LIBTYPE=STATIC \
             CFLAGS="$EXTRA_FLAGS -DPLATFORM_DESKTOP -D_GLFW_WIN32 -DGRAPHICS_API_OPENGL_33" \
             -j$(nproc)
    fi

    # Find the resulting file (handles variations in Raylib Makefile versions)
    RESULT=$(find . -name "libraylib.a" | head -n 1)
    if [ -f "$RESULT" ]; then
        mv "$RESULT" "../../$DEST_DIR/$OUT_NAME"
    elif [ -f "../src/libraylib.a" ]; then
        mv ../src/libraylib.a "../../$DEST_DIR/$OUT_NAME"
    else
        echo "❌ Error: Could not find libraylib.a for $OUT_NAME"
        exit 1
    fi
    
    cd ../../
}

# 1. Linux 64-bit
build_ray "LINUX" "gcc" "libraylib_linux64.a" ""

# 2. Linux 32-bit
build_ray "LINUX" "gcc" "libraylib_linux32.a" "-m32"

# 3. Windows 64-bit
build_ray "WINDOWS" "x86_64-w64-mingw32-gcc" "libraylib_win64.a" ""

# 4. Windows 32-bit
build_ray "WINDOWS" "i686-w64-mingw32-gcc" "libraylib_win32.a" ""

echo "---------------------------------"
echo "Done! Libraries moved to $DEST_DIR/"
ls -l "$DEST_DIR"/libraylib_*
