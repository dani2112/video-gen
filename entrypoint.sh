#!/bin/bash
set -e

echo "🚀 Starting WAN2.1 ComfyUI Setup with GPU Support"

# Use Cloud Run's PORT environment variable, default to 8080
PORT=${PORT:-8080}
echo "📡 Starting on port: $PORT"

# Function to download model with GCS caching
download_model() {
    local url=$1
    local path=$2
    local filename=$(basename "$path")
    local gcs_path="gs://YOUR_BUCKET_NAME/models/$filename"
    
    # First try to download from GCS cache
    if gsutil -q stat "$gcs_path" 2>/dev/null; then
        echo "📦 Found $filename in GCS cache, downloading..."
        gsutil cp "$gcs_path" "$path" && {
            echo "✅ Downloaded $filename from cache"
            return 0
        }
    fi
    
    # If not in cache or cache failed, download from original source
    if [ ! -f "$path" ]; then
        echo "📥 Downloading $filename from source..."
        wget --tries=3 --timeout=30 --progress=dot:giga "$url" -O "$path" || {
            echo "❌ Failed to download $filename"
            return 1
        }
        echo "✅ Downloaded $filename"
        
        # Upload to GCS cache for next time
        echo "📤 Caching $filename to GCS..."
        gsutil cp "$path" "$gcs_path" || echo "⚠️ Failed to cache to GCS"
    else
        echo "✅ $filename already exists locally"
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
    download_model "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors?download=true" "/app/ComfyUI/models/clip_vision/clip_vision_h.safetensors" &
    download_model "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1-I2V-14B-720P_fp8_e4m3fn.safetensors" "/app/ComfyUI/models/diffusion_models/Wan2_1-I2V-14B-720P_fp8_e4m3fn.safetensors" &
    wait
} &

echo "✅ ComfyUI is ready and models are downloading in background!"
echo "🌐 Access ComfyUI at: http://localhost:$PORT"

# Wait for ComfyUI process
wait $COMFYUI_PID 