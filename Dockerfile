# Single-stage build for ComfyUI + WAN2.1
FROM pytorch/pytorch:2.7.1-cuda12.8-cudnn9-runtime

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PORT=8080 \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    wget \
    curl \
    ffmpeg \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Follow official ComfyUI NVIDIA installation instructions exactly:
# 1. Install NVIDIA PyTorch first
RUN pip install --no-cache-dir torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu128

# 2. Clone ComfyUI
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git

# 3. Install ComfyUI dependencies (including safetensors)
RUN cd ComfyUI && pip install --no-cache-dir -r requirements.txt

# 4. Install custom nodes for WAN2.1
RUN cd ComfyUI/custom_nodes && \
    git clone --depth 1 https://github.com/kijai/ComfyUI-WanVideoWrapper.git && \
    git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes.git

# 5. Install custom node dependencies
RUN cd ComfyUI/custom_nodes/ComfyUI-WanVideoWrapper && \
    if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi
RUN cd ComfyUI/custom_nodes/ComfyUI-VideoHelperSuite && \
    if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi
RUN cd ComfyUI/custom_nodes/ComfyUI-KJNodes && \
    if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi

# Create model directories
RUN mkdir -p ComfyUI/models/{diffusion_models,text_encoders,vae,clip_vision}

# Copy workflow and entrypoint
COPY wan2.1_I2V_720P.json ComfyUI/
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 8080

# Models download at runtime for faster builds
ENTRYPOINT ["/app/entrypoint.sh"] 