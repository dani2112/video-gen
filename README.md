# video-gen

docker build -f Dockerfile.framepack -t framepack:latest .

docker run -it --rm \
  --gpus all \
  -p 127.0.0.1:7860:7860 \
  -v $(pwd)/hf_models:/app/models \
  framepack:latest

of for f1

docker run -it --rm \
  --gpus all \
  -p 127.0.0.1:7860:7860 \
  -v $(pwd)/hf_models:/app/models \
  framepack:latest python demo_gradio_f1.py --server 0.0.0.0

docker build -f Dockerfile.wangp -t wan2gp:latest .

docker run --gpus all -it --rm \
  -v "$(pwd)/wangp_checkpoints:/app/ckpts" \
  -p 127.0.0.1:7860:7860 \
  wan2gp:latest python wgp.py --i2v --server-name 0.0.0.0 --teacache 2.0 --sage-attention

docker run --gpus all -it --rm \
  -v "$(pwd)/videos:/host" \
  ghcr.io/k4yt3x/video2x:6.4.0


  docker run --gpus all -it --rm \
  -v "$(pwd)/videos:/host" \
  ghcr.io/k4yt3x/video2x:6.4.0 \
  -i /host/250616_152230_915_6475_37.mp4 \
  -o /host/250616_152230_915_6475_37_upscaled.mp4 \
  -s 4 \
  -p realesrgan --realesrgan-model realesrgan-plus \
  -c libx264 -e crf=18 -e preset=slow
  -gpu

  on gcp
  
  docker run -it --rm   --gpus all   --network host   -v $(pwd)/hf_models:/app/models   -e GRADIO_USERNAME=username   -e GRADIO_PASSWORD=password   -e HF_HUB_OFFLINE=0   framepack:latest   python demo_gradio_f1.py --server 0.0.0.0

## SwarmUI (PyTorch Runtime with CUDA)

Build SwarmUI container:

```bash
docker build -f Dockerfile.swarmui -t swarmui:latest .
```

Run SwarmUI container:

```bash
docker run -it --rm \
  -p 127.0.0.1:7860:7860 \
  -v $(pwd)/swarm_models:/SwarmUI/Models \
  -v $(pwd)/swarm_output:/SwarmUI/Output \
  -v $(pwd)/swarm_data:/SwarmUI/Data \
  swarmui:latest
```

Run SwarmUI with authentication on GCP/remote:

```bash
docker run -it --rm \
  --gpus all \
  --network host \
  -v $(pwd)/swarm_models:/SwarmUI/Models \
  -v $(pwd)/swarm_output:/SwarmUI/Output \
  -v $(pwd)/swarm_data:/SwarmUI/Data \
  swarmui:latest
```

Access SwarmUI at: http://localhost:7860

huggingface-cli download mit-han-lab/nunchaku-flux.1-dev svdq-int4_r32-flux.1-dev.safetensors --local-dir swarm_models/diffusion_models/flux.dev --local-dir-use-symlinks False

Segment objets with SAML https://huggingface.co/spaces/Xenova/segment-anything-web
