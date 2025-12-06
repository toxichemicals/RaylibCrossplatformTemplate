# 🎮 Raylib Cross-Platform Build Template (Arch Linux Focused)

This repository provides a streamlined template for creating **Raylib** games with comprehensive cross-platform build support. It is optimized for use on an **Arch Linux** system but includes instructions for general dependency installation.

Using the included build scripts, you can compile your C game source (`main.c`) into executables for:

* **Linux (AMD64/i386)**

* **Windows (32-bit / 64-bit)**

* **Web (JavaScript and WebAssembly)**

## 🚀 Getting Started

### Prerequisites (Arch Linux)

This setup assumes you are running Arch Linux and have the standard `pacman` package manager available.

1. **Install Core Toolchains & Dependencies:**
   Run the included script to install all necessary GCC, MinGW (for Windows cross-compilation), and 32-bit libraries for Linux static linking:

./installallarch.sh


2. **Setup Portable Emscripten SDK (for Web builds):**
Run this script to clone the Emscripten SDK (emsdk) into the local `emsdk_portable` folder and activate the latest stable toolchain.

./archemsdk.sh


### Dependencies (Non-Arch Systems)

If you are **not** on Arch Linux, you must manually install the following dependencies to replicate the environment:

| Platform | Required Tools | Purpose | 
| ----- | ----- | ----- | 
| **Linux (Native)** | `gcc` | Standard C compilation | 
| **Windows (Cross)** | **MinGW-w64** compiler suite | Enables `i686-w64-mingw32-gcc` and `x86_64-w64-mingw32-gcc` | 
| **Web (WASM/JS)** | **Emscripten SDK (emsdk)** | Provides the `emcc` toolchain for WebAssembly | 

## ⚙️ Repository Structure & Files

| File/Folder | Description | Purpose | 
| ----- | ----- | ----- | 
| **`src/`** | **Source directory** |The primary directory for storing build files, such as main.c in this template. |
| **`src/main.c`** | The primary Raylib game source code. | This is the file compiled into all targets (e.g., `CoolLinux`, `CoolWin64.exe`). | 
| **`raylib/`** | Contains pre-compiled Raylib binaries. | Includes static libraries for all supported platforms (Linux, Win32/64, Web). | 
| **`assets/`** | Placeholder asset directory. | Used to embed images, sounds, or other resources into the final builds. | 
| **`builds/`** | **Output Directory.** | All compiled executables and archives are placed here. | 
| **`minimalui.html`** | HTML shell template. | Used by Emscripten to generate the final Web builds. | 
| **`build.sh`** | **Primary Build Script.** | Orchestrates the entire cross-platform compilation process. | 
| **`installallarch.sh`** | **Setup Script 1.** | Installs GCC and MinGW dependencies via `pacman` (Arch only). | 
| **`archemsdk.sh`** | **Setup Script 2.** | Clones and sets up the portable Emscripten SDK (Arch only). | 

## 🛠️ The Build Process

The entire build process is managed by the `./build.sh` script.

### Running the Build

./build.sh


### Build Script Options

| Flag | Description | 
 | ----- | ----- | 
| **`-fc`** | **Full Clean.** Deletes the entire `builds/` directory before starting. | 
| **`--no-web`** | Skips the entire Web build section, useful if you only need native targets. | 
| **`--nopemsdk`** | Skips the automatic check for the local `emsdk_portable` folder and uses the system's `emcc` (if available). | 

### What `build.sh` Does:

1. **Cleans:** Removes previous build artifacts (unless `-fc` is used, which does a full clean).

2. **Native Builds:**

   * Compiles `main.c` using standard `gcc` for Linux targets, creating executables like `CoolLinux`.

   * Compiles `main.c` using the **MinGW-w64 cross-compilers** (`i686-w64-mingw32-gcc` and `x86_64-w64-mingw32-gcc`) for static Windows executables (e.g., `CoolWin64.exe`).

3. **Web Build Setup:**

   * Checks for the local `emsdk_portable` directory. If found, it automatically sources the environment.

   * If not found, it prompts the user to continue using the system's `emcc`.

4. **Web Builds:**

   * Compiles to **WebAssembly (.wasm)**, bundled into `CoolWebWASM.html`.

   * Compiles to **Pure JavaScript** (using `-s WASM=0`), bundled into `CoolWebJS.html`.

5. **Packaging:** Creates compressed `.tar` and `.zip` archives of the final builds in the `builds/` directory.
