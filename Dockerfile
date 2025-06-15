# ComfyUI for Google Cloud Run - GPU Support with CUDA 12.8
FROM pytorch/pytorch:2.7.1-cuda12.8-cudnn9-runtime

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PORT=8080
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    ffmpeg \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git

# Install ComfyUI dependencies (this is all we need!)
RUN cd ComfyUI && pip install --no-cache-dir -r requirements.txt

# Install required custom nodes for WAN2.1
RUN cd ComfyUI/custom_nodes && \
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    git clone https://github.com/kijai/ComfyUI-KJNodes.git

# Install dependencies for custom nodes (with error handling)
RUN cd ComfyUI/custom_nodes/ComfyUI-WanVideoWrapper && \
    if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi
RUN cd ComfyUI/custom_nodes/ComfyUI-VideoHelperSuite && \
    if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi
RUN cd ComfyUI/custom_nodes/ComfyUI-KJNodes && \
    if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi

# Create model directories
RUN mkdir -p ComfyUI/models/diffusion_models \
    ComfyUI/models/text_encoders \
    ComfyUI/models/vae \
    ComfyUI/models/clip_vision

# Copy workflow and entrypoint script
COPY wan2.1_I2V_720P.json ComfyUI/
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Expose Cloud Run port (8080) but also support ComfyUI default (8188)
EXPOSE 8080

# Use the entrypoint script
ENTRYPOINT ["/app/entrypoint.sh"] 