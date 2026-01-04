#!/bin/bash

drawLine() {
    printf '%*s\n' "$(tput cols)" '' | tr ' ' -
}


echo "Please enable flags if you have not yet, then you must reinstall the LDE"
drawLine
echo "1. Crostini without LXD containers (#crostini-containerless) --> enable"
echo "2. Crostini GPU Support (#crostini-gpu-support) --> enable"
echo "3. Debian version for new Crostini containers --> default"
drawLine
echo "If you can:"
echo "4. Vulkan (#enable-vulkan) --> enable"
drawLine

echo "Install started..."

sudo apt update && sudo apt upgrade
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install mesa-vulkan-drivers mesa-vulkan-drivers:i386 vulkan-tools libvulkan1 libvulkan1:i386 libvulkan-dev libvulkan-dev:i386 

mkdir -p ~/.config/systemd/user/cros-garcon.service.d/

for file in /usr/share/vulkan/icd.d/*; do

    filename=$(basename "$file")
    
    if [[ "$filename" == virtio* ]]; then
        newLine="VK_ICD_FILENAMES=$file"

        echo "Found file: $filename"
        
        sudo sed -i '/VK_ICD_FILENAMES=/d' /etc/environment
        echo "VK_ICD_FILENAMES=$file" | sudo tee -a /etc/environment > /dev/null

        sed -i "/VK_ICD_FILENAMES=/d" ~/.bashrc
        sed -i "/VK_INSTANCE_LAYERS=/d" ~/.bashrc
        echo "export VK_ICD_FILENAMES=$file" >> ~/.bashrc
        echo "export VK_INSTANCE_LAYERS=VK_LAYER_MESA_device_select" >> ~/.bashrc

         
        cat <<EOF > ~/.config/systemd/user/cros-garcon.service.d/vulkan.conf
[Service]
Environment="VK_ICD_FILENAMES=$file"
Environment="VK_INSTANCE_LAYERS=VK_LAYER_MESA_device_select"
EOF
        break 
    fi
done

sudo sed -i "/VK_INSTANCE_LAYERS=/d" /etc/environment
echo "VK_INSTANCE_LAYERS=VK_LAYER_MESA_device_select" | sudo tee -a /etc/environment > /dev/null

sudo /usr/sbin/usermod -aG video,render $USER
echo "Add video and render groups"

systemctl --user daemon-reload
systemctl --user restart cros-garcon.service

echo "install Steam and Dependencies..."

sudo apt install adwaita-icon-theme-legacy oss-compat lm-sensors:i386 pipewire:i386 pocl-opencl-icd:i386 mesa-opencl-icd:i386 steam:i386

echo "Installing suggested packages..."

sudo apt install -m -y gvfs gvfs:i386 low-memory-monitor:i386 speex speex:i386 gnutls-bin:i386 krb5-doc:i386 krb5-user:i386 libgcrypt20:i386 liblz4-1:i386 libvisual-0.4-plugins jackd2 jackd2:i386 liblcms2-utils liblcms2-utils:i386 gtk2-engines-pixbuf:i386 libgtk2.0-0t64:i386 colord colord:i386 cryptsetup-bin:i386 opus-tools:i386 pulseaudio:i386 librsvg2-bin librsvg2-bin:i386 accountsservice evince xdg-desktop-portal-gnome xfonts-cyrillic


drawLine
echo "Setup Complete."
echo "1. Look for 'Install Steam' in your app drawer and launch it."
echo "2. If it hangs, run 'pkill -9 -f steam' and then type 'steam' in this terminal."
drawLine
