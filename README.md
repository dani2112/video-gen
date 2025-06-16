# video-gen

docker build -f Dockerfile.framepack -t framepack:latest .

docker run -it --rm \
  --gpus all \
  -p 127.0.0.1:7860:7860 \
  -v $(pwd)/hf_models:/app/models \
  framepack:latest

docker build -f Dockerfile.wangp -t wan2gp:latest .

docker run --gpus all -it --rm \
  -v "$(pwd)/wangp_checkpoints:/app/ckpts" \
  -p 127.0.0.1:7860:7860 \
  wan2gp:latest python wgp.py --i2v --server-name 0.0.0.0