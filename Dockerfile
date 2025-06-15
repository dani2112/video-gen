# Multi-stage build for optimized ComfyUI + WAN2.1
FROM pytorch/pytorch:2.7.1-cuda12.8-cudnn9-runtime as builder

# Set environment variables for build
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install build dependencies in one layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Clone and install everything in combined layers for better caching
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git && \
    cd ComfyUI && \
    pip install --no-cache-dir -r requirements.txt && \
    # Install custom nodes
    cd custom_nodes && \
    git clone --depth 1 https://github.com/kijai/ComfyUI-WanVideoWrapper.git && \
    git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes.git && \
    # Install custom node dependencies
    cd ComfyUI-WanVideoWrapper && \
    if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi && \
    cd ../ComfyUI-VideoHelperSuite && \
    if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi && \
    cd ../ComfyUI-KJNodes && \
    if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi

# Final optimized image
FROM pytorch/pytorch:2.7.1-cuda12.8-cudnn9-runtime

# Runtime environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PORT=8080 \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility

WORKDIR /app

# Install only runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ffmpeg \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy ComfyUI from builder stage
COPY --from=builder /app/ComfyUI /app/ComfyUI

# Create model directories
RUN mkdir -p ComfyUI/models/{diffusion_models,text_encoders,vae,clip_vision}

# Copy workflow and entrypoint
COPY wan2.1_I2V_720P.json ComfyUI/
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 8080

# Models download at runtime for faster builds
ENTRYPOINT ["/app/entrypoint.sh"] 