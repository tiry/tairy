# FFMPEG Hardware Acceleration on Arch Linux (AMD APU)

This guide covers the installation and usage of `ffmpeg` with full VA-API hardware acceleration on an Arch Linux system running an AMD APU (like Strix Halo).

This method enables "zero-copy" transcoding, where video frames are decoded and re-encoded entirely on the GPU (VCN) without ever passing through the CPU, providing the fastest possible performance.

## 1\. ⚙️ Installation

You need `ffmpeg` and the specific VA-API (Video Acceleration API) drivers for your AMD GPU.

```bash
# Install the main ffmpeg package
sudo pacman -S ffmpeg

# Install the VA-API drivers provided by Mesa
sudo pacman -S libva-mesa-driver

# Install the VA-API utility for verification
sudo pacman -S libva-utils
```

## 2\. ✅ Verification

Run the `vainfo` command to verify that your system correctly identifies your GPU's hardware encoding and decoding capabilities.

```bash
vainfo
```

Look for lines that include `VAEntrypointEncSlice`. This confirms you can **encode** (compress) video. You should see entries for `H264`, `HEVC`, and `AV1`.

## 3\. 🚀 The "Zero-Copy" Transcode Command

This is the optimal command to re-encode a video file from H.264 to AV1. It decodes and encodes on the GPU, copying the audio stream as-is.

```bash
ffmpeg -hwaccel vaapi -hwaccel_output_format vaapi -i input.mp4 -c:v av1_vaapi -qp 22 -c:a copy output-av1.mkv
```

### Command Breakdown

  * **`-hwaccel vaapi`**: Tells `ffmpeg` to use VA-API (your GPU) to **decode** the input file.
  * **`-hwaccel_output_format vaapi`**: This is the key. It tells the decoder to **keep the decoded frames in GPU memory** instead of downloading them to system RAM.
  * **`-i input.mp4`**: The input video file.
  * **`-c:v av1_vaapi`**: Sets the **v**ideo **c**odec to `av1_vaapi`, instructing `ffmpeg` to use your GPU's dedicated **AV1 encoder**.
  * **`-qp 22`**: Sets the **q**uality **p**arameter. This is a constant quality mode (lower is better quality, 18-28 is a good range). You can also use a bitrate, e.g., `-b:v 6M`.
  * **`-c:a copy`**: Copies the **a**udio **c**odec. This is very fast and preserves 100% of the original audio quality.
  * **`output-av1.mkv`**: The output file. The `.mkv` (Matroska) container is highly recommended for AV1.

### Common Error (And Solution)

If you *don't* use the `-hwaccel` flags, you might need to manually upload the video frames from the CPU to the GPU. The command for that is:

```bash
# This is a slower, fallback method
ffmpeg -i input.mp4 -vf "format=nv12,hwupload" -c:v av1_vaapi -qp 22 -c:a copy output_av1.mkv
```

However, the "zero-copy" method is faster and more efficient.
