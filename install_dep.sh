#!/bin/bash

# Function to download Miniconda installer
download_miniconda() {
    if [ ! -f "$1" ]; then
        echo "Downloading Miniconda installer..."
        wget -O "$1" "$2"
    else
        echo "Miniconda installer already exists."
    fi
}

# Function to install Miniconda
install_miniconda() {
    echo "Installing Miniconda..."
    bash "$1" -b -p "$2"
    export PATH="$2/bin:$PATH"
}

# Function for Conda initialization
conda_init_shell() {
    echo "Initializing Conda for $1..."
    eval "$(conda shell.$1 hook)"
}

# Determine OS
OS="Unknown"
case "$(uname -s)" in
    Linux*)     OS="Linux";;
    Darwin*)    OS="MacOS";;
    MINGW64*)   OS="Windows";;
    *)          echo "Unsupported OS."; exit 1;;
esac

echo "Detected OS: $OS"

# Variables based on OS
if [ "$OS" = "Windows" ]; then
    MINICONDA_INSTALLER="Miniconda3-latest-Windows-x86_64.exe"
    MINICONDA_URL="https://repo.anaconda.com/miniconda/$MINICONDA_INSTALLER"
    MINICONDA_PATH="/c/miniconda"
    WORKSPACE_PATH="/c/opt/workspace"
    SHELL_TYPE="bash"
else
    MINICONDA_INSTALLER="Miniconda3-latest-${OS}-x86_64.sh"
    MINICONDA_URL="https://repo.anaconda.com/miniconda/$MINICONDA_INSTALLER"
    MINICONDA_PATH="/opt/miniconda"
    WORKSPACE_PATH="/opt/workspace"
    SHELL_TYPE="bash"
fi

# Check and create workspace directory
if [ ! -d "$WORKSPACE_PATH" ]; then
    mkdir -p "$WORKSPACE_PATH"
fi
cd "$WORKSPACE_PATH"

# 1. Check if Conda is installed
if ! command -v conda &> /dev/null; then
    # Conda is not installed, proceed with steps 3, 4, 5
    download_miniconda "$MINICONDA_INSTALLER" "$MINICONDA_URL"
    install_miniconda "$MINICONDA_INSTALLER" "$MINICONDA_PATH"
    conda_init_shell "$SHELL_TYPE"
else
    echo "Conda is already installed."
fi

# 2. Check if Conda environment exists
if conda info --envs | grep -q "paddledet"; then
    echo "Conda environment 'paddledet' already exists."
else
    # Create Conda environment
    conda create -n paddledet python=3.8 -y
fi
# Activate Conda environment
conda_init_shell "$SHELL_TYPE"
conda activate paddledet

# Dynamically determine the path to pip based on the Python executable's location
PIP_PATH=$(dirname $(which python))/pip

# Check if PaddleDetection directory exists
if [ -d "PaddleDetection" ]; then
    echo "PaddleDetection directory exists. Updating repository..."
    cd PaddleDetection
    git pull
else
    # Clone PaddleDetection repository
    git clone https://github.com/n0rthwood/PaddleDetection.git
    cd PaddleDetection
fi

# Install packages and dependencies using the full pip path
$PIP_PATH install --upgrade pip
$PIP_PATH install paddlepaddle-gpu==2.5.2 -i https://mirror.baidu.com/pypi/simple
$PIP_PATH install idna
python -c "import paddle; print(paddle.__version__)"

# Additional installations for Windows
if [ "$OS" = "Windows" ]; then
    $PIP_PATH install cython
    $PIP_PATH install git+https://github.com/philferriere/cocoapi.git#subdirectory=PythonAPI
fi

# Paddle detection and further installations
$PIP_PATH install -r requirements.txt
python setup.py install
$PIP_PATH install -e .
python ppdet/modeling/tests/test_architectures.py

# Testing
export CUDA_VISIBLE_DEVICES=0
python tools/infer.py -c configs/ppyolo/ppyolo_r50vd_dcn_1x_coco.yml -o use_gpu=true weights=https://paddledet.bj.bcebos.com/models/ppyolo_r50vd_dcn_1x_coco.pdparams --infer_img=demo/000000014439.jpg

# Paddle-convert packages
$PIP_PATH install paddle2onnx
$PIP_PATH install onnxruntime-gpu