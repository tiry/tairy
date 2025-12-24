
python -m venv venv-rocm

# 2. Activate it (your prompt should change to (venv-rocm))
source venv-rocm/bin/activate

# 3. Install PyTorch ROCm version AND ipykernel
# We install ipykernel so this environment can talk to your existing Jupyter server
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/rocm7.1
pip install transformers accelerate ipykernel

# Register this environment as a kernel
# This writes a small file to ~/.local/share/jupyter/kernels/ that your running server can see
python -m ipykernel install --user --name=llm-rocm --display-name "Python (AMD ROCm 7.1)"
