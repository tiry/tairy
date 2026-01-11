
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

from the benchmark directory

    docker run -it \
        --entrypoint /bin/bash \
        --gpus all \
        --ipc=host \
        -p 8000:8000 \
        --security-opt seccomp=unconfined \
        -v ~/.cache/huggingface:/root/.cache/huggingface \
        -v ./vllm-bench:/opt/vllm-bench \
        vllm/vllm-omni:v0.12.0rc1

    
then run the benchmarks from `/opt/vllm-bench`

## Running bench from within the docker container

### Individual CLIs

**starting serving**

    vllm bench throughput --model google/gemma-3-4b-it

**starting benchmark**

    vllm bench serve --save-result --save-detailed \
      --backend vllm \
      --model google/gemma-3-4b-it \
      --endpoint /v1/completions \
      --dataset-name custom \
      --dataset-path prompts.jsonl \
      --num-prompts 3 \
      --max-concurrency 1 \
      --temperature=0.3 \
      --top-p=0.75 \
      --result-dir "./log/"

### Using scripts

You can leverage the scripts:

 - `vllm-bench/run.sh` : start a benchmarck for one configuration
 - `vllm-bench/run_all.sh` : run benchmark for all configurations lsted in `models2benchmark`
 
 