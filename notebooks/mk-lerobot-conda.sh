#!/bin/bash

# 1. Setup paths
ENV_NAME="lerobot-env"
CONDA_BASE=$(conda info --base)
ENV_PATH="$CONDA_BASE/envs/$ENV_NAME"

eval "$($CONDA_BASE/bin/conda shell.bash hook)"

echo "📦 Creating/Updating environment: $ENV_NAME"
conda create -y -n $ENV_NAME python=3.10 ffmpeg=7.1 -c conda-forge

conda activate $ENV_NAME

echo "🚀 Installing dependencies into $ENV_PATH..."
$ENV_PATH/bin/pip install torch torchcodec torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
$ENV_PATH/bin/pip install jupyter ipykernel python-dotenv huggingface_hub peft

if [ ! -d "lerobot" ]; then
    echo "Cloning LeRobot repository..."
    git clone https://github.com/huggingface/lerobot.git
fi
cd lerobot
$ENV_PATH/bin/pip install -e ".[smolvla]"
cd ..

echo "🔧 Registering Jupyter Kernel..."
$ENV_PATH/bin/python -m ipykernel install --user --name lerobot_conda --display-name "Python 3 (LeRobot-Conda)"

echo "✅ Done! Restart Jupyter and select 'Python 3 (LeRobot-Conda)'"
