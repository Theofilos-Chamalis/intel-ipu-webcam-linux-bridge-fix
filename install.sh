#!/bin/bash

echo "🚀 Starting Intel IPU Webcam Bridge Installer..."

# 1. Detect Distribution and Install Dependencies
if [ -f /etc/arch-release ]; then
    echo "📦 Detected Arch/Manjaro. Installing dependencies..."
    sudo pacman -S --needed v4l2loopback-dkms v4l2loopback-utils gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad libcamera libnotify
elif [ -f /etc/debian_version ]; then
    echo "📦 Detected Ubuntu/Debian. Installing dependencies..."
    sudo apt update
    sudo apt install -y v4l2loopback-dkms v4l2loopback-utils gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad libcamera-tools libnotify-bin
elif [ -f /etc/fedora-release ]; then
    echo "📦 Detected Fedora. Installing dependencies..."
    sudo dnf install -y v4l2loopback gstreamer1 gstreamer1-plugins-base gstreamer1-plugins-good gstreamer1-plugins-bad-free libcamera-tools libnotify
else
    echo "❌ Unsupported distribution. Please install v4l2loopback and gstreamer manually."
    exit 1
fi

# 2. Configure Kernel Module to load on boot
echo "⚙️ Configuring v4l2loopback kernel module..."
echo "v4l2loopback" | sudo tee /etc/modules-load.d/v4l2loopback.conf > /dev/null

# 3. Create the Systemd Service to initialize the virtual device on boot
echo "⚙️ Creating virtual device systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/virtual-webcam.service > /dev/null
[Unit]
Description=Create Virtual Webcam Device
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/v4l2loopback-ctl add -n "Virtual Hardware Camera" /dev/video35
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable --now virtual-webcam.service

# 4. Copy the toggle script to the user's local bin
echo "📂 Installing toggle script..."
mkdir -p "$HOME/.local/bin"
cp toggle-camera.sh "$HOME/.local/bin/intel-webcam-toggle.sh"
chmod +x "$HOME/.local/bin/intel-webcam-toggle.sh"

# 5. Create the Desktop Application Shortcut
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

echo "✅ Installation Complete! You may need to reboot your system for the kernel modules to fully load."
