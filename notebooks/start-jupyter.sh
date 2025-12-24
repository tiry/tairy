#!/bin/bash

# Script to manage Python venv and start Jupyter Notebook server
# This script will:
# - Create a Python virtual environment if it doesn't exist
# - Activate the virtual environment
# - Install Jupyter Notebook if needed
# - Start the Jupyter server pointing to the notebooks subfolder

set -e  # Exit on error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"
NOTEBOOKS_DIR="$SCRIPT_DIR/notebooks"

echo "========================================"
echo "Jupyter Notebook Setup & Launch Script"
echo "========================================"
echo ""

# Create notebooks directory if it doesn't exist
if [ ! -d "$NOTEBOOKS_DIR" ]; then
    echo "Creating notebooks directory: $NOTEBOOKS_DIR"
    mkdir -p "$NOTEBOOKS_DIR"
fi

# Check if virtual environment exists
if [ ! -d "$VENV_DIR" ]; then
    echo "Virtual environment not found. Creating new venv..."
    python3 -m venv "$VENV_DIR"
    echo "✓ Virtual environment created at: $VENV_DIR"
else
    echo "✓ Virtual environment already exists at: $VENV_DIR"
fi

# Activate virtual environment
echo "Activating virtual environment..."
source "$VENV_DIR/bin/activate"
echo "✓ Virtual environment activated"

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip -q

# Check if Jupyter is installed
if ! command -v jupyter &> /dev/null; then
    echo "Jupyter not found. Installing Jupyter Notebook..."
    pip install jupyter notebook
    echo "✓ Jupyter Notebook installed"
else
    echo "✓ Jupyter already installed"
fi

# Print info
echo ""
echo "========================================"
echo "Starting Jupyter Notebook Server"
echo "========================================"
echo "Notebooks directory: $NOTEBOOKS_DIR"
echo "Virtual environment: $VENV_DIR"
echo ""
echo "Press Ctrl+C to stop the server"
echo "========================================"
echo ""

# Start Jupyter Notebook server pointing to the notebooks directory
cd "$SCRIPT_DIR"
jupyter notebook --notebook-dir="$NOTEBOOKS_DIR" --ip=127.0.0.1
