

## Running `llama.cpp` with ROCm

    ./run-llamacpp.sh -m ~/models/gemma-3-4b-it.fp16.gguf --benchmark -b rocm
    ./run-llamacpp.sh -m ~/models/Qwen3-4B-Instruct-2507-F16.gguf --benchmark -b rocm
    ./run-llamacpp.sh -m ~/models/Ministral-3-3B-Base-2512.f16.gguf --benchmark -b rocm
    ./run-llamacpp.sh -m ~/models/llama-Llama-3.2-3B-Instruct-F16.gguf --benchmark -b rocm


  Device 0: Radeon 8060S Graphics, gfx1151 (0x1151), VMM: no, Wave Size: 32
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| gemma3 4B F16                  |   7.23 GiB |     3.88 B | ROCm       | 999 |           pp512 |       2349.66 ± 5.94 |
| gemma3 4B F16                  |   7.23 GiB |     3.88 B | ROCm       | 999 |           tg128 |         26.22 ± 0.02 |
| qwen3 4B F16                   |   7.49 GiB |     4.02 B | ROCm       | 999 |           pp512 |       2032.71 ± 7.68 |
| qwen3 4B F16                   |   7.49 GiB |     4.02 B | ROCm       | 999 |           tg128 |         25.37 ± 0.02 |
| mistral3 3B F16                |   6.39 GiB |     3.43 B | ROCm       | 999 |           pp512 |       2106.81 ± 9.48 |
| mistral3 3B F16                |   6.39 GiB |     3.43 B | ROCm       | 999 |           tg128 |         29.22 ± 0.01 |
| llama 3B F16                   |   5.98 GiB |     3.21 B | ROCm       | 999 |           pp512 |       1745.22 ± 7.47 |
| llama 3B F16                   |   5.98 GiB |     3.21 B | ROCm       | 999 |           tg128 |         31.15 ± 0.02 |

## Running `llama.cpp` with CUDA


    ./run-llamacpp.sh -m ~/models/gemma-3-4b-it.fp16.gguf --benchmark -b cuda
    ./run-llamacpp.sh -m ~/models/Qwen3-4B-Instruct-2507-F16.gguf --benchmark -b cuda
    ./run-llamacpp.sh -m ~/models/Ministral-3-3B-Base-2512.f16.gguf --benchmark -b cuda
    ./run-llamacpp.sh -m ~/models/llama-Llama-3.2-3B-Instruct-F16.gguf --benchmark -b cuda

| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| gemma3 4B F16                  |   7.23 GiB |     3.88 B | CUDA       |  99 |           pp512 |      8769.01 ± 18.78 |
| gemma3 4B F16                  |   7.23 GiB |     3.88 B | CUDA       |  99 |           tg128 |         56.04 ± 0.00 |
| qwen3 4B F16                   |   7.49 GiB |     4.02 B | CUDA       |  99 |           pp512 |      7495.51 ± 10.10 |
| qwen3 4B F16                   |   7.49 GiB |     4.02 B | CUDA       |  99 |           tg128 |         54.80 ± 0.00 |
| mistral3 3B F16                |   6.39 GiB |     3.43 B | CUDA       |  99 |           pp512 |      9512.68 ± 26.68 |
| mistral3 3B F16                |   6.39 GiB |     3.43 B | CUDA       |  99 |           tg128 |         64.38 ± 0.02 |
| llama 3B F16                   |   5.98 GiB |     3.21 B | CUDA       |  99 |           pp512 |     10070.49 ± 38.20 |
| llama 3B F16                   |   5.98 GiB |     3.21 B | CUDA       |  99 |           tg128 |         69.13 ± 0.02 |
