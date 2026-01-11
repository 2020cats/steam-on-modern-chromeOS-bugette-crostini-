#!/bin/bash
[[ -x "$0" ]] || chmod +x "$0" 2>/dev/null

recPackgePath=$(find "$HOME/Vulkan installer/etc/" -name "recommend.txt" | head -n 1)
optPackgePath=$(find "$HOME/Vulkan installer/etc/" -name "optional.txt" | head -n 1)

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
    xargs -a "$recPackgePath" sudo apt install -y -m 
    
    read -p "Do you want to download the recommended enhancement packages? [Y/n] " userWantDownloadYN
    if [[ -z "$userWantDownloadYN" || "$userWantDownloadYN" =~ ^[Yy]$ ]]; then
        echo "Downloading recommended enhancement packages."
        xargs -a "$optPackgePath" sudo apt install -y -m 
        sudo apt update
    else
        echo "Skipped recommended enhancement packages."
    fi

    
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

    saveState "SETUP_DONE"

    sleep 5

    #resets the garcon

    systemctl --user daemon-reload
    systemctl --user restart cros-garcon.service

    exit
fi

if [[ "$currentState" == "SETUP_DONE" ]]; then

    source "$HOME/.bashrc" 2>/dev/null
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

    echo "install Steam..."

    sudo apt install -y steam:i386

    echo "Installing suggested packages..."
    
    
    
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
        if ls /usr/share/vulkan/icd.d/ 2>/dev/null | grep -q "virtio"; then
            echo "Vulkan was downloaded correctly and has the json file in the correct place."
        else
            echo "Error: Vulkan was not downloaded correctly or the json file is in a incorrect place."
            testPassed=false
        fi
        if dpkg --print-foreign-architectures | grep -q "i386"; then
            echo "I386 has been correctly added."
        else
            echo "Error: i386 was not correctly added."
            testPassed=false
        fi
        if command -v vulkaninfo >/dev/null; then
            ACTIVE_GPU=$(vulkaninfo --summary | grep "deviceName" | head -n 1)
            echo "Active Vulkan Device: $ACTIVE_GPU"
            if [[ ! $ACTIVE_GPU == *"Venus"* ]]; then
                echo "ERROR: Vulkan is present but using software rendering/wrong driver!"
                testPassed=false
            fi
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
