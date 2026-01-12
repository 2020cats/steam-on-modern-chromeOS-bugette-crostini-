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
pythonAppPath="$appDir/appUI.py"
launcherPath="$appDir/Launcher.sh"

# Checks if the files actually exist 
if [ ! -f "$appDir/$iconFileName" ]; then
    echo "Error: Cannot find $appDir/$iconFileName"
    exit 1
fi

#add premissions to be safe
chmod +x "$appDir/Launcher.sh"
chmod +x "$appDir/appUI.py"

#Perform the copies
sed -i 's|^Path=.*|Path="'"$appDir"'"|' "$appDir/$desktopFilePath"
sed -i 's|^Exec=.*|Exec="'"$launcherPath"'"|' "$appDir/$desktopFilePath"

sudo cp "$appDir/$iconFileName" "/usr/share/icons/hicolor/48x48/apps/vulkan-installer.png"
sudo cp "$appDir/$desktopFilePath" "/usr/share/applications/"

#Ensures icon actually shows
sudo chmod 755 /usr/share/applications
sudo chmod 644 "/usr/share/applications/$desktopFilePath"
sudo chmod 644 "/usr/share/icons/hicolor/48x48/apps/vulkan-installer.png"

sudo update-desktop-database
echo "App icon should now appear in your Linux Apps folder!"
