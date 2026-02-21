# Intel IPU Webcam Linux Bridge 📷🐧

A plug-and-play GStreamer and `v4l2loopback` bridge to make modern Intel MIPI webcams (IPU6 / IPU7) work with legacy Linux applications like Zoom, MS Teams, Discord, and Slack.



## 🚨 The Problem
Modern premium laptops (like the Dell XPS, ThinkPad series, and Dell Pro with Core Ultra CPUs) no longer use standard USB webcams. Instead, they wire the raw camera sensor directly to the CPU via Intel's Image Processing Unit (IPU). While `libcamera` can read this raw feed, legacy applications like Zoom only know how to read processed USB video feeds (`/dev/video0`), resulting in a blank screen.

## 🛠️ The Solution
This repository automates the creation of a "Virtual Webcam" on your system. It provides a simple desktop app toggle that:
1. Grabs the raw `libcamera` feed.
2. Applies color correction and HD scaling (bypassing the green tint issue on uncalibrated sensors).
3. Pipes it into a dummy `/dev/video35` device that Zoom and Teams can easily read.
4. Kills the feed when you click it again to save battery and protect privacy.

---

## 📋 Requirements & Compatibility

**Hardware Supported:**
* **CPUs:** Intel Meteor Lake (Core Ultra Series 1) & Lunar Lake (Core Ultra Series 2)
* **Architecture:** Intel IPU6 and IPU7
* **Tested Sensors:** OmniVision ov08x40 (Dell Pro 14), Intel MIPI cameras.

**Software Requirements:**
* **Linux Kernel:** `v6.17` or newer (Required for native IPU7 staging drivers).
* **libcamera:** `v0.6.0` or newer (Required for SoftISP image processing).
* **Distributions Supported:** Arch Linux / Manjaro, Ubuntu 24.04 LTS (and newer), Fedora 41 (and newer).

> **⚠️ SECURE BOOT WARNING:** This workaround relies on `v4l2loopback-dkms`. If you have Secure Boot enabled in your BIOS, the Linux kernel will block this unsigned custom module from loading. You must either temporarily disable Secure Boot or manually sign the DKMS module for your kernel.

---

## 🚀 Installation

1. Clone this repository:
   ```bash
   git clone [https://github.com/YOUR_USERNAME/intel-ipu-webcam-linux-bridge.git](https://github.com/YOUR_USERNAME/intel-ipu-webcam-linux-bridge.git)
   cd intel-ipu-webcam-linux-bridge
   ```
2. Run the installer script:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```
3. Reboot your system to allow the new kernel modules to load.

---

## 🎮 How to Use

1. Open your desktop Application Menu and search for Hardware Camera Toggle.
2. Click it. You will see a desktop notification saying Hardware Camera Powered ON 🎥.
3. Open Zoom, Teams, or your browser, and select Virtual Hardware Camera from the video settings.
4. When your meeting is over, click the toggle app again to shut off the hardware and turn off the camera's privacy light.

---

## 🔧 Troubleshooting

- **"The camera works, but the quality is bad / the image is green!"**

Uncalibrated sensors often default to a heavy green tint (the raw Bayer filter data) and low resolutions.
The Fix: Open ~/.local/bin/intel-webcam-toggle.sh with a text editor. You can tweak the HUE, SATURATION, and RESOLUTION variables at the top of the script to perfectly match your sensor and room lighting.

- **"The script runs, but Zoom still shows a black screen."**

Your internal camera might have a different hardware ID than the default script expects.

1. Run `cam -l` or `libcamera-hello --list-cameras` in your terminal.
2. Look for your internal camera ID (e.g., `\_SB_.LNK1` or `Intel IPU...`).
3. Open `~/.local/bin/intel-webcam-toggle.sh` and update the `CAMERA_NAME` variable. (Note: You must use four backslashes `\\\\` for every single backslash in the name to escape GStreamer's string parser!)
