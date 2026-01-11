#!/bin/bash
[[ -x "$0" ]] || chmod +x "$0" 2>/dev/null

echo "Starting install backup sanitize"

vulkan64=$(find /usr/lib/x86_64-linux-gnu -name "libvulkan_virtio.so" -o -name "libvulkan_venus.so" | head -n 1)
vulkan32=$(find /usr/lib/i386-linux-gnu -name "libvulkan_virtio.so" -o -name "libvulkan_venus.so" | head -n 1)

if [[ -z "$vulkan64" || -z "$vulkan32" ]]; then
    echo "CRITICAL [FAIL] Vulkan driver files (.so) not found. Steam will crash."
    exit 1
fi

recPackgePath=$(find "$HOME/Vulkan installer/etc/" -name "recommend.txt" | head -n 1)
optPackgePath=$(find "$HOME/Vulkan installer/etc/" -name "optional.txt" | head -n 1)

echo "Upgrading packages and purging optional packages"

sudo apt update && sudo apt upgrade
sudo dpkg --add-architecture i386
echo "APT::Architectures \"$(dpkg --print-architecture),$(dpkg --print-foreign-architectures | tr '\n' ',' | sed 's/,$//')\";" | sudo tee /etc/apt/apt.conf.d/99multilib
sudo apt update
xargs -a "$recPackgePath" sudo apt install -y -m
xargs -a "$optPackgePath" sudo apt purge -y -m 
sudo apt install -y steam:i386

echo "Setting exports... (varSetSani.sh)"
bash "$(find ~ -name varSetSani.sh | head -n 1)"

echo "Cleaning files and config..."

vulkan64=$(find /usr/lib/x86_64-linux-gnu -name "libvulkan_virtio.so" -o -name "libvulkan_venus.so" | head -n 1)
vulkan32=$(find /usr/lib/i386-linux-gnu -name "libvulkan_virtio.so" -o -name "libvulkan_venus.so" | head -n 1)
 
sudo rm -f /usr/share/vulkan/icd.d/virtio*
sudo rm -f /etc/vulkan/icd.d/virtio*

sudo mkdir -p /etc/vulkan/icd.d
cat <<EOF | sudo tee /etc/vulkan/icd.d/virtio_icd.x86_64.json
{
    "file_format_version": "1.0.0",
    "ICD": {
        "library_path": "$vulkan64",
        "api_version": "1.3.269"
    }
}
EOF

# Create the 32-bit JSON (Essential for Steam)
cat <<EOF | sudo tee /etc/vulkan/icd.d/virtio_icd.i686.json
{
    "file_format_version": "1.0.0",
    "ICD": {
        "library_path": "$vulkan32",
        "api_version": "1.3.269"
    }
}
EOF



#Creating the new files for vulkan and configging them for vulkan on 64 and 32
sudo cp /etc/vulkan/icd.d/virtio_icd.x86_64.json /usr/share/vulkan/icd.d/
sudo cp /etc/vulkan/icd.d/virtio_icd.i686.json /usr/share/vulkan/icd.d/

echo "Conducting backup measure..."
#Safety measure to ensure file exist in correct place

sudo mkdir -p /usr/share/vulkan/icd.d/
sudo mkdir -p /etc/vulkan/backup/
sudo mkdir -p /usr/share/vulkan/backup/

sudo cp /usr/share/vulkan/icd.d/virtio* /usr/share/vulkan/backup/
sudo cp /etc/vulkan/icd.d/virtio* /etc/vulkan/backup/

#configs and saves exports to muiple location like garcon
bash "$(find ~ -name varSetSani.sh | head -n 1)"

#Adds premissions and groups required.
sudo chmod 666 /dev/dri/renderD128 2>/dev/null
sudo chmod 666 /dev/dri/*
sudo usermod -aG video,render $USER
echo "Add video and render groups"
sudo chmod 666 /dev/dri/card0 2>/dev/null

sudo apt update

sudo ldconfig

echo "Running extensive test..."

if glxinfo | grep -iq "virtio"; then
    echo "[PASS] Virtio-gpu is active."
else
    echo "[FAIL] Hardware acceleration not detected. Check your 'Baguette' flags and relaunch in crosh."
fi
if ls /usr/share/vulkan/icd.d/ 2>/dev/null | grep -q "virtio"; then
    echo "[PASS] Vulkan was downloaded correctly and has the json file in the correct place."
else
    echo "[FAIL] Vulkan was not downloaded correctly or the json file is in a incorrect place."
fi
if dpkg --print-foreign-architectures | grep -q "i386"; then
    echo "[PASS] I386 has been correctly added."
else
    echo "[FAIL] i386 was not correctly added."
fi
if ! grep -q "trixie" /etc/os-release; then
    echo "[PASS] Your system is running Debian Trixie."
else 
    echo "[FAIL] Your system is running $(lsb_release -d | cut -f2)."
fi
if command -v vulkaninfo >/dev/null; then
    ACTIVE_GPU=$(vulkaninfo --summary | grep "deviceName" | head -n 1)
    echo "Active Vulkan Device: $ACTIVE_GPU"
    if [[ ! $ACTIVE_GPU == *"Venus"* ]]; then
        echo "[FAIL] Vulkan is present but using software rendering/wrong driver!"
        testPassed=false
    fi
fi
if dpkg -l | grep -q "pipewire:i386"; then
    echo "[PASS] 32-bit Audio drivers installed."
else
    echo "[WARN] 32-bit Audio (pipewire:i386) missing. Games may be silent."
fi
if [ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ] || [ -S "/run/user/$(id -u)/wayland-0" ]; then
    echo "[PASS] Wayland display socket is active."
else
    echo "[WARN] Wayland socket not detected. GUI apps might fail to open."
fi
if [ -f "/usr/lib/i386-linux-gnu/libvulkan.so.1" ]; then
    echo "[PASS] 32-bit Vulkan Loader found."
else
    echo "[FAIL] 32-bit Vulkan Loader MISSING."
fi
if [ -L "$HOME/.steam/bin32" ] || [ -d "$HOME/.steam/steam/ubuntu12_32" ]; then
    echo "[PASS] Steam directory structure exists."
else
    echo "[INFO] Steam has not been initialized yet and must be install again."
fi
if [ -d "/dev/shm" ]; then
    echo "[PASS] /dev/shm is accessible."
else
    echo "[FAIL] /dev/shm is missing."
fi
FREE_SPACE=$(df -h / | tail -1 | awk '{print $4}' | sed 's/G//')
if (( $(echo "$FREE_SPACE > 5" | bc -l) )); then
    echo "[PASS] Sufficient disk space ($FREE_SPACE GB free)."
else
    echo "[WARN] Low disk space ($FREE_SPACE GB)."
fi
if command -v xwayland >/dev/null; then
    echo "[PASS] XWayland is installed."
else
    echo "[FAIL] XWayland missing."
fi
MESA64=$(dpkg -s libgl1-mesa-dri | grep Version | cut -d' ' -f2)
MESA32=$(dpkg -s libgl1-mesa-dri:i386 | grep Version | cut -d' ' -f2)

if [ "$MESA64" == "$MESA32" ]; then
    echo "[PASS] Mesa versions are synchronized ($MESA64)."
else
    echo "[FAIL] Mesa versions are different between 64 and 32, 64bit: $MESA64 vs 32bit: $MESA32"
    echo "       Run 'sudo apt install libgl1-mesa-dri libgl1-mesa-dri:i386' to sync."
fi

echo "WARNING: Terminal will close in 5 seconds to restart the service bridge."
echo "RE-EXECUTE this script once you re-open the terminal."

sleep 5

systemctl --user daemon-reload
systemctl --user restart cros-garcon.service

