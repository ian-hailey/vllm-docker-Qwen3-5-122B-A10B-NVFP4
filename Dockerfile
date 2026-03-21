FROM vllm/vllm-openai:nightly

USER root

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

RUN uv pip install --system --upgrade --force-reinstall git+https://github.com/huggingface/transformers.git


