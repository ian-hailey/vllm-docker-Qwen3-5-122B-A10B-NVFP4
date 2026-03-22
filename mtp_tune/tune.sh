#!/bin/bash
# 1. Stop the running server to free up VRAM
docker-compose down

# 2. Run the tuner with Ray installation and Entrypoint override
docker run --gpus all -it --rm --ipc=host \
  --entrypoint /bin/bash \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  -v ~/.cache/vllm_configs/moe:/usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/configs \
  vllm-custom-nightly \
  -c "pip install ray && python3 /vllm-workspace/benchmarks/kernels/benchmark_moe.py \
      --model Sehyo/Qwen3.5-122B-A10B-NVFP4 \
      --tp-size 1 \
      --dtype auto \
      --batch-size 1 2 4 8 \
      --tune \
      --save-dir /usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/fused_moe/configs"
