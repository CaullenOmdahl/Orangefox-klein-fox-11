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
    echo "[INFO] Updating existing repository at scripts."
    cd scripts && git pull origin master
    cd ..
fi

# Run setup scripts
cd scripts
sudo bash setup/android_build_env.sh
sudo bash setup/install_android_sdk.sh || true

# Configure Git
git config --global user.name "Caullen Omdahl"
git config --global user.email "Caullen.Omdahl@gmail.com"

# Create OrangeFox sync directory
mkdir -p ~/OrangeFox_sync
cd ~/OrangeFox_sync

# Clone OrangeFox sync repository
if [ ! -d "sync" ]; then
    git clone https://gitlab.com/OrangeFox/sync.git
else
    echo "[INFO] Updating existing repository at sync."
    cd sync && git pull origin main
    cd ..
fi

# Run orangefox_sync script
cd ~/OrangeFox_sync/sync/
./orangefox_sync.sh --branch 11.0 --path ~/fox_11.0

# Clone device tree
cd ~/fox_11.0/device/
if [ ! -d "blackshark/klein" ]; then
    git clone https://github.com/CaullenOmdahl/Blackshark-3-TWRP-Device-Tree.git blackshark/klein
else
    echo "[INFO] Updating existing device tree."
    cd blackshark/klein && git pull origin main
fi

# Set environment variables
cd ~/fox_11.0
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

# Start build
lunch twrp_klein-eng && mka adbd recoveryimage

# Build complete
echo "[INFO] Build process completed successfully."
