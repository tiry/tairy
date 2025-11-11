# Installing `text-generation-webui` on Arch Linux with AMD ROCm

This guide details the specific process for installing `text-generation-webui` on Arch Linux and **forcing it to use a custom-compiled ROCm backend**.

This procedure is necessary for bleeding-edge AMD APUs (like the Strix Halo, `gfx1151`) where the default installer downloads an incorrect or non-optimized backend (e.g., Vulkan), and we want to ensure maximum performance by using our native ROCm build.

## 1\. Prerequisites

Before you begin, ensure your system has the necessary build tools and the ROCm driver stack installed.

```bash
sudo pacman -Syu git cmake base-devel rocm-hip-sdk rocminfo
```

## 2\. Step 1: Initial `text-generation-webui` Setup

First, we will clone the repository and run the installer *once*. The only goal of this step is to let the installer create its Conda environment and download its base dependencies.

```bash
git clone https://github.com/oobabooga/text-generation-webui.git
cd text-generation-webui
./start_linux.sh
```

The installer will download many files and likely install the wrong `llama-cpp` package (e.g., `llama-cpp-binaries` with Vulkan support). This is expected. Once the UI is running or the script finishes, stop it with `Ctrl+C`.

## 3\. Step 2: Manually Replace the `llama.cpp` Backend

This is the most critical step. We will enter the new Conda environment, remove the incorrect `llama-cpp` library, and manually compile the correct one with our ROCm flags.

### 3.1. Activate the Conda Environment

Activate the `(base)` environment that the installer just created:

```bash
source installer_files/conda/bin/activate
```

Your terminal prompt will change to show `(base)` at the beginning.

### 3.2. Uninstall Incorrect Packages

From inside the `(base)` environment, remove any pre-compiled `llama.cpp` libraries. The `-y` flag confirms "yes" to all prompts.

```bash
pip uninstall llama-cpp-binaries llama-cpp-python -y
```

### 3.3. Install `llama-cpp-python` with ROCm Flags

Still inside the `(base)` environment, run this command. It will download the `llama-cpp-python` source code and compile it with our specific flags for the `gfx1151` architecture. This will take several minutes.

```bash
CMAKE_ARGS="-DGGML_HIP=ON -DAMDGPU_TARGETS=gfx1151" pip install --upgrade --force-reinstall llama-cpp-python --no-cache-dir
```

## 4\. Step 3: Running the Server

You can no longer use `start_linux.sh`, as it will try to "fix" your dependencies.

Instead, while your `(base)` environment is active, you must use `python server.py` with the `--skip-install` flag.

```bash
# Make sure you are in the (base) environment
# source installer_files/conda/bin/activate

# Run the server with your custom model directory
python server.py \
  --skip-install \
  --listen \
  --listen-host 0.0.0.0 \
  --model-dir /home/tiry/llama.cpp/models/
```

The UI will now be running and using your custom-compiled ROCm backend, allowing you to select and load models with full GPU acceleration.

## 5\. (Optional) Create a `systemd` Service

To manage the server without SSHing in, you can create a service file.

**1. Create the file:**

```bash
sudo nano /etc/systemd/system/text-generation-webui.service
```

**2. Paste the following configuration.** This file is designed to correctly activate the Conda environment before running the server.

```ini
[Unit]
Description=Text Generation Web UI
After=network.target

[Service]
Type=simple
User=tiry

# Set the working directory to your web UI folder
WorkingDirectory=/home/tiry/text-generation-webui

# This command activates the conda env and then runs the server
ExecStart=/bin/bash -c "source /home/tiry/text-generation-webui/installer_files/conda/bin/activate && \
  python server.py \
  --skip-install \
  --listen \
  --listen-host 0.0.0.0 \
  --model-dir /home/tiry/llama.cpp/models/"

Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**3. Enable and Start the Service:**

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now text-generation-webui.service
```

You can now manage the service with `sudo systemctl status|start|stop|restart text-generation-webui`.

