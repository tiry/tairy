#!/bin/bash
echo "Attempting to unload NVIDIA modules..."
sudo modprobe -r nvidia_drm 2>/dev/null
sudo modprobe -r nvidia_modeset 2>/dev/null
sudo modprobe -r nvidia_uvm 2>/dev/null
sudo modprobe -r nvidia 2>/dev/null
echo "Cleanup complete. You can now safely shutdown/reboot."
