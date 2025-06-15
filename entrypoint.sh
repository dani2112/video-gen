#!/bin/bash
set -e

echo "🚀 Starting WAN2.1 ComfyUI Setup with GPU Support"

# Function to download model if not exists
download_model() {
    local url=$1
    local path=$2
    local filename=$(basename "$path")
    
    if [ ! -f "$path" ]; then
        echo "📥 Downloading $filename..."
        wget -q --show-progress "$url" -O "$path"
        echo "✅ Downloaded $filename"
    else
        echo "✅ $filename already exists, skipping download"
    fi
}

# Download WAN2.1 models if they do not exist
echo "🔍 Checking WAN2.1 models..."

download_model "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors" "/app/ComfyUI/models/vae/Wan2_1_VAE_bf16.safetensors"

download_model "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors" "/app/ComfyUI/models/text_encoders/umt5-xxl-enc-bf16.safetensors"

download_model "https://huggingface.co/openai/clip-vit-large-patch14/resolve/main/pytorch_model.bin" "/app/ComfyUI/models/clip_vision/clip_vision_h.safetensors"

download_model "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1-I2V-14B-720P_fp8_e4m3fn.safetensors" "/app/ComfyUI/models/diffusion_models/Wan2_1-I2V-14B-720P_fp8_e4m3fn.safetensors"

echo "✅ All models ready!"

# Use Cloud Run's PORT environment variable, default to 8080
PORT=${PORT:-8080}

# Check if GPU is available
if command -v nvidia-smi &> /dev/null; then
    echo "🔥 GPU detected, running with CUDA acceleration"
    GPU_ARGS=""
else
    echo "💻 No GPU detected, running on CPU"
    GPU_ARGS="--cpu"
fi

# Start ComfyUI with appropriate settings
echo "🎨 Starting ComfyUI on port $PORT..."
cd /app/ComfyUI
python main.py --listen 0.0.0.0 --port $PORT $GPU_ARGS 