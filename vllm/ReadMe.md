

Bsed on documentation, I will assume:

| Container | Hardware / GPU | OpenAI API? | Chat | Vision/Audio |
| --- | --- | --- | --- | --- |
| `vllm/vllm-openai` | **NVIDIA GPU** (CUDA) | Y | Y | No (Text/Images only) |
| `vllm/vllm-tpu` | **Google TPU** (v4/v5e) | Y | Y | No (Text/Images only) |
| `vllm/vllm-omni` | **NVIDIA GPU** (CUDA) | Y | Y | Audio & Video |
| `vllm/vllm-omni-rocm` | **AMD GPU** (ROCm) | Y | Y | Audio & Video |




## NVida Setup

Fror Nvidia need to install kernels extensions

    sudo pacman -S nvidia-container-toolkit


Comfigure Docker

    sudo nvidia-ctk runtime configure --runtime=docker

    sudo systemctl restart docker

Test access

    docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi

## Rocm Setup

No system level extensions (but does not work)

Run test container

    docker run -it   --device /dev/kfd   --device /dev/dri   --group-add video   --ipc=host   --cap-add=SYS_PTRACE   --security-opt seccomp=unconfined   -e HSA_OVERRIDE_GFX_VERSION=11.0.0   rocm/dev-ubuntu-22.04   bash

From within container:

    root@90fdf6d8647c:/# amd-smi

    +------------------------------------------------------------------------------+
    | AMD-SMI 26.2.0+021c61fc      amdgpu version: Linuxver ROCm version: 7.1.1    |
    | VBIOS version: 00107962                                                      |
    | Platform: Linux Baremetal                                                    |
    |-------------------------------------+----------------------------------------|
    | BDF                        GPU-Name | Mem-Uti   Temp   UEC       Power-Usage |
    | GPU  HIP-ID  OAM-ID  Partition-Mode | GFX-Uti    Fan               Mem-Usage |
    |=====================================+========================================|
    | 0000:c2:00.0                 0x1586 | N/A        N/A   0             N/A/0 W |
    |   0       0     N/A             N/A | N/A        N/A           1013/65536 MB |
    +-------------------------------------+----------------------------------------+
    +------------------------------------------------------------------------------+
    | Processes:                                                                   |
    |  GPU        PID  Process Name          GTT_MEM  VRAM_MEM  MEM_USAGE     CU % |
    |==============================================================================|
    |  No running processes found                                                  |
    +------------------------------------------------------------------------------+


    root@90fdf6d8647c:/# rocm-smi


    WARNING: AMD GPU device(s) is/are in a low-power state. Check power control/runtime_status

    ======================================== ROCm System Management Interface ========================================
    ================================================== Concise Info ==================================================
    Device  Node  IDs              Temp    Power     Partitions          SCLK  MCLK  Fan  Perf  PwrCap  VRAM%  GPU%  
                  (DID,     GUID)  (Edge)  (Socket)  (Mem, Compute, ID)                                              
    ==================================================================================================================
    0       1     0x1586,   43175  49.0°C  10.029W   N/A, N/A, 0         N/A   N/A   0%   auto  N/A     1%     1%    
    ==================================================================================================================
    ============================================== End of ROCm SMI Log ===============================================


## Run Inference

### Rocm 


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
      vllm/vllm-omni-rocm:v0.12.0rc1 \
      vllm serve --model Qwen/Qwen2.5-7B-Instruct-1M

Debug

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
      vllm/vllm-omni-rocm:v0.12.0rc1 \
      bash


    vllm serve --model Qwen/Qwen2.5-7B-Instruct-1M


    TypeError: TritonAttentionImpl.__init__() got an unexpected keyword argument 'layer_idx'


    

    vllm bench throughput --model google/gemma-3-4b-it


Start VLLM Server

    vllm serve --model google/gemma-3-4b-it

Run benchmark

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


============ Serving Benchmark Result ============
Successful requests:                     3         
Failed requests:                         0         
Maximum request concurrency:             1         
Benchmark duration (s):                  39.01     
Total input tokens:                      45        
Total generated tokens:                  604       
Request throughput (req/s):              0.08      
Output token throughput (tok/s):         15.48     
Peak output token throughput (tok/s):    16.00     
Peak concurrent requests:                2.00      
Total Token throughput (tok/s):          16.64     
---------------Time to First Token----------------
Mean TTFT (ms):                          73.12     
Median TTFT (ms):                        72.91     
P99 TTFT (ms):                           73.66     
-----Time per Output Token (excl. 1st token)------
Mean TPOT (ms):                          64.47     
Median TPOT (ms):                        64.57     
P99 TPOT (ms):                           64.60     
---------------Inter-token Latency----------------
Mean ITL (ms):                           64.53     
Median ITL (ms):                         64.45     
P99 ITL (ms):                            66.18     
==================================================


vllm serve --model mistralai/Ministral-3-3B-Instruct-2512 \
  --tokenizer_mode mistral \
  --config_format mistral \
  --load_format mistral

No meaningful error
RuntimeError: Engine core initialization failed. See root cause above. Failed core proc(s): {}


vllm serve mistralai/Mistral-Nemo-Instruct-2407 \
    --tokenizer_mode mistral \
    --config_format mistral \
    --load_format mistral

    vllm bench serve --save-result --save-detailed \
      --backend vllm \
      --model mistralai/Mistral-Nemo-Instruct-2407 \
      --endpoint /v1/completions \
      --dataset-name custom \
      --dataset-path prompts.jsonl \
      --num-prompts 3 \
      --max-concurrency 1 \
      --temperature=0.3 \
      --top-p=0.75 \
      --result-dir "./log/"


============ Serving Benchmark Result ============
Successful requests:                     3         
Failed requests:                         0         
Maximum request concurrency:             1         
Benchmark duration (s):                  133.51    
Total input tokens:                      24        
Total generated tokens:                  531       
Request throughput (req/s):              0.02      
Output token throughput (tok/s):         3.98      
Peak output token throughput (tok/s):    4.00      
Peak concurrent requests:                2.00      
Total Token throughput (tok/s):          4.16      
---------------Time to First Token----------------
Mean TTFT (ms):                          262.70    
Median TTFT (ms):                        262.36    
P99 TTFT (ms):                           267.80    
-----Time per Output Token (excl. 1st token)------
Mean TPOT (ms):                          251.29    
Median TPOT (ms):                        251.14    
P99 TPOT (ms):                           251.62    
---------------Inter-token Latency----------------
Mean ITL (ms):                           251.36    
Median ITL (ms):                         251.08    
P99 ITL (ms):                            257.26    
==================================================




curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "google/gemma-3-4b-it",
    "messages": [
      {"role": "user", "content": "Who are you?"}
    ],
    "max_tokens": 50
  }'


docker run -d \
  --gpus all \
  --ipc=host \
  -p 8000:8000 \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  vllm/vllm-openai:latest \
# --- VLLM FLAGS START ---
  --model meta-llama/Meta-Llama-3-8B-Instruct \



  --gpu-memory-utilization 0.95 \
  --max-model-len 8192

docker run -d \
  --gpus all \
  --ipc=host \
  -p 8000:8000 \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  vllm/vllm-rocm:latest \
# --- VLLM FLAGS START ---
  --model mistralai/Ministral-3-3B-Instruct-2512 \


  --network=host \

  
mistralai/Ministral-3-3B-Instruct-2512 


--chat-template ./path-to-chat-template.jinja

docker run --rm -it \
  --device /dev/kfd \
  --device /dev/dri \
  --group-add video \
  --ipc=host \
  --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  -e HSA_OVERRIDE_GFX_VERSION=11.0.0 \
  rocm/dev-ubuntu-22.04 \
  rocm-smi