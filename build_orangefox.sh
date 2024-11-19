#!/bin/bash

# New OrangeFox Recovery Build Script
# Author: Caullen Omdahl
# Description: Improved build script with better error handling and logging
# SPDX-License-Identifier: GPL-3.0-only

# Log setup
LOG_FILE="orangefox_build.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Exit immediately if a command exits with a non-zero status
set -e

# Function to handle errors
handle_error() {
    echo "[ERROR] An error occurred on line $1. Check the log for details." >&2
    exit 1
}
trap 'handle_error $LINENO' ERR

# Update and upgrade system
sudo apt update && sudo apt upgrade -y

# Install necessary packages
sudo apt install -y aria2 git gnupg flex bison build-essential zip curl zlib1g-dev \
    gcc-multilib g++-multilib libc6-dev-i386 libncurses5-dev x11proto-core-dev libx11-dev \
    lib32z1-dev ccache libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig imagemagick \
    python2 python3 libssl-dev repo python-is-python3

# Clone scripts repository
if [ ! -d "scripts" ]; then
    git clone https://gitlab.com/OrangeFox/misc/scripts
else
    echo "[INFO] Scripts directory already exists. Skipping cloning."
fi

cd scripts

# Run setup scripts
if [ -f "setup/android_build_env.sh" ]; then
    sudo bash setup/android_build_env.sh
else
    echo "[ERROR] android_build_env.sh not found!" >&2
    exit 1
fi

if [ -f "setup/install_android_sdk.sh" ]; then
    sudo bash setup/install_android_sdk.sh
else
    echo "[ERROR] install_android_sdk.sh not found!" >&2
    exit 1
fi

# Configure Git
GIT_NAME="Caullen Omdahl"
GIT_EMAIL="Caullen.Omdahl@gmail.com"
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

# Create OrangeFox sync directory
SYNC_DIR="$HOME/OrangeFox_sync"
mkdir -p "$SYNC_DIR"
cd "$SYNC_DIR"

# Clone OrangeFox sync repository
if [ ! -d "sync" ]; then
    git clone https://gitlab.com/OrangeFox/sync.git
else
    echo "[INFO] Sync directory already exists. Skipping cloning."
fi

cd sync

# Run orangefox_sync script
SYNC_PATH="$HOME/fox_11.0"
if [ -d "$SYNC_PATH" ]; then
    echo "[INFO] Cleaning existing build environment."
    rm -rf "$SYNC_PATH"
fi
./orangefox_sync.sh --branch 11.0 --path "$SYNC_PATH"

# Clone device tree
DEVICE_DIR="$SYNC_PATH/device/blackshark"
if [ -d "$DEVICE_DIR/klein" ]; then
    echo "[INFO] Cleaning existing device tree."
    rm -rf "$DEVICE_DIR/klein"
fi
mkdir -p "$DEVICE_DIR"
git clone https://github.com/CaullenOmdahl/blackshark-klein-device-tree.git "$DEVICE_DIR/klein"

# Set environment variables
cd "$SYNC_PATH"
export ALLOW_MISSING_DEPENDENCIES=true
export FOX_BUILD_DEVICE=klein
export LC_ALL=C

# Setup build environment
if [ -f "build/envsetup.sh" ]; then
    source build/envsetup.sh
else
    echo "[ERROR] build/envsetup.sh not found!" >&2
    exit 1
fi

# Start build with logging of device tree issues
lunch twrp_klein-eng || {
    echo "[ERROR] lunch command failed. Possible issues with the device tree. Check the log for details." >&2
    exit 1
}

mka adbd recoveryimage || {
    echo "[ERROR] Build failed during mka adbd recoveryimage. Possible issues with the device tree. Check the log for details." >&2
    exit 1
}

# Build complete
echo "[INFO] Build process completed successfully."
