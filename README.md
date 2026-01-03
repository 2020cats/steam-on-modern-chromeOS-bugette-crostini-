# installing steam on modern chromeOS penguin using vulkan
I went through the process of downloading steam on chromeOS penguin using the new baguette version so you don't have to...
Please note: This was made at the very start of 2026, so some things may change or break. Also this may take a very long time 


You must enable the following chrome flags BEFORE you create the linux enviroment for this to work. You also cannot use 
1. Crostini without LXD containers (#crostini-containerless) --> enable
2. Crostini GPU Support (#crostini-gpu-support) --> enable
3. Debian version for new Crostini containers --> defaut (I don't know if this matters, but it seamed to cause problems)
And if you can:
4. Vulkan (#enable-vulkan) --> enable
5. Default ANGLE Vulkan (#default-angle-vulkan) --> enable (may or may not help preformance in steam client)
6. ANGLE From Vulkan (#vulkan-from-angle) --> enable (may or may not help preformance in steam client)


Now you can go into the chromeOS settings and setup the Linux development environment. I recomend no less then 20GB to ensure you have the space for steam and then some.

Inside penguin in crosh or the terminal app, you now must make sure your system is up to date. Add the i386 architecture and install: mesa-vulkan-drivers, mesa-vulkan-drivers:i386, vulkan-tools, libvulkan1, libvulkan1:i386, libvulkan-dev, and libvulkan-dev:i386. You can try vmc start but it doesn't seem to work with vulkan.

  #if using crosh
  vsh termina penguin
  
  sudo apt update && sudo apt upgrade
  sudo dpkg --add-architecture i386
  sudo apt install mesa-vulkan-drivers mesa-vulkan-drivers:i386 vulkan-tools libvulkan1 libvulkan1:i386 libvulkan-    dev libvulkan-dev:i386 -y

To make ensure the system does not change back, you must find the name of virtio json file. Then, enter the /etc/environment and set VK_ICD_FILENAMES to that file path

Then enter the crosh (Alt + Ctrl + T) stop termina and launch it with --enable-gpu --enable-vulkan 
Or paste this this:
  vmc stop termina
  vmc launch termina --enable-gpu --enable-vulkan
  
  ls /usr/share/vulkan/icd.d/
  sudo nano /etc/environment
    #delete any VK values and enter 
    VK_ICD_FILENAMES=<your file path probably /usr/share/vulkan/icd.d/virtio_icd.json>
    VK_INSTANCE_LAYERS=VK_LAYER_MESA_device_select

  nano ~/.bashrc
    #paste this at the end to be safe 
    export VK_ICD_FILENAMES=<same file path as before>

You also need to add the "video" and "render" groups for vulkan to be able to commuticate with the gpu.
  sudo /usr/sbin/usermod -aG video,render $USER

You also may need to update the cros garcon
  systemctl --user edit cros-garcon.service
    #add this:
      [Service]
      VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/virtio_icd.json
      

Now you must verify that your gpu is using venus (the penguin gpu converter) and not llvmpipe. To test this you can use vkcube. Another way to be sure is too run vulkan info (MESA_VK_DEVICE_SELECT=list vulkaninfo)
  vulkaninfo --summary
  vkcube



Now that you have the intergrated gpu and vulkan working, you can install steam. You probelly want to do it in the terminal, because it will also install the depecencies needed.

If in terminal:
  sudo apt upgrade 
  udo apt install steam:i386

You are going to see a app called "install steam" or something like that, and launch it. You shoud be able to lanuch the app with an otoption to install steam. For me it seem to go wrong, but it may not for you. You should try to luanch steam in the teminal using "steam". If it said that steam is allready running kill the process (pkill -9 -f steam), then try "steam" again. For me, steam then started downloading itself.

Then run to make sure all of the suggest depencies are downloaded: 
  sudo apt install adwaita-icon-theme-legacy oss-compat lm-sensors:i386 pipewire:i386 pocl-opencl-icd:i386  mesa-opencl-icd:i386  rocm-opencl-icd 5.7.1-6+deb13u1 pocl-opencl-icd 6.0-6 mesa-opencl-icd 25.0.7-2
  
Suggested but may not work:
  gvfs gvfs:i386 low-memory-monitor:i386 speex speex:i386 gnutls-bin:i386 krb5-doc:i386 krb5-user:i386 libgcrypt20:i386 liblz4-1:i386 libvisual-0.4-plugins jackd2 jackd2:i386 liblcms2-utils liblcms2-utils:i386 gtk2-engines-pixbuf:i386 libgtk2.0-0t64:i386 colord colord:i386 cryptsetup-bin:i386 opus-tools:i386 pulseaudio:i386 librsvg2-bin          librsvg2-bin:i386 accountsservice evince xdg-desktop-portal-gnome xfonts-cyrillic -y


