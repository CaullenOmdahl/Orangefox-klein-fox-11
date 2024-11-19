# OrangeFox Recovery Build Script

## Overview

This script automates the process of building the OrangeFox Recovery for the BlackShark SHARK KLE-H0 (codename: klein). It provides an improved, streamlined build process with error handling and logging to help diagnose and resolve issues. This script is designed to work on Linux-based systems and requires several dependencies to be installed for a successful build.

## Features
- Comprehensive error handling to stop the build if something goes wrong.
- Logging of all actions to `orangefox_build.log` for easy troubleshooting.
- Automatic cleaning and re-cloning of the device repository for fresh builds.

## Prerequisites

Before running this script, ensure the following:
- You are using a Linux-based OS (e.g., Ubuntu or Debian).
- You have `sudo` privileges to install necessary dependencies.

The script installs all the necessary dependencies and configures the environment for building OrangeFox Recovery.

## How to Run the Script

To run the script from the Linux console, use the following command:

```bash
bash <(curl -s https://raw.githubusercontent.com/CaullenOmdahl/Orangefox-klein-fox-11/main/build_orangefox.sh)
```

This command will download the script and immediately run it.

### Manual Steps

Alternatively, you can manually clone the repository and run the script:

1. Clone the repository:
   ```bash
   git clone https://github.com/CaullenOmdahl/Orangefox-klein-fox-11.git
   cd Orangefox-klein-fox-11
   ```

2. Run the script:
   ```bash
   bash build_orangefox.sh
   ```

## What the Script Does

1. **System Update and Dependency Installation**
   - Updates and upgrades your system.
   - Installs necessary packages and dependencies for building Android-based recovery images.

2. **Setup Scripts**
   - Clones and runs environment setup scripts for the build.

3. **Git Configuration**
   - Configures Git with the specified username and email.

4. **Sync OrangeFox Sources**
   - Creates a working directory (`~/OrangeFox_sync`) and syncs the required sources for building OrangeFox.

5. **Clone Device Tree**
   - Clones the device tree for the BlackShark SHARK KLE-H0 to ensure compatibility.

6. **Build Process**
   - Sets up the environment.
   - Runs the `lunch` and `mka` commands to build the OrangeFox recovery image.

## Troubleshooting

All errors and important messages are logged to `orangefox_build.log`. If you encounter any issues during the build, refer to this log file. The script also has built-in error handling, which provides informative error messages to help pinpoint the problem.

If you encounter an issue related to the device tree, please copy and paste the relevant error messages from the log and consult for further assistance.

## Notes
- The script ensures that the build environment and device tree are cleaned and re-cloned each time it is run to ensure a clean build.
- The script sets several environment variables required for building OrangeFox Recovery, such as `ALLOW_MISSING_DEPENDENCIES` and `FOX_BUILD_DEVICE`.

## License

This script is licensed under the GPL-3.0 license.

