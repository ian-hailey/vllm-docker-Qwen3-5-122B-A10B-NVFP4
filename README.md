# Docker Setup for Qwen3.5-122B-A10B-NVFP4 with vLLM

Docker container configuration for launching **Qwen3.5-122B-A10B-NVFP4** with vLLM, featuring Multi-Token Prediction (MTP) speculative decoding for accelerated inference.

## Model Information

- **Model**: Sehyo/Qwen3.5-122B-A10B-NVFP4
- **Architecture**: Qwen3_5MoeForConditionalGeneration (MoE)
- **Quantization**: NVFP4 (NVIDIA FP4)
- **Max Context Length**: 262,144 tokens
- **vLLM Version**: 0.17.2rc1

## Prerequisites

- NVIDIA GPU with CUDA support (tested on RTX PRO 6000 Blackwell)
- Docker & Docker Compose
- Hugging Face token (for model access)

## Quick Start

### 1. Set Your Hugging Face Toke

Edit `docker-compose.yaml` and replace the placeholder token:
```yaml
HUGGING_FACE_HUB_TOKEN: "hf_your_actual_token_here"
```

### 2. Build and Run

```bash
docker-compose build
docker-compose up
```

The server will start on `http://0.0.0.0:8000`

## Configuration Details

### Dockerfile
```dockerfile
FROM vllm/vllm-openai:nightly

USER root

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

RUN uv pip install --system --upgrade --force-reinstall git+https://github.com/huggingface/transformers.git
```

### Speculative Decoding (MTP)

```json
--speculative-config '{"method":"mtp","num_speculative_tokens":2}'
```

- **Method**: MTP (Multi-Token Prediction)
- **Speculative Tokens**: 2 tokens per step
- **Drafter Model**: Uses MTP head from the same model
- **To Disable MTP**: Comment out the `--speculative-config` line in `docker-compose.yaml`

### Optional MTP Performance Tuning

For optimal MTP performance, you can run the `mtp_tune/tune.sh` script to benchmark and tune MoE kernel configurations for your specific GPU. This generates optimized configuration files that can improve inference performance.

**Prerequisites**:
- Stop the running server first (script does this automatically)
- Requires ~75 minutes (1hr 15mins) to complete

**How to Run**:
```bash
# Stop the server and run tuning script
./mtp_tune/tune.sh
```

**What it does**:
- Benchmarks fused MoE kernel configurations for your specific hardware (tested on NVIDIA RTX PRO 6000 Blackwell)
- Tests 1,920 different configurations across batch sizes 1, 2, 4, and 8
- Saves optimized configuration to vllm's fused MoE config directory

**Output**:
- Generated config file: `E=256,N=1024,device_name=NVIDIA_RTX_PRO_6000_Blackwell_Workstation_Edition.json`
- Total tuning time: ~4,367 seconds (1hr 15mins)

**Note**: This is optional. The model will work without tuning, but tuned configurations may provide better performance for your specific GPU.

## Benchmark Results: MTP vs No-MTP

### Test Configuration
- **Hardware**: NVIDIA RTX PRO 6000 Blackwell
- **Input/Output**: Various token lengths (124K-240K input, 512 output)
- **MTP Config**: 2 speculative tokens

### Benchmark Comparison

#### Single Request (1x 124K in, 512 out)

| Metric | MTP Enabled | No MTP | Improvement |
|--------|-------------|--------|-------------|
| Duration | 29.32s | 29.91s | +2% |
| Output Token Throughput | 17.46 tok/s | 17.12 tok/s | +2% |
| Total Token Throughput | 4245.99 tok/s | 4162.32 tok/s | +2% |
| Mean TPOT | 7.22 ms | 12.74 ms | **43% faster** |
| Mean TTFT | 25,634 ms | 23,401 ms | -9% |
| Acceptance Rate | 98.84% | N/A | - |

#### Single Request (1x 240K in, 512 out)

| Metric | MTP Enabled | No MTP | Improvement |
|--------|-------------|--------|-------------|
| Duration | 60.10s | 57.83s | -4% |
| Output Token Throughput | 8.52 tok/s | 8.85 tok/s | -4% |
| Total Token Throughput | 4001.66 tok/s | 4158.62 tok/s | -4% |
| Mean TPOT | 7.57 ms | 13.51 ms | **44% faster** |
| Mean TTFT | 56,233 ms | 50,929 ms | -10% |
| Acceptance Rate | 97.13% | N/A | - |

#### Concurrent Requests (2x 124K in, 512 out)

| Metric | MTP Enabled | No MTP | Difference |
|--------|-------------|--------|------------|
| Duration | 146.88s | 32.53s | **+351%** |
| Output Token Throughput | 6.97 tok/s | 31.48 tok/s | -78% |
| Total Token Throughput | 1695.39 tok/s | 7654.81 tok/s | -78% |
| Mean TPOT | 107.87 ms | 37.95 ms | +184% |
| Mean TTFT | 84,813 ms | 12,945 ms | +554% |
| Acceptance Rate | 95.33% | N/A | - |


## Key Observations

### MTP Advantages (Single Request)
- **Faster TPOT**: 43-44% reduction in time per output token for single requests
- **High Acceptance Rate**: 95-99% of draft tokens accepted, indicating effective speculation
- **Consistent Performance**: Stable TPOT across different input lengths

### MTP Limitations (Concurrent Requests)
- **Concurrency Impact**: Significant performance degradation with 2+ concurrent requests
- **Resource Contention**: MTP appears to consume resources that affect multi-request handling
- **Throughput Drop**: 78% reduction in output token throughput under concurrent load

### Recommendations

1. **Single-user/Low-concurrency scenarios**: MTP provides faster response times
2. **Multi-user/High-concurrency scenarios**: Consider disabling MTP for better throughput
3. **To disable MTP**: Remove the `--speculative-config` argument from docker-compose.yaml

## Troubleshooting

### Common Issues

1. **Model Download Failed**: Ensure your Hugging Face token is valid and has access to the model
2. **GPU Memory Issues**: Adjust `--gpu-memory-utilization` if OOM errors occur
3. **Slow First Token**: TTFT is expected to be high for 100K+ context inputs due to prefill time

### Logs

View container logs:
```bash
docker-compose logs -f vllm
```

## License

This configuration is provided for educational and research purposes. Please refer to the model's license on Hugging Face for usage terms.