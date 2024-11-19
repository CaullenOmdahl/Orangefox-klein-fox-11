#!/bin/bash

# New OrangeFox Recovery Build Script
# Author: Caullen Omdahl
# Description: Improved build script with better error handling and logging, 
#              utilizing efficiency improvements for rerun, multithreading, 
#              and incremental updates.
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

# Function to install necessary packages (skip if already installed)
install_packages() {
    echo "[INFO] Installing necessary packages..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y aria2 git gnupg flex bison build-essential zip curl zlib1g-dev \
        gcc-multilib g++-multilib libc6-dev-i386 libncurses5-dev x11proto-core-dev libx11-dev \
        lib32z1-dev ccache libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig imagemagick \
        python2 python3 libssl-dev repo python-is-python3
}

# Clone or update repository function
clone_or_update_repo() {
    local repo_url=$1
    local target_dir=$2
    local branch=${3:-master}
    if [ ! -d "$target_dir" ]; then
        git clone -b "$branch" "$repo_url" "$target_dir"
    else
        echo "[INFO] Updating existing repository at $target_dir."
        cd "$target_dir" && git fetch && git checkout "$branch" && git pull origin "$branch"
    fi
}

# Install necessary packages
install_packages

# Clone or update scripts repository
clone_or_update_repo "https://gitlab.com/OrangeFox/misc/scripts" "scripts"

# Run setup scripts
cd scripts

if [ -f "setup/android_build_env.sh" ]; then
    sudo bash setup/android_build_env.sh
else
    echo "[ERROR] android_build_env.sh not found!" >&2
    exit 1
fi

if [ -f "setup/install_android_sdk.sh" ]; then
    sudo bash setup/install_android_sdk.sh || true
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

# Clone or update OrangeFox sync repository
clone_or_update_repo "https://gitlab.com/OrangeFox/sync.git" "sync" "main"

cd sync

# Run orangefox_sync script with multithreading enabled where possible
SYNC_PATH="$HOME/fox_11.0"
if [ -d "$SYNC_PATH" ]; then
    echo "[INFO] Updating existing build environment."
    repo sync -j$(nproc) || {
        echo "[ERROR] Failed to update repository. Check log for details." >&2
        exit 1
    }
else
    ./orangefox_sync.sh --branch 11.0 --path "$SYNC_PATH"
fi

# Clone or update device tree
DEVICE_DIR="$SYNC_PATH/device/blackshark"
clone_or_update_repo "https://github.com/CaullenOmdahl/blackshark-klein-device-tree.git" "$DEVICE_DIR/klein" "main"

# Set environment variables
cd "$SYNC_PATH"
export ALLOW_MISSING_DEPENDENCIES=true
export FOX_BUILD_DEVICE=klein
export LC_ALL=C

# Setup build environment
if [ -f "build/envsetup.sh" ]; then
    echo "[INFO] Setting up build environment."
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

# Build recovery image using multithreading
mka -j$(nproc) adbd recoveryimage || {
    echo "[ERROR] Build failed during mka adbd recoveryimage. Possible issues with the device tree. Check the log for details." >&2
    exit 1
}

# Build complete
echo "[INFO] Build process completed successfully."
