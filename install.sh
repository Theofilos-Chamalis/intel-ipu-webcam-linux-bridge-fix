#!/bin/bash

# 1. ROOT CHECK: Prevent the user from running the whole script as sudo
if [ "$EUID" -eq 0 ]; then
  echo "❌ Please DO NOT run this script as root (do not use 'sudo ./install.sh')."
  echo "Run it normally as './install.sh'. It will ask for your sudo password when needed."
  exit 1
fi

echo "🚀 Starting Intel IPU Webcam Bridge Installer..."

# 2. Detect Distribution and Install Dependencies
if [ -f /etc/arch-release ]; then
    echo "📦 Detected Arch/Manjaro. Installing dependencies..."
    sudo pacman -S --needed v4l2loopback-dkms v4l2loopback-utils gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad libcamera libnotify
elif [ -f /etc/debian_version ]; then
    echo "📦 Detected Ubuntu/Debian. Installing dependencies..."
    sudo apt update
    sudo apt install -y v4l2loopback-dkms v4l2loopback-utils gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-libcamera libcamera-tools libnotify-bin
elif [ -f /etc/fedora-release ]; then
    echo "📦 Detected Fedora. Installing dependencies..."
    sudo dnf install -y v4l2loopback gstreamer1 gstreamer1-plugins-base gstreamer1-plugins-good gstreamer1-plugins-bad-free libcamera-tools libnotify
else
    echo "❌ Unsupported distribution. Please install v4l2loopback and gstreamer manually."
    exit 1
fi

# 3. Configure Kernel Module to load on boot
echo "⚙️ Configuring v4l2loopback kernel module..."
echo "v4l2loopback" | sudo tee /etc/modules-load.d/v4l2loopback.conf > /dev/null

# 4. Create the Systemd Service to initialize the virtual device on boot
# (Added ExecStartPre to prevent race conditions!)
echo "⚙️ Creating virtual device systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/virtual-webcam.service > /dev/null
[Unit]
Description=Create Virtual Webcam Device
After=multi-user.target

[Service]
Type=oneshot
ExecStartPre=/sbin/modprobe v4l2loopback
ExecStart=/usr/bin/v4l2loopback-ctl add -n "Virtual Hardware Camera" /dev/video35
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now virtual-webcam.service

# 5. Copy the toggle script to the user's local bin
# (Ensuring the source file actually exists first)
if [ ! -f "toggle-camera.sh" ]; then
    echo "❌ Error: 'toggle-camera.sh' not found in the current directory."
    echo "Please make sure you cloned the whole repository."
    exit 1
fi

echo "📂 Installing toggle script..."
mkdir -p "$HOME/.local/bin"
cp toggle-camera.sh "$HOME/.local/bin/intel-webcam-toggle.sh"
chmod +x "$HOME/.local/bin/intel-webcam-toggle.sh"

# 6. Create the Desktop Application Shortcut
echo "🖥️ Creating Desktop entry..."
mkdir -p "$HOME/.local/share/applications"
cat << EOF > "$HOME/.local/share/applications/intel-camera-toggle.desktop"
[Desktop Entry]
Version=1.0
Name=Hardware Camera Toggle
Comment=Turn the Intel hardware webcam on and off
Exec=sh -c "$HOME/.local/bin/intel-webcam-toggle.sh"
Icon=camera-web
Terminal=false
Type=Application
Categories=Utility;AudioVideo;
EOF

# Force desktop environment to update its application list
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo "✅ Installation Complete!"
echo "⚠️ IMPORTANT: Please REBOOT your computer now to ensure the kernel drivers load correctly."
