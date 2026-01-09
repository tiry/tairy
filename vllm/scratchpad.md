
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


vllm serve mistralai/Ministral-3-14B-Instruct-2512 \
  --tokenizer_mode mistral --config_format mistral --load_format mistral \
  --enable-auto-tool-choice --tool-call-parser mistral

No meaningful error
RuntimeError: Engine core initialization failed. See root cause above. Failed core proc(s): {}

vllm serve mistralai/Mistral-Small-Instruct-2409\
  --tokenizer_mode mistral --config_format mistral --load_format mistral \
  --enable-auto-tool-choice --tool-call-parser mistral


   vllm bench serve --save-result --save-detailed \
      --backend vllm \
      --model mistralai/Mistral-Small-Instruct-2409 \
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
Benchmark duration (s):                  350.85    
Total input tokens:                      24        
Total generated tokens:                  526       
Request throughput (req/s):              0.01      
Output token throughput (tok/s):         1.50      
Peak output token throughput (tok/s):    2.00      
Peak concurrent requests:                2.00      
Total Token throughput (tok/s):          1.57      
---------------Time to First Token----------------
Mean TTFT (ms):                          701.68    
Median TTFT (ms):                        698.10    
P99 TTFT (ms):                           709.25    
-----Time per Output Token (excl. 1st token)------
Mean TPOT (ms):                          666.82    
Median TPOT (ms):                        666.85    
P99 TPOT (ms):                           666.95    
---------------Inter-token Latency----------------
Mean ITL (ms):                           666.81    
Median ITL (ms):                         667.42    
P99 ITL (ms):                            681.52    
==================================================

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

vllm serve meta-llama/Llama-3.1-8B-Instruct

    vllm bench serve --save-result --save-detailed \
      --backend vllm \
      --model meta-llama/Llama-3.1-8B-Instruct \
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
Benchmark duration (s):                  162.69    
Total input tokens:                      123       
Total generated tokens:                  703       
Request throughput (req/s):              0.02      
Output token throughput (tok/s):         4.32      
Peak output token throughput (tok/s):    5.00      
Peak concurrent requests:                2.00      
Total Token throughput (tok/s):          5.08      
---------------Time to First Token----------------
Mean TTFT (ms):                          238.21    
Median TTFT (ms):                        235.03    
P99 TTFT (ms):                           251.65    
-----Time per Output Token (excl. 1st token)------
Mean TPOT (ms):                          231.38    
Median TPOT (ms):                        231.41    
P99 TPOT (ms):                           231.43    
---------------Inter-token Latency----------------
Mean ITL (ms):                           231.39    
Median ITL (ms):                         231.37    
P99 ITL (ms):                            236.49    
==================================================

vllm serve RedHatAI/Meta-Llama-3.1-8B-Instruct-FP8 => fail


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