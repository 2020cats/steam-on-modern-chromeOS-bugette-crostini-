#!/bin/bash
[[ -x "$0" ]] || chmod +x "$0" 2>/dev/null

#generate the dashes with the specfic method
getCols() {
    # 1. Try tput
    if command -v tput >/dev/null 2>&1; then
        tput cols
    # 2. Try stty
    elif command -v stty >/dev/null 2>&1; then
        stty size | awk '{print $2}'
    # 3. Fallback to a standard 80 characters
    else
        echo 80
    fi
}

#generate the dashes with the specfic method
drawLine() {
    local cols=$(getCols)
    cols=${cols:-80}
    printf '%*s\n' "$cols" '' | tr ' ' -
}

#Trixie check
if ! grep -q "trixie" /etc/os-release; then
    drawLine
    echo "ERROR: This script is designed for Debian Trixie."
    echo "Your system version appears to be different. Aborting to prevent package conflicts."
    echo "Please check your flags and reinstall the linux environment."
    exit 1
fi

#Set ups the save file
shopt -s nullglob
stateFile="$HOME/.steam_install_state"

saveState() {
    echo "$1" > "$stateFile"
}

currentState=$(cat "$stateFile" 2>/dev/null || echo "START")

#The script BEFORE it crashes
if [[ "$currentState" == "START" ]]; then
    echo "Please enable flags if you have not yet, then you must reinstall the LDE"
    drawLine
    echo "1. Crostini without LXD containers (#crostini-containerless) --> enable"
    echo "2. Crostini GPU Support (#crostini-gpu-support) --> enable"
    echo "3. Debian version for new Crostini containers --> default"
    drawLine
    echo "If you can:"
    echo "4. Vulkan (#enable-vulkan) --> enable"
    drawLine

    sleep 5

    echo "Install started..."

    #get read for install 
    sudo apt update && sudo apt upgrade
    sudo dpkg --add-architecture i386
    sudo apt update
    sudo apt install -y -m mesa-utils xwayland libva-wayland2 libegl-mesa0 libegl1-mesa-dev mesa-vulkan-drivers mesa-vulkan-drivers:i386 vulkan-tools libvulkan1 libvulkan1:i386 libvulkan-dev libvulkan-dev:i386 libwayland-client0 libwayland-client0:i386 libwayland-server0 libwayland-server0:i386  libwayland-egl1:i386 libwayland-cursor0:i386 xdg-desktop-portal-gtk

    
    echo "Cleaning files and config"

    vulkan64=$(find /usr/lib/x86_64-linux-gnu -name "libvulkan_virtio.so" | head -n 1)
    vulkan32=$(find /usr/lib/i386-linux-gnu -name "libvulkan_virtio.so" | head -n 1)
     
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

    # 4. Create the 32-bit JSON (Essential for Steam)
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
    
    sudo mkdir -p /usr/share/vulkan/backup/
    cp /usr/share/vulkan/icd.d/virtio* /usr/share/vulkan/backup/
    
    sudo mkdir -p /etc/vulkan/backup/
    cp /etc/vulkan/icd.d/virtio* /etc/vulkan/backup/
    
    mkdir -p ~/.config/systemd/user/cros-garcon.service.d/
    rm -f ~/.config/systemd/user/cros-garcon.service.d/*.conf
    vulkanConfHome="$HOME/.config/systemd/user/cros-garcon.service.d/vulkan.conf"
    touch "$vulkanConfHome"

    #clears the the file from old or conflig exports
    vars=("VK_ICD_FILENAMES" "WAYLAND_DISPLAY" "XDG_RUNTIME_DIR" "XDG_SESSION_TYPE" "GDK_BACKEND" "QT_QPA_PLATFORM" "VK_INSTANCE_LAYERS" "DISPLAY")

    for var in "${vars[@]}"; do
        sudo sed -i "/^$var=/d" /etc/environment
        sed -i "/export $var=/d" ~/.bashrc
        sed -i "/Environment=\"$var=/d" "$vulkanConfHome"
    done

    #Find file for vulkan and adds the export to files 
    
    vulkanCompiledPath=""
    for file in /usr/share/vulkan/icd.d/virtio*; do  
        if [ -z "$vulkanCompiledPath" ]; then
            vulkanCompiledPath="$file"
        else
            vulkanCompiledPath+=":$file"
        fi
    done
    
    #Adds exports files
    echo "VK_ICD_FILENAMES=$vulkanCompiledPath" | sudo tee -a /etc/environment > /dev/null
    echo "VK_INSTANCE_LAYERS=VK_LAYER_MESA_device_select" | sudo tee -a /etc/environment > /dev/null        
    
    {
        echo "export VK_ICD_FILENAMES=$vulkanCompiledPath"
        echo "export XDG_RUNTIME_DIR=/run/user/\$(id -u)"
        echo "export VK_INSTANCE_LAYERS=VK_LAYER_MESA_device_select"
        echo "export WAYLAND_DISPLAY=wayland-0"
        echo "export XDG_SESSION_TYPE=wayland"
        echo "export GDK_BACKEND=wayland,x11"
        echo "export QT_QPA_PLATFORM=wayland"
        echo "export XDG_RUNTIME_DIR=\"/run/user/\$(id -u)\""
        echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu"
        echo "export MESA_VK_DEVICE_SELECT=virtio"
        echo "export VK_USE_PLATFORM_XLIB_KHR=1"
        echo "export VK_USE_PLATFORM_XCB_KHR=1"
        echo "export VK_USE_PLATFORM_WAYLAND_KHR=1"
        echo "export STEAM_RUNTIME_PREFER_HOST_LIBRARIES=1"
    } >> ~/.bashrc

    export VK_ICD_FILENAMES=$vulkanCompiledPath
    export WAYLAND_DISPLAY=wayland-0
    export XDG_SESSION_TYPE=wayland
    export GDK_BACKEND=wayland,x11
    export QT_QPA_PLATFORM=wayland
    export MESA_VK_DEVICE_SELECT=virtio
    export VK_USE_PLATFORM_XLIB_KHR=1
    export VK_USE_PLATFORM_XCB_KHR=1
    export VK_USE_PLATFORM_WAYLAND_KHR=1

    cat <<EOF > ~/.config/systemd/user/cros-garcon.service.d/vulkan.conf
[Service]
Environment="VK_ICD_FILENAMES=$vulkanCompiledPath"
Environment="VK_INSTANCE_LAYERS=VK_LAYER_MESA_device_select"
Environment="WAYLAND_DISPLAY=wayland-0"
Environment="DISPLAY=:0"
Environment="XDG_RUNTIME_DIR=/run/user/%U"
Environment="XDG_SESSION_TYPE=wayland"
Environment="GDK_BACKEND=wayland,x11"
Environment="QT_QPA_PLATFORM=wayland"
Environment="VK_USE_PLATFORM_XCB_KHR=1"
Environment="VK_USE_PLATFORM_XLIB_KHR=1"
Environment="VK_USE_PLATFORM_WAYLAND_KHR=1"
Environment="MESA_VK_DEVICE_SELECT=virtio"
Environment="STEAM_RUNTIME_PREFER_HOST_LIBRARIES=1"
EOF

    if ! grep -q "\[Service\]" "$vulkanConfHome"; then
        echo "[Service]" >> "$vulkanConfHome"
    fi
    

    #Adds premissions and groups required.
    sudo chmod 666 /dev/dri/renderD128 2>/dev/null
    chmod 666 /dev/dri/*
    sudo usermod -aG video,render $USER
    echo "Add video and render groups"
    sudo chmod 666 /dev/dri/card0 2>/dev/null

    sudo apt update

    echo "WARNING: Terminal will close in 5 seconds to restart the service bridge."
    echo "RE-EXECUTE this script once you re-open the terminal."  

    saveState "SETUP_DONE"

    sleep 5

    #resets the garcon

    systemctl --user daemon-reload
    systemctl --user restart cros-garcon.service

    exit
fi

if [[ "$currentState" == "SETUP_DONE" ]]; then
    rm -f "$stateFile"
    
    drawLine
    echo "Install continuing..."

    sleep 3
    
    if [ -f /etc/apt/sources.list.d/debian.sources ]; then
        sudo sed -i 's/Components: main/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources
    else
        sudo sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
        
    fi

    sudo dpkg --add-architecture i386
    sudo apt update

    echo "install Steam and Dependencies..."

    sudo apt install -y adwaita-icon-theme-legacy oss-compat lm-sensors:i386 pipewire:i386 pocl-opencl-icd:i386 mesa-opencl-icd:i386 steam:i386

    echo "Installing suggested packages..."

    sudo apt install -m -y gvfs gvfs:i386 low-memory-monitor:i386 speex speex:i386 gnutls-bin:i386 krb5-doc krb5-user:i386 libgcrypt20:i386 liblz4-1:i386 libvisual-0.4-plugins jackd2 jackd2:i386 liblcms2-utils liblcms2-utils:i386
    sudo apt install -m -y gtk2-engines-pixbuf:i386 libgtk2.0-0t64:i386 colord colord:i386 cryptsetup-bin:i386 opus-tools:i386 pulseaudio:i386 librsvg2-bin librsvg2-bin:i386 accountsservice evince xdg-desktop-portal-gnome xfonts-cyrillic
    
    read -p "Do you want to download the recommended enhancement packages? [Y/n] " userWantDownloadYN
    if [[ -z "$userWantDownloadYN" || "$userWantDownloadYN" =~ ^[Yy]$ ]]; then
        echo "Downloading recommended enhancement packages."
        sudo apt install -y -m mangohud protonup-qt goverlay gamemode
        sudo apt update
    else
        echo "Skipped recommended enhancement packages."
    fi

    echo "Oppimizing for chromeOS settings and preferences"

    export XDG_SESSION_TYPE=wayland
    export GDK_BACKEND=wayland,x11
    export WAYLAND_DISPLAY=wayland-0
    export STEAM_RUNTIME_PREFER_HOST_LIBRARIES=1
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu
    
    testPassed=true

    #self-tests 
    if [[ "$1" == "--ignore-tests" ]]; then
        echo "Skipping self-tests as requested by flag..."
    else
        if glxinfo | grep -iq "virtio"; then
            echo "Conducting self test..."
            echo "Virtio-gpu is active."
        else
            echo "Error: Hardware acceleration not detected. Check your 'Baguette' flags and relaunch in crosh."
            testPassed=false
        fi
    
        if dpkg --print-foreign-architectures | grep -q "i386"; then
            echo "i386 is enabled."
        else
            echo "Error: i386 is missing. Steam will not launch"
            testPassed=false
        fi
    
        if ls /usr/share/vulkan/icd.d/ 2>/dev/null | grep -q "virtio"; then
            echo "Vulkan was downloaded correctly and has the json file in the correct place."
        else
            echo "Error: Vulkan was not downloaded correctly or the json file is in a incorrect place."
            testPassed=false
        fi
    fi

    if [ "$testPassed" = true ]; then
        drawLine
        echo "Setup Complete."
        echo "Steam will start downloading in 5 secs"
        drawLine

        sleep 5

        steam
    else
        drawLine
        echo "Self test failed..."
        echo "1. Check flags"
        echo "2. Remove and then reinstall the linux enviroment"
        echo "3. Execute VulkanSteamInstaller.sh again"
        echo "Or paste this: bash $(find ~ -name VulkanSteamInstaller.sh | head -n 1)"
        drawLine
    fi
fi
