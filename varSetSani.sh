    #clears the the file from old or conflig exports
    vars=("VK_ICD_FILENAMES" "VK_INSTANCE_LAYERS" "WAYLAND_DISPLAY" "XDG_RUNTIME_DIR" "XDG_SESSION_TYPE" "GDK_BACKEND" "QT_QPA_PLATFORM" "SDL_VIDEODRIVER" "DISABLE_WAYLAND_X11_INTEROP" "MESA_VK_DEVICE_SELECT" "STEAM_RUNTIME_PREFER_HOST_LIBRARIES")
    echo "Cleaning up old environment configurations..."
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
    
    #Writing to /etc/environment
    {
        echo "VK_ICD_FILENAMES=$vulkanCompiledPath"
        echo "VK_INSTANCE_LAYERS=VK_LAYER_MESA_device_select"
        echo "XDG_SESSION_TYPE=wayland"
        echo "WAYLAND_DISPLAY=wayland-0"
        echo "XDG_RUNTIME_DIR=/run/user/$(id -u)"
        echo "GDK_BACKEND=wayland,x11"
        echo "QT_QPA_PLATFORM=wayland"
        echo "SDL_VIDEODRIVER=wayland"
        echo "DISABLE_WAYLAND_X11_INTEROP=1"
        echo "MESA_VK_DEVICE_SELECT=virtio"
    } | sudo tee -a /etc/environment > /dev/null

    # Writing to ~/.bashrc
    {
        echo "export VK_ICD_FILENAMES=$vulkanCompiledPath"
        echo "export WAYLAND_DISPLAY=wayland-0"
        echo "export XDG_RUNTIME_DIR=/run/user/\$(id -u)"
        echo "export XDG_SESSION_TYPE=wayland"
        echo "export GDK_BACKEND=wayland,x11"
        echo "export QT_QPA_PLATFORM=wayland"
        echo "export SDL_VIDEODRIVER=wayland"
        echo "export DISABLE_WAYLAND_X11_INTEROP=1"
        echo "export MESA_VK_DEVICE_SELECT=virtio"
        echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu"
        echo "export STEAM_RUNTIME_PREFER_HOST_LIBRARIES=1"
    } >> ~/.bashrc

    # --- Applying to CURRENT Session ---
    export VK_ICD_FILENAMES=$vulkanCompiledPath
    export WAYLAND_DISPLAY=wayland-0
    export XDG_RUNTIME_DIR=/run/user/$(id -u)
    export SDL_VIDEODRIVER=wayland
    export DISABLE_WAYLAND_X11_INTEROP=1

    # --- Updating the Garcon Service (ChromeOS UI Bridge) ---
    mkdir -p ~/.config/systemd/user/cros-garcon.service.d/
    cat <<EOF > ~/.config/systemd/user/cros-garcon.service.d/vulkan.conf
[Service]
Environment="VK_ICD_FILENAMES=$vulkanCompiledPath"
Environment="WAYLAND_DISPLAY=wayland-0"
Environment="XDG_RUNTIME_DIR=/run/user/%U"
Environment="XDG_SESSION_TYPE=wayland"
Environment="GDK_BACKEND=wayland,x11"
Environment="QT_QPA_PLATFORM=wayland"
Environment="SDL_VIDEODRIVER=wayland"
Environment="DISABLE_WAYLAND_X11_INTEROP=1"
Environment="MESA_VK_DEVICE_SELECT=virtio"
Environment="STEAM_RUNTIME_PREFER_HOST_LIBRARIES=1"
EOF

systemctl --user daemon-reload
systemctl --user import-environment WAYLAND_DISPLAY XDG_RUNTIME_DIR SDL_VIDEODRIVER DISABLE_WAYLAND_X11_INTEROP
