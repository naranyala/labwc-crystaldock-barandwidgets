# Installing Quickshell on OpenMandriva Linux

This guide explains how to build and install `quickshell` from source on OpenMandriva Linux.

## Prerequisites

Install the build toolchain and Qt6 development packages:

```bash
# Build tools
sudo dnf install -y cmake ninja-build gcc-c++ g++ pkgconf-pkg-config git

# Qt6 development packages
sudo dnf install -y \
    lib64Qt6Core-devel lib64Qt6Gui-devel lib64Qt6Qml-devel \
    lib64Qt6Quick-devel lib64Qt6QuickControls2-devel \
    lib64Qt6Widgets-devel lib64Qt6ShaderTools-devel \
    lib64Qt6WaylandClient-devel lib64Qt6DBus-devel \
    lib64Qt6Network-devel lib64Qt6Test-devel

# Wayland and Vulkan dependencies
sudo dnf install -y \
    lib64wayland-devel wayland-protocols-devel \
    lib64vulkan-devel spirv-tools

# Miscellaneous dependencies
sudo dnf install -y \
    lib64jemalloc-devel lib64pipewire-devel \
    lib64pam-devel
```

## Installation Steps

### 1. Clone the repository

```bash
mkdir -p ~/sources
cd ~/sources
git clone --depth=1 https://github.com/quickshell-mirror/quickshell.git
cd quickshell
```

### 2. Configure the build

Use the following CMake command to avoid common build errors on OpenMandriva (specifically `cpptrace` and `PCH` issues):

```bash
cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DDISTRIBUTOR="OCWS" \
    -DCMAKE_PREFIX_PATH=/usr/local \
    -DVENDOR_CPPTRACE=ON \
    -DNO_PCH=ON
```

**Key Flags Explained:**
- `-DVENDOR_CPPTRACE=ON`: Uses the built-in version of `cpptrace` to avoid incompatibilities with system libraries (e.g., missing `libunwind`).
- `-DNO_PCH=ON`: Disables Precompiled Headers to avoid threading support mismatches during compilation.

### 3. Build and install

```bash
# Build using all available cores
cmake --build build -j$(nproc)

# Install to /usr/local
sudo cmake --install build
```

### 4. Verify Installation

```bash
export PATH="/usr/local/bin:$PATH"
quickshell --version
```

## Troubleshooting

- **"quickshell: command not found"**: Ensure `/usr/local/bin` is in your `PATH`.
- **PCH Error**: If you see `POSIX thread support was disabled in PCH file`, ensure you used `-DNO_PCH=ON`.
- **Cpptrace Error**: If you see `Cpptrace was built without CPPTRACE_UNWIND_WITH_LIBUNWIND`, ensure you used `-DVENDOR_CPPTRACE=ON`.
