#!/bin/bash

# ==========================================
# CONFIGURATION
# If your camera is not found, run 'cam -l' or 'libcamera-hello --list-cameras'
# and replace the CAMERA_NAME below with your hardware ID.
# ==========================================
CAMERA_NAME="\\\\_SB_.LNK1"
VIRTUAL_DEVICE="/dev/video35"
HUE="0.15"
SATURATION="1.2"
RESOLUTION="width=1920,height=1080"
# ==========================================

# Check if the GStreamer pipeline is currently running
if pgrep -f "v4l2sink device=$VIRTUAL_DEVICE" > /dev/null; then
    # Kill the pipeline to turn off the hardware and save battery
    pkill -f "v4l2sink device=$VIRTUAL_DEVICE"
    notify-send -u normal "Virtual Camera" "Hardware Camera Powered OFF 🛑"
else
    # Start the pipeline, applying color correction and scaling
    /usr/bin/gst-launch-1.0 libcamerasrc camera-name="$CAMERA_NAME" ! \
    videoconvert ! videobalance hue=$HUE saturation=$SATURATION ! \
    videoscale ! video/x-raw,$RESOLUTION,format=YUY2 ! \
    v4l2sink device=$VIRTUAL_DEVICE > /dev/null 2>&1 &
    
    notify-send -u normal "Virtual Camera" "Hardware Camera Powered ON 🎥"
fi
