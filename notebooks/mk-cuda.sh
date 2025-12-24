python -m venv venv-cuda

# 3. Activate it
source venv-cuda/bin/activate

# 4. Install PyTorch with CUDA support
# Standard 'pip install torch' defaults to CUDA 12.x on Linux, which is what we want.
pip install torch torchvision torchaudio transformers accelerate jupyter ipykernel

# 5. Register the kernel
python -m ipykernel install --user --name=llm-cuda --display-name "Python (Nvidia CUDA)"