
## Running Container in Interactive mode

### ROCm

from the benchmark directory


   docker run -it \
    --device /dev/kfd \
    --device /dev/dri \
    --group-add video \
    --ipc=host \
    -p 8000:8000 \
    -e HSA_OVERRIDE_GFX_VERSION=11.0.0 \
    -e VLLM_USE_V1=0 \
    --cap-add=SYS_PTRACE \
    --security-opt seccomp=unconfined \
    -v ~/.cache/huggingface:/root/.cache/huggingface \
    -v ./vllm-bench:/opt/vllm-bench \
    vllm/vllm-omni-rocm:v0.12.0rc1 \
    bash


then run the benchmarks from `/opt/vllm-bench`

### Cuda


