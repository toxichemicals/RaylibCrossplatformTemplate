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
