# Jupyter Notebook Setup

This directory contains a script to automatically manage a Python virtual environment and run Jupyter Notebook.

## Usage

Simply run the script:

```bash
./start-jupyter.sh
```

## What the script does

1. **Creates a Python virtual environment** (if it doesn't exist) in `notebooks/venv/`
2. **Activates the virtual environment** (if it already exists)
3. **Installs Jupyter Notebook** (if not already installed)
4. **Starts the Jupyter server** pointing to the `notebooks/notebooks/` subdirectory

## Directory Structure

```
notebooks/
├── start-jupyter.sh       # Main script
├── venv/                  # Python virtual environment (created automatically)
├── notebooks/             # Your Jupyter notebooks go here
└── README.md             # This file
```

## First Run

On the first run, the script will:
- Create the virtual environment
- Install pip dependencies
- Install Jupyter Notebook
- Start the server

This may take a few minutes.

## Subsequent Runs

On subsequent runs, the script will:
- Activate the existing virtual environment
- Check if Jupyter is installed
- Start the server immediately

## Access

Once running, Jupyter will typically be available at:
- http://localhost:8888

The terminal will display the exact URL with the access token.

## Stopping the Server

Press `Ctrl+C` in the terminal to stop the Jupyter server.

## Notes

- All your notebooks should be saved in the `notebooks/notebooks/` subdirectory
- The virtual environment is isolated and won't affect your system Python
- The script uses Python 3 by default

## Available Notebooks

### LLM Inference Notebooks

- **CPU_Inference.ipynb** - Run LLM inference on CPU using transformers library
- **Cuda-Inference.ipynb** - Run LLM inference on NVIDIA GPUs using CUDA
- **Cuda-Inference-Mistral.ipynb** - Run Mistral model inference on NVIDIA GPUs
- **ROCm-Inference.ipynb** - Run LLM inference on AMD GPUs using ROCm
- **Rocm-Inference-Mistral.ipynb** - Run Mistral model inference on AMD GPUs
- **Mistral7B.ipynb** - Work with Mistral 7B model (general usage)
- **Mitstral7B verlan inference.ipynb** - Mistral 7B inference with Verlan (French slang) fine-tuned model

### LLM Fine-Tuning Notebooks

- **Mistral7B-FineTune.ipynb** - Fine-tune Mistral 7B model on custom datasets
- **embeddings.ipynb** - Work with text embeddings and vector representations

### Stable Diffusion Notebooks

- **SDXL.ipynb** - Generate images using Stable Diffusion XL base model
- **SDXL-LORA.ipynb** - Generate images using Stable Diffusion XL with LoRA fine-tuning
- **SD-LORA.ipynb** - Generate images using Stable Diffusion 1.5 with LoRA fine-tuning
- **Image_DataSet_processing.ipynb** - Preprocess and prepare image datasets for training

### Utility Notebooks

- **version.ipynb** - Check installed library versions and system information
