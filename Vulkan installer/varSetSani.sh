#!/bin/bash

echo "Starting Sanitization..."

# Ensure script is executable
[[ -x "$0" ]] || chmod +x "$0" 2>/dev/null

mkdir -p ~/.config/systemd/user/cros-garcon.service.d/
rm -f ~/.config/systemd/user/cros-garcon.service.d/*.conf

# Defines var for image
displayType="wayland,x"

# Define the garcon config path so the script knows where to clean
vulkanConfHome="$HOME/.config/systemd/user/cros-garcon.service.d/vulkan.conf"
touch "$vulkanConfHome"

# 1. Cleanup old entries
vars=("VK_ICD_FILENAMES" "VK_INSTANCE_LAYERS" "WAYLAND_DISPLAY" "XDG_RUNTIME_DIR" "XDG_SESSION_TYPE" "GDK_BACKEND" "QT_QPA_PLATFORM" "SDL_VIDEODRIVER" "DISABLE_WAYLAND_X11_INTEROP" "MESA_VK_DEVICE_SELECT" "STEAM_RUNTIME_PREFER_HOST_LIBRARIES")

echo "Cleaning up old environment configurations..."
for var in "${vars[@]}"; do
    sudo sed -i "/^$var=/d" /etc/environment
    sed -i "/export $var=/d" ~/.bashrc
    # Only try to clean the file if it actually exists
    [ -f "$vulkanConfHome" ] && sed -i "/Environment=\"$var=/d" "$vulkanConfHome"
done

# 2. Find Vulkan ICD files (Virtio-GPU)
vulkanCompiledPath=""
for file in /usr/share/vulkan/icd.d/virtio*; do  
    if [ -f "$file" ]; then
        if [ -z "$vulkanCompiledPath" ]; then
            vulkanCompiledPath="$file"
        else
            vulkanCompiledPath+=":$file"
        fi
    fi
done

echo "Starting var config..."


# 3. Writing to /etc/environment (Global System)
{
    echo "VK_ICD_FILENAMES=$vulkanCompiledPath"
    echo "VK_INSTANCE_LAYERS=VK_LAYER_MESA_device_select"
    echo "VK_LAYER_MESA_device_select=0"
    echo "XDG_SESSION_TYPE=wayland"
    echo "WAYLAND_DISPLAY=wayland-0"
    echo "XDG_RUNTIME_DIR=/run/user/$(id -u)"
    echo "GDK_BACKEND=$displayType"
    echo "QT_QPA_PLATFORM=wayland"
    echo "SDL_VIDEODRIVER=$displayType"
    echo "DISABLE_WAYLAND_X11_INTEROP=0"
    echo "MESA_VK_DEVICE_SELECT=virtio"
} | sudo tee -a /etc/environment > /dev/null

# 4. Writing to ~/.bashrc (Local Shell)
{
    echo "export VK_ICD_FILENAMES=$vulkanCompiledPath"
    echo "export WAYLAND_DISPLAY=wayland-0"
    echo "export XDG_RUNTIME_DIR=/run/user/\$(id -u)"
    echo "export XDG_SESSION_TYPE=wayland"
    echo "export GDK_BACKEND=$displayType"
    echo "export QT_QPA_PLATFORM=wayland"
    echo "export SDL_VIDEODRIVER=$displayType"
    echo "export DISABLE_WAYLAND_X11_INTEROP=0"
    echo "export MESA_VK_DEVICE_SELECT=virtio"
    echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu"
    echo "export STEAM_RUNTIME_PREFER_HOST_LIBRARIES=1"
    echo "export VK_INSTANCE_LAYERS=VK_LAYER_MESA_device_select"
    echo "export MESA_VK_DEVICE_SELECT=virtio"
} >> ~/.bashrc

# 5. Applying to CURRENT Session
export VK_ICD_FILENAMES=$vulkanCompiledPath
export WAYLAND_DISPLAY=wayland-0
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export SDL_VIDEODRIVER=$displayType
export DISABLE_WAYLAND_X11_INTEROP=0
export XDG_SESSION_TYPE=wayland
export GDK_BACKEND=$displayType
export WAYLAND_DISPLAY=wayland-0
export STEAM_RUNTIME_PREFER_HOST_LIBRARIES=1

# 6. Updating Garcon (ChromeOS Launcher Bridge)
mkdir -p "$(dirname "$vulkanConfHome")"
cat <<EOF > "$vulkanConfHome"
[Service]
Environment="VK_ICD_FILENAMES=$vulkanCompiledPath"
Environment="WAYLAND_DISPLAY=wayland-0"
Environment="XDG_RUNTIME_DIR=/run/user/%U"
Environment="XDG_SESSION_TYPE=wayland"
Environment="GDK_BACKEND=$displayType"
Environment="QT_QPA_PLATFORM=wayland"
Environment="SDL_VIDEODRIVER=$displayType"
Environment="DISABLE_WAYLAND_X11_INTEROP=0"
Environment="MESA_VK_DEVICE_SELECT=virtio"
Environment="STEAM_RUNTIME_PREFER_HOST_LIBRARIES=1"
Environment="SDL_VIDEODRIVER=$displayType"
Environment="VK_INSTANCE_LAYERS=VK_LAYER_MESA_device_select"
Environment="MESA_VK_DEVICE_SELECT=virtio"
EOF

if ! grep -q "\[Service\]" "$vulkanConfHome"; then
    echo "[Service]" >> "$vulkanConfHome"
fi


echo "export XDG_RUNTIME_DIR=/run/user/$(id -u)" | sudo tee -a /etc/environment > /dev/null

systemctl --user daemon-reload
systemctl --user import-environment WAYLAND_DISPLAY XDG_RUNTIME_DIR SDL_VIDEODRIVER DISABLE_WAYLAND_X11_INTEROP

echo "Sanitization and config complete."
