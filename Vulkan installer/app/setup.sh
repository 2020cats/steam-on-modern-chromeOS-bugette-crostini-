#!/bin/bash

if ! command -v python3 >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y python3
  sudo apt install python3-tk
fi

APP_DIR="$HOME/Vulkan installer"
ICON_NAME="vulkan-installer.png"
DESKTOP_FILE="vulkan-installer.desktop"

sudo cp "$APP_DIR/assets/$ICON_NAME" /usr/share/icons/hicolor/48x48/apps/

sudo cp "$APP_DIR/$DESKTOP_FILE" /usr/share/applications/

sudo update-desktop-database
echo "App icon should now appear in your Linux Apps folder!"
