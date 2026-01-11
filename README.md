# WARNING: This does not work all the way yet!!!!!!

# Installing steam on modern chromeOS crostini using vulkan (2026)
THis is a process intended to install steam and vulkan for crostini. You can either follow the instructions or use the installer.
Please note: This was made at the very start of 2026, so some things may change or break. Also this may take a very long time depending on your internet speed. (Don't do this on slow wifi D:) 

# Prep

You must enable the following chrome flags BEFORE you create the linux enviroment for this to work. You also cannot use 
1. Crostini without LXD containers (#crostini-containerless) --> enable
2. Crostini GPU Support (#crostini-gpu-support) --> enable
3. Debian version for new Crostini containers --> defaut (I don't know if this matters, but it seamed to cause problems)

   And if you can: (may help preformance in steam client)
5. Vulkan (#enable-vulkan) --> enable
6. Default ANGLE Vulkan (#default-angle-vulkan) --> enable 
7. ANGLE From Vulkan (#vulkan-from-angle) --> enable (


Now you can go into the chromeOS settings and setup the Linux development environment. I recomend no less then 20GB to ensure you have the space for steam and then some.

# Setup using Installer (Recommended)
Start the VM using Crosh (Alt + Ctrl + T). *vmc Launch will give an error.
```
vmc stop termina
vmc launch termina --gpu-support --enable-vulkan
vsh termina penguin
```

Run the VulkanSteamInstaller.sh file and follow its instructions. *It will crash the seshion, so you will need to exicute the file twice.
```
bash "$(find ~ -name VulkanSteamInstaller.sh | head -n 1)"
```

Test using vulkaninfo --summary or vkcube.
If you get errors about wayland you can download westion.
```
sudo apt install weston
weston --vk-renderer
```

**Otherwise...**

# Install Vulkan without Installer

## Warning: This is a pain and most likely not up to date. 

Inside penguin in crosh you now must make sure your system is up to date. Add the i386 architecture and install: xwayland, libva-wayland2, libegl-mesa0, libegl1-mesa-dev, mesa-vulkan-drivers, mesa-vulkan-drivers:i386, vulkan-tools, mesa-utils, libvulkan1, libvulkan1:i386, libvulkan-dev, libvulkan-dev:i386, libwayland-client0, libwayland-client0:i386, libwayland-server0, libwayland-server0:i386, libwayland-egl1:i386, libwayland-cursor0:i386, xdg-desktop-portal-gtk. You can try vmc start but it doesn't seem to work with, vulkan.
```
#Enters crostini from crosh. You WILL get an error after launch.
vmc stop termina
vmc launch termina --gpu-support --enable-vulkan
vsh termina penguin

sudo dpkg --add-architecture i386
sudo apt update && sudo apt upgrade

sudo apt install -y -m mesa-utils xwayland libva-wayland2 libegl-mesa0 libegl1-mesa-dev mesa-vulkan-drivers mesa-vulkan-drivers:i386 vulkan-tools libvulkan1 libvulkan1:i386 libvulkan-dev libvulkan-dev:i386 libwayland-client0 libwayland-client0:i386 libwayland-server0 libwayland-server0:i386 libwayland-egl1:i386 libwayland-cursor0:i386 xdg-desktop-portal-gtk
```

To make ensure the system does not change back, you must find the name of virtio json file. Then, enter the /etc/environment and set VK_ICD_FILENAMES to that file path

Then enter the crosh (Alt + Ctrl + T) stop termina and launch it with --enable-gpu --enable-vulkan. You then need to find the file path to your virtio json file. *If you don't see it, you didn't enale gpu correctly.
Or paste this this:
  ```
vmc stop termina
vmc launch termina --enable-gpu --enable-vulkan
#if using crosh: vsh termina penguin
  
ls /usr/share/vulkan/icd.d/
sudo nano /etc/environment
    #delete any Vk, wayland, or XDG values and enter: 
    VK_ICD_FILENAMES=<same file path as before>
    VK_INSTANCE_LAYERS=VK_LAYER_MESA_device_select
    WAYLAND_DISPLAY=wayland-0
    XDG_RUNTIME_DIR=/run/user/$(id -u)
    XDG_SESSION_TYPE=wayland
    QT_QPA_PLATFORM=wayland

nano ~/.bashrc
    #paste this at the end to be safe
    export VK_ICD_FILENAMES=<same file path as before>
    export VK_INSTANCE_LAYERS=VK_LAYER_MESA_device_select
    export WAYLAND_DISPLAY=wayland-0
    export XDG_RUNTIME_DIR=/run/user/$(id -u)
    export XDG_SESSION_TYPE=wayland
    export QT_QPA_PLATFORM=wayland
```

You also may need to update the cros garcon
  ```
systemctl --user edit cros-garcon.service

#add this:
[Service]
Environment="VK_ICD_FILENAMES=<save file path from before>"
Environment="VK_INSTANCE_LAYERS=VK_LAYER_MESA_device_select"
Environment="XDG_RUNTIME_DIR=/run/user/%U"
Environment="WAYLAND_DISPLAY=wayland-0"
Environment="DISPLAY=:0"
Environment="XDG_SESSION_TYPE=wayland"
Environment="QT_QPA_PLATFORM=wayland"
```

You also need to add the "video" and "render" groups for vulkan to be able to commuticate with the gpu.
  ```
sudo /usr/sbin/usermod -aG video,render $USER
  ```

Reload and restart the garcon: (This will crash terminal or crosh)
```
systemctl --user daemon-reload
systemctl --user restart cros-garcon.service
 ```
Or use the 'safe' mode:
```
systemctl --user import-environment
```
   
Now you must verify that your gpu is using venus (the penguin gpu converter) and not llvmpipe. To test this you can use vkcube. Another way to be sure is too run vulkan info (MESA_VK_DEVICE_SELECT=list vulkaninfo).
  
  ```
vulkaninfo --summary
  ```

You can also try to use vkcube. If you see a spinning blue box, Vulkan is working. You may need to use wayland.
  ```
vkcube
```

If you get errors about wayland you can download westion.
```
sudo apt install weston
weston --vk-renderer
#or
weston --backend=wayland --vk-renderer
```
# Steam download without Installer

Restart the VM using Crosh (Alt + Ctrl + T). Launch will give an error.
```
vmc stop termina
vmc launch termina --gpu-support --enable-vulkan
vsh termina penguin
```

You need to free your sources then update: 
```
sudo sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
sudo dpkg --add-architecture i386
sudo apt update
```

Now that you have the intergrated gpu and vulkan working, you can install steam. After it installed you can just type 'steam' to get it to setup.

 ```
sudo apt upgrade 
sudo apt install steam:i386

steam
```

Then run to make sure all of the suggest depencies are downloaded: 
```
sudo apt install adwaita-icon-theme-legacy oss-compat lm-sensors:i386 pipewire:i386 pocl-opencl-icd:i386  mesa-opencl-icd:i386  rocm-opencl-icd 5.7.1-6+deb13u1 pocl-opencl-icd 6.0-6 mesa-opencl-icd
```
Suggested but may not all work:
```
sudo apt install -m -y gvfs gvfs:i386 low-memory-monitor:i386 speex speex:i386 gnutls-bin:i386 krb5-doc krb5-user:i386 libgcrypt20:i386 liblz4-1:i386 libvisual-0.4-plugins jackd2 jackd2:i386 liblcms2-utils liblcms2-utils:i386
sudo apt install -m -y gtk2-engines-pixbuf:i386 libgtk2.0-0t64:i386 colord colord:i386 cryptsetup-bin:i386 opus-tools:i386 pulseaudio:i386 librsvg2-bin librsvg2-bin:i386 accountsservice evince xdg-desktop-portal-gnome xfonts-cyrillic
```

# Finishing

You now may want to update your system (sudo apt update) and must restart your VM using VMC in Crosh (Alt + Ctrl + T) and enable with gpu and vulkan support. Launch will give a error.
```
vmc stop termina
vmc launch termina --gpu-support --enable-vulkan
vsh termina penguin

export VK_ICD_FILENAMES=<file path from before>
export DISPLAY=:0
export WAYLAND_DISPLAY=wayland-0
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export XDG_SESSION_TYPE=wayland
export QT_QPA_PLATFORM=wayland
```
# Troubleshooting

Check garcon (journalctl --user -u cros-garcon)
Check for gpu support (ls -l /dev/dri), search for card0 and renderD128
If it says it cannot download a package or depecency try: (Make sure it updates)
```
sudo sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
sudo dpkg --add-architecture i386
sudo apt update
```
