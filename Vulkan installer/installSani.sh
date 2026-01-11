#!/bin/bash
[[ -x "$0" ]] || chmod +x "$0" 2>/dev/null

recPackgePath=$(find "$HOME/Vulkan installer/etc/" -name "recommend.txt" | head -n 1)
optPackgePath=$(find "$HOME/Vulkan installer/etc/" -name "optional.txt" | head -n 1)

sudo apt update && sudo apt upgrade
sudo dpkg --add-architecture i386
echo "APT::Architectures \"$(dpkg --print-architecture),$(dpkg --print-foreign-architectures | tr '\n' ',' | sed 's/,$//')\";" | sudo tee /etc/apt/apt.conf.d/99multilib
sudo apt update
xargs -a "$recPackgePath" sudo apt install -y -m
xargs -a "$optPackgePath" sudo apt purge -y -m 
sudo apt install -y steam:i386

bash "$(find ~ -name varSetSani.sh | head -n 1)"

echo "Cleaning files and config"

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

echo "WARNING: Terminal will close in 5 seconds to restart the service bridge."
echo "RE-EXECUTE this script once you re-open the terminal."

echo "Running extensive test..."

if glxinfo | grep -iq "virtio"; then
    echo "Conducting self test..."
    echo "Virtio-gpu is active."
else
    echo "Error: Hardware acceleration not detected. Check your 'Baguette' flags and relaunch in crosh."
fi
if ls /usr/share/vulkan/icd.d/ 2>/dev/null | grep -q "virtio"; then
    echo "Vulkan was downloaded correctly and has the json file in the correct place."
else
    echo "Error: Vulkan was not downloaded correctly or the json file is in a incorrect place."
fi
if dpkg --print-foreign-architectures | grep -q "i386"; then
    echo "I386 has been correctly added."
else
    echo "Error: i386 was not correctly added."
fi
if ! grep -q "trixie" /etc/os-release; then
    echo "Your system is running Debian Trixie."
else 
    echo "Your system is running Debian Trixie."
fi
if command -v vulkaninfo >/dev/null; then
    ACTIVE_GPU=$(vulkaninfo --summary | grep "deviceName" | head -n 1)
    echo "Active Vulkan Device: $ACTIVE_GPU"
    if [[ ! $ACTIVE_GPU == *"Venus"* ]]; then
        echo "ERROR: Vulkan is present but using software rendering/wrong driver!"
        testPassed=false
    fi
fi
