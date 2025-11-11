#!/bin/bash
set -e

VENV_DIR="./venv"
PYTHON_BIN="python3"

# Create venv if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python virtual environment..."
    $PYTHON_BIN -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

# Install requirements
pip install --upgrade pip
pip install langchain-community

# Run the viewer
python dump_chunks.py


