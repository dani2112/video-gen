#!/bin/bash
set -e

echo "🚀 Starting WAN2.1 ComfyUI Setup with GPU Support"

# Use Cloud Run's PORT environment variable, default to 8080
PORT=${PORT:-8080}
echo "📡 Starting on port: $PORT"

# Function to download model if not exists
download_model() {
    local url=$1
    local path=$2
    local filename=$(basename "$path")
    
    if [ ! -f "$path" ]; then
        echo "📥 Downloading $filename..."
        # Use wget with retries and better error handling
        wget --tries=3 --timeout=30 --progress=dot:giga "$url" -O "$path" || {
            echo "❌ Failed to download $filename"
            return 1
        }
        echo "✅ Downloaded $filename"
    else
        echo "✅ $filename already exists, skipping download"
    fi
}

# Start ComfyUI in background while downloading models
echo "🎨 Starting ComfyUI server..."
cd /app/ComfyUI

# Check if GPU is available
if command -v nvidia-smi &> /dev/null; then
    echo "🔥 GPU detected, running with CUDA acceleration"
    GPU_ARGS=""
else
    echo "💻 No GPU detected, running on CPU"
    GPU_ARGS="--cpu"
fi

# Start ComfyUI in background
python main.py --listen 0.0.0.0 --port $PORT $GPU_ARGS &
COMFYUI_PID=$!

# Give ComfyUI a moment to start
sleep 5

# Check if ComfyUI is running
if ! kill -0 $COMFYUI_PID 2>/dev/null; then
    echo "❌ ComfyUI failed to start"
    exit 1
fi

echo "🎯 ComfyUI is starting up on port $PORT"

# Download models in parallel while ComfyUI is starting
echo "🔍 Checking WAN2.1 models..."

# Download models in background
{
    download_model "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors" "/app/ComfyUI/models/vae/Wan2_1_VAE_bf16.safetensors" &
    download_model "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors" "/app/ComfyUI/models/text_encoders/umt5-xxl-enc-bf16.safetensors" &
    download_model "https://huggingface.co/openai/clip-vit-large-patch14/resolve/main/pytorch_model.bin" "/app/ComfyUI/models/clip_vision/clip_vision_h.safetensors" &
    download_model "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1-I2V-14B-720P_fp8_e4m3fn.safetensors" "/app/ComfyUI/models/diffusion_models/Wan2_1-I2V-14B-720P_fp8_e4m3fn.safetensors" &
    wait
} &

echo "✅ ComfyUI is ready and models are downloading in background!"
echo "🌐 Access ComfyUI at: http://localhost:$PORT"

# Wait for ComfyUI process
wait $COMFYUI_PID 