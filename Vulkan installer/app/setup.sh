#!/bin/bash

# 1. Check for Python and Tkinter
if ! command -v python3 >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y python3 python3-tk
fi

installerPath=$(find "$HOME" -type f -name "VulkanSteamInstaller.sh" -print -quit)


# Make sure this path is exactly where your files are!
baseDir=$(dirname "$installerPath")
appDir="$baseDir/app"
iconFileName="icon.png"
desktopFilePath="vulkan-installer.desktop"

# Checks if the files actually exist 
if [ ! -f "$appDir/$iconFileName" ]; then
    echo "Error: Cannot find $appDir/$iconFileName"
    exit 1
fi

#Perform the copies
sed -i "s|^Exec=.*|Exec=python3 \"$PYTHON_APP\"|" "$appDir/$desktopFilePath"

sudo cp "$appDir/$iconFileName" "/usr/share/icons/hicolor/48x48/apps/vulkan-installer.png"
sudo cp "$appDir/$desktopFilePath" "/usr/share/applications/"

sudo update-desktop-database
echo "App icon should now appear in your Linux Apps folder!"
