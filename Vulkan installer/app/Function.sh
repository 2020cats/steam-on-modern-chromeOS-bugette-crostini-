if ! command -v python3 >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y python3
  sudo apt install python3-tk
fi
sudo update-desktop-database

python3 ~/Vulkan installer/app/appUI.py
