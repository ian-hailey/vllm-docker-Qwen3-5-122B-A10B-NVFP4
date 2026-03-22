docker exec -it vllm vllm bench serve \
    --model "local-llm" \
    --tokenizer "Sehyo/Qwen3.5-122B-A10B-NVFP4" \
    --base-url "http://127.0.0.1:8000" \
    --endpoint "/v1/completions" \
    --dataset-name "random" \
    --num-prompts 1 \
    --random-input-len 124000 \
    --random-output-len 512 \
    --trust-remote-code 
