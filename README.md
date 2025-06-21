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
  --network host
  -v $(pwd)/hf_models:/app/models \
  framepack:latest python demo_gradio_f1.py --server 0.0.0.0

docker build -f Dockerfile.wangp -t wan2gp:latest .

docker run --gpus all -it --rm \
  -v "$(pwd)/wangp_checkpoints:/app/ckpts" \
  -p 127.0.0.1:7860:7860 \
  wan2gp:latest python wgp.py --i2v --server-name 0.0.0.0

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