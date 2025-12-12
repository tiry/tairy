
# fix HDR via Vulkan

DXVK_HDR=1 PROTON_ENABLE_WAYLAND=1 PROTON_ENABLE_HDR=1 ENABLE_HDR_WSI=1 %command%

# fix HDR via gamerscope

gamescope --hdr-enabled -- %command%
gamescope -W 2560 -H 1440 -r 120 -f --hdr-enabled -- %command%
