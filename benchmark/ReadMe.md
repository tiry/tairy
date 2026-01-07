

## Context

### Infrastructure

The underlying hardware for this benchmark is:

**Hardware:**

 - Framework Desktop AMD AI 395+ (Radeon 8060S)
 - eGPU Razer CoreX + NVidia RTX 4070Ti

**System**

    Arch Linux                           
    Kernel: Linux 6.18.2-arch2-1

**Nvidia:**

    NVIDIA-SMI 590.48.01              
    Driver Version: 590.48.01      
    CUDA Version: 13.1 

**AMD:**

    AMD-SMI 26.2.0+unknown       
    ROCm version: 7.1.1

### Inference engines

Benchmark done using 2 inference engine:

**llama.cpp**

Llama.cpp has been compiled 3 times: for Vulkan, Rocm and Cuda.

The build script is in [update-llamacpp.sh](../scripts/update-llamacpp.sh).
Then we use the wrapper [run-llamacpp.sh](../scripts/run-llamacpp.sh).

For example: to run llamacpp benchmark on rocm backend using Llama-3-8B-Instruct.Q5_K_M

    ./run-llamacpp.sh -m ~/models/Llama-3-8B-Instruct.Q5_K_M.gguf --benchmark -b rocm

**pytorch**

`pytorch` is run using [start-jupyter.sh](../notebooks/start-jupyter.sh).

Tests are run agains 2 kernels:

 - one CUDA kernel built using [mk_cuda.sh](../notebooks/mk-cuda.sh)
 - one Rocm kernel build using [mk_rocm.sh](../notebooks/mk-rocm.sh)


## Plots

### Driver/Backend comparison with llama.cpp

<img src="benchmark_comparison.png"></ing>

### llama.cpp vs pytorch

<img src="benchmark_inference_comparison.png"></ing>

## Raw Llama.cpp results

### AMD AI 395+ / Strix Halo

**Rocm:**

    Device 0: Radeon 8060S Graphics, gfx1151 (0x1151), VMM: no, Wave Size: 32

**Vulkan:**

    ggml_vulkan: 0 = Radeon 8060S Graphics (RADV GFX1151) (radv) | uma: 1 | fp16: 1 | bf16: 0 | warp size: 64 | shared memory: 65536 | int dot: 1 | matrix cores: KHR_coopmat


| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| llama 8B Q5_K - Medium         |   5.33 GiB |     8.03 B | ROCm       | 999 |           pp512 |       1084.19 ± 2.41 |
| llama 8B Q5_K - Medium         |   5.33 GiB |     8.03 B | Vulkan     | 999 |           pp512 |        619.09 ± 1.82 |
| llama 8B Q5_K - Medium         |   5.33 GiB |     8.03 B | ROCm       | 999 |           tg128 |         35.11 ± 0.05 |
| llama 8B Q5_K - Medium         |   5.33 GiB |     8.03 B | Vulkan     | 999 |           tg128 |         38.80 ± 0.07 |
| mistral3 14B Q5_K - Medium     |   8.95 GiB |    13.51 B | ROCm       | 999 |           pp512 |        694.17 ± 1.05 |
| mistral3 14B Q5_K - Medium     |   8.95 GiB |    13.51 B | Vulkan     | 999 |           pp512 |        335.40 ± 0.95 |
| mistral3 14B Q5_K - Medium     |   8.95 GiB |    13.51 B | ROCm       | 999 |           tg128 |         20.91 ± 0.01 |
| mistral3 14B Q5_K - Medium     |   8.95 GiB |    13.51 B | Vulkan     | 999 |           tg128 |         22.70 ± 0.04 |
| gemma3n E4B Q8_0               |   9.86 GiB |     6.87 B | ROCm       | 999 |           pp512 |       1310.28 ± 3.32 |
| gemma3n E4B Q8_0               |   9.86 GiB |     6.87 B | Vulkan     | 999 |           pp512 |                  N/A |
| gemma3n E4B Q8_0               |   9.86 GiB |     6.87 B | ROCm       | 999 |           tg128 |         25.66 ± 0.02 |
| gemma3n E4B Q8_0               |   9.86 GiB |     6.87 B | Vulkan     | 999 |           tg128 |                  N/A |
| mistral3 14B Q6_K              |  10.32 GiB |    13.51 B | ROCm       | 999 |           pp512 |        514.28 ± 0.56 |
| mistral3 14B Q6_K              |  10.32 GiB |    13.51 B | Vulkan     | 999 |           pp512 |        286.73 ± 0.63 |
| mistral3 14B Q6_K              |  10.32 GiB |    13.51 B | ROCm       | 999 |           tg128 |         18.91 ± 0.05 |
| mistral3 14B Q6_K              |  10.32 GiB |    13.51 B | Vulkan     | 999 |           tg128 |         19.73 ± 0.03 |
| mistral3 14B Q8_0              |  13.37 GiB |    13.51 B | ROCm       | 999 |           pp512 |        708.34 ± 0.89 |
| mistral3 14B Q8_0              |  13.37 GiB |    13.51 B | Vulkan     | 999 |           pp512 |        281.26 ± 0.56 |
| mistral3 14B Q8_0              |  13.37 GiB |    13.51 B | ROCm       | 999 |           tg128 |         15.19 ± 0.01 |
| mistral3 14B Q8_0              |  13.37 GiB |    13.51 B | Vulkan     | 999 |           tg128 |         15.64 ± 0.04 |


### NVidia 4070Ti

**CUDA:**

    Device 0: NVIDIA GeForce RTX 4070 Ti, compute capability 8.9, VMM: yes

**Vulkan:**

    ggml_vulkan: 0 = NVIDIA GeForce RTX 4070 Ti (NVIDIA) | uma: 0 | fp16: 1 | bf16: 1 | warp size: 32 | shared memory: 49152 | int dot: 1 | matrix cores: NV_coopmat2
    ggml_vulkan: 1 = Radeon 8060S Graphics (RADV GFX1151) (radv) | uma: 1 | fp16: 1 | bf16: 0 | warp size: 64 | shared memory: 65536 | int dot: 1 | matrix cores: KHR_coopmat

| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| llama 8B Q5_K - Medium         |   5.33 GiB |     8.03 B | CUDA       |  99 |           pp512 |       5350.57 ± 6.94 |
| llama 8B Q5_K - Medium         |   5.33 GiB |     8.03 B | Vulkan     | 999 |           pp512 |      4134.34 ± 83.79 |
| llama 8B Q5_K - Medium         |   5.33 GiB |     8.03 B | CUDA       |  99 |           tg128 |         79.34 ± 0.01 |
| llama 8B Q5_K - Medium         |   5.33 GiB |     8.03 B | Vulkan     | 999 |           tg128 |         78.82 ± 0.33 |
| mistral3 14B Q5_K - Medium     |   8.95 GiB |    13.51 B | CUDA       |  99 |           pp512 |       3298.67 ± 5.61 |
| mistral3 14B Q5_K - Medium     |   8.95 GiB |    13.51 B | Vulkan     | 999 |           pp512 |      2491.44 ± 12.13 |
| mistral3 14B Q5_K - Medium     |   8.95 GiB |    13.51 B | CUDA       |  99 |           tg128 |         47.24 ± 0.00 |
| mistral3 14B Q5_K - Medium     |   8.95 GiB |    13.51 B | Vulkan     | 999 |           tg128 |         45.96 ± 0.29 |
| gemma3n E4B Q8_0               |   9.86 GiB |     6.87 B | CUDA       |  99 |           pp512 |       5333.26 ± 2.49 |
| gemma3n E4B Q8_0               |   9.86 GiB |     6.87 B | Vulkan     | 999 |           pp512 |     4688.36 ± 100.02 |
| gemma3n E4B Q8_0               |   9.86 GiB |     6.87 B | CUDA       |  99 |           tg128 |         64.32 ± 0.02 |
| gemma3n E4B Q8_0               |   9.86 GiB |     6.87 B | Vulkan     | 999 |           tg128 |         60.26 ± 0.27 |
| mistral3 14B Q6_K              |  10.32 GiB |    13.51 B | CUDA       |  99 |           pp512 |       3037.02 ± 3.11 |
| mistral3 14B Q6_K              |  10.32 GiB |    13.51 B | Vulkan     | 999 |           pp512 |      2581.60 ± 13.32 |
| mistral3 14B Q6_K              |  10.32 GiB |    13.51 B | CUDA       |  99 |           tg128 |         41.40 ± 0.02 |
| mistral3 14B Q6_K              |  10.32 GiB |    13.51 B | Vulkan     | 999 |           tg128 |         40.23 ± 0.16 |
| mistral3 14B Q8_0              |  13.37 GiB |    13.51 B | CUDA       |  99 |           pp512 |                  N/A |
| mistral3 14B Q8_0              |  13.37 GiB |    13.51 B | Vulkan     | 999 |           pp512 |                  N/A |
| mistral3 14B Q8_0              |  13.37 GiB |    13.51 B | CUDA       |  99 |           tg128 |                  N/A |
| mistral3 14B Q8_0              |  13.37 GiB |    13.51 B | Vulkan     | 999 |           tg128 |                  N/A |

## Comparing Pytorch and llama.cpp

### Models selection and preparation

Llama.cpp runs GGUF models and allows to quantize then in various ways: this is what allowed testing `mistral3 14B Q6_K` or `mistral3 14B Q5_K - Medium`.
However, to my knowledge, when loading the model using pytorch, I can use BitsAndButes but only for Q4KM or Q8 quatization.

So, to run the comparison I selected 3 models:

 - mistralai/Ministral-3-3B-Instruct-2512 : run in BF16
 - mistralai/Ministral-3-8B-Instruct-2512 : run in Q8
 - mistralai/Ministral-3-14B-Instruct-2512 : run in Q4KM

These modesls were downloaded using [hf_download](../utils/hf_download.py)

    python hf_download.py -d ~/models/ mistralai/Ministral-3-3B-Instruct-2512
    python hf_download.py -d ~/models/ mistralai/Ministral-3-8B-Instruct-2512
    python hf_download.py -d ~/models/ mistralai/Ministral-3-14B-Instruct-2512

These models were converted to GGUF using the convert script from llama.cpp

    python convert_hf_to_gguf.py --mistral-format ~/models/mistralai_Ministral-3-3B-Instruct-2512/
    python convert_hf_to_gguf.py --mistral-format ~/models/mistralai_Ministral-3-8B-Instruct-2512/
    python convert_hf_to_gguf.py --mistral-format ~/models/mistralai_Ministral-3-14B-Instruct-2512/

Then the 8B and 14B models were quantized:

Q4KM for the 14B model

    build/bin/llama-quantize  ~/models/mistralai_Ministral-3-14B-Instruct-2512/mistralai_Ministral-3-14B-Instruct-2512-F16.gguf ~/models/mistralai_Ministral-3-14B-Instruct-2512-Q4KM.gguf Q4_K_M

Q8 for the 8B model

    build/bin/llama-quantize  ~/models/mistralai_Ministral-3-8B-Instruct-2512/mistralai_Ministral-3-8B-Instruct-2512-F16.gguf ~/models/mistralai_Ministral-3-8B-Instruct-2512-Q8_0.gguf Q8_0

NB: The Mistral 3 models for 8B and 14B are in FP8 by default, so it would have been more correct to download the `-BF16` variant, but I would expect this to be neutral on inference speed (even if doing quantization twice probably hurst quality).

### Running with llamap.cpp

#### 3B F16

**AMD**

    ./run-llamacpp.sh -m ~/models/mistralai_Ministral-3-3B-Instruct-2512-F16.gguf --benchmark -b rocm 

  Device 0: Radeon 8060S Graphics, gfx1151 (0x1151), VMM: no, Wave Size: 32
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| mistral3 3B F16                |   6.39 GiB |     3.43 B | ROCm       | 999 |           pp512 |       1975.80 ± 3.99 |
| mistral3 3B F16                |   6.39 GiB |     3.43 B | ROCm       | 999 |           tg128 |         28.92 ± 0.02 |

 
ggml_vulkan: 0 = Radeon 8060S Graphics (RADV GFX1151) (radv) | uma: 1 | fp16: 1 | bf16: 0 | warp size: 64 | shared memory: 65536 | int dot: 1 | matrix cores: KHR_coopmat
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| mistral3 3B F16                |   6.39 GiB |     3.43 B | Vulkan     | 999 |           pp512 |       1017.88 ± 3.32 |
| mistral3 3B F16                |   6.39 GiB |     3.43 B | Vulkan     | 999 |           tg128 |         27.86 ± 0.08 |

**Nvidia**

    ./run-llamacpp.sh -m ~/models/mistralai_Ministral-3-3B-Instruct-2512-F16.gguf --benchmark -b cuda

  Device 0: NVIDIA GeForce RTX 4070 Ti, compute capability 8.9, VMM: yes
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| mistral3 3B F16                |   6.39 GiB |     3.43 B | CUDA       |  99 |           pp512 |      9510.99 ± 25.43 |
| mistral3 3B F16                |   6.39 GiB |     3.43 B | CUDA       |  99 |           tg128 |         64.36 ± 0.01 |

    ./run-llamacpp.sh -m ~/models/mistralai_Ministral-3-3B-Instruct-2512-F16.gguf --benchmark -b vulkan

ggml_vulkan: 0 = NVIDIA GeForce RTX 4070 Ti (NVIDIA) | uma: 0 | fp16: 1 | bf16: 1 | warp size: 32 | shared memory: 49152 | int dot: 1 | matrix cores: NV_coopmat2
ggml_vulkan: 1 = Radeon 8060S Graphics (RADV GFX1151) (radv) | uma: 1 | fp16: 1 | bf16: 0 | warp size: 64 | shared memory: 65536 | int dot: 1 | matrix cores: KHR_coopmat
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| mistral3 3B F16                |   6.39 GiB |     3.43 B | Vulkan     | 999 |           pp512 |     9201.73 ± 163.56 |
| mistral3 3B F16                |   6.39 GiB |     3.43 B | Vulkan     | 999 |           tg128 |         62.31 ± 0.25 |

#### 8B Q8

**AMD**

    ./run-llamacpp.sh -m ~/models/mistralai_Ministral-3-8B-Instruct-2512-Q8_0.gguf --benchmark -b rocm 

  Device 0: Radeon 8060S Graphics, gfx1151 (0x1151), VMM: no, Wave Size: 32
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| mistral3 8B Q8_0               |   8.40 GiB |     8.49 B | ROCm       | 999 |           pp512 |       1100.50 ± 1.48 |
| mistral3 8B Q8_0               |   8.40 GiB |     8.49 B | ROCm       | 999 |           tg128 |         24.08 ± 0.01 |


    ./run-llamacpp.sh -m ~/models/mistralai_Ministral-3-8B-Instruct-2512-Q8_0.gguf --benchmark -b vulkan 

ggml_vulkan: 0 = Radeon 8060S Graphics (RADV GFX1151) (radv) | uma: 1 | fp16: 1 | bf16: 0 | warp size: 64 | shared memory: 65536 | int dot: 1 | matrix cores: KHR_coopmat
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| mistral3 8B Q8_0               |   8.40 GiB |     8.49 B | Vulkan     | 999 |           pp512 |        493.17 ± 0.85 |
| mistral3 8B Q8_0               |   8.40 GiB |     8.49 B | Vulkan     | 999 |           tg128 |         25.18 ± 0.03 |

**NVidia**

    ./run-llamacpp.sh -m ~/models/mistralai_Ministral-3-8B-Instruct-2512-Q8_0.gguf --benchmark -b cuda

  Device 0: NVIDIA GeForce RTX 4070 Ti, compute capability 8.9, VMM: yes
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| mistral3 8B Q8_0               |   8.40 GiB |     8.49 B | CUDA       |  99 |           pp512 |       5223.47 ± 5.97 |
| mistral3 8B Q8_0               |   8.40 GiB |     8.49 B | CUDA       |  99 |           tg128 |         51.70 ± 0.00 |

    ./run-llamacpp.sh -m ~/models/mistralai_Ministral-3-8B-Instruct-2512-Q8_0.gguf --benchmark -b vulkan

ggml_vulkan: 0 = NVIDIA GeForce RTX 4070 Ti (NVIDIA) | uma: 0 | fp16: 1 | bf16: 1 | warp size: 32 | shared memory: 49152 | int dot: 1 | matrix cores: NV_coopmat2
ggml_vulkan: 1 = Radeon 8060S Graphics (RADV GFX1151) (radv) | uma: 1 | fp16: 1 | bf16: 0 | warp size: 64 | shared memory: 65536 | int dot: 1 | matrix cores: KHR_coopmat
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| mistral3 8B Q8_0               |   8.40 GiB |     8.49 B | Vulkan     | 999 |           pp512 |      4037.69 ± 17.98 |
| mistral3 8B Q8_0               |   8.40 GiB |     8.49 B | Vulkan     | 999 |           tg128 |         51.05 ± 0.26 |


#### 14B Q4

**AMD**

    ./run-llamacpp.sh -m ~/models/mistralai_Ministral-3-14B-Instruct-2512-Q4KM.gguf --benchmark -b rocm 

  Device 0: Radeon 8060S Graphics, gfx1151 (0x1151), VMM: no, Wave Size: 32
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| mistral3 14B Q4_K - Medium     |   7.67 GiB |    13.51 B | ROCm       | 999 |           pp512 |        682.74 ± 0.61 |
| mistral3 14B Q4_K - Medium     |   7.67 GiB |    13.51 B | ROCm       | 999 |           tg128 |         23.57 ± 0.01 |

    ./run-llamacpp.sh -m ~/models/mistralai_Ministral-3-14B-Instruct-2512-Q4KM.gguf --benchmark -b vulkan

ggml_vulkan: 0 = Radeon 8060S Graphics (RADV GFX1151) (radv) | uma: 1 | fp16: 1 | bf16: 0 | warp size: 64 | shared memory: 65536 | int dot: 1 | matrix cores: KHR_coopmat
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| mistral3 14B Q4_K - Medium     |   7.67 GiB |    13.51 B | Vulkan     | 999 |           pp512 |        304.90 ± 0.34 |
| mistral3 14B Q4_K - Medium     |   7.67 GiB |    13.51 B | Vulkan     | 999 |           tg128 |         26.01 ± 0.04 |

**NVidia**

    ./run-llamacpp.sh -m ~/models/mistralai_Ministral-3-14B-Instruct-2512-Q4KM.gguf --benchmark -b cuda

  Device 0: NVIDIA GeForce RTX 4070 Ti, compute capability 8.9, VMM: yes
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| mistral3 14B Q4_K - Medium     |   7.67 GiB |    13.51 B | CUDA       |  99 |           pp512 |       3384.11 ± 4.92 |
| mistral3 14B Q4_K - Medium     |   7.67 GiB |    13.51 B | CUDA       |  99 |           tg128 |         54.12 ± 0.00 |

    ./run-llamacpp.sh -m ~/models/mistralai_Ministral-3-14B-Instruct-2512-Q4KM.gguf --benchmark -b vulkan

ggml_vulkan: 0 = NVIDIA GeForce RTX 4070 Ti (NVIDIA) | uma: 0 | fp16: 1 | bf16: 1 | warp size: 32 | shared memory: 49152 | int dot: 1 | matrix cores: NV_coopmat2
ggml_vulkan: 1 = Radeon 8060S Graphics (RADV GFX1151) (radv) | uma: 1 | fp16: 1 | bf16: 0 | warp size: 64 | shared memory: 65536 | int dot: 1 | matrix cores: KHR_coopmat
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| mistral3 14B Q4_K - Medium     |   7.67 GiB |    13.51 B | Vulkan     | 999 |           pp512 |      2764.02 ± 13.49 |
| mistral3 14B Q4_K - Medium     |   7.67 GiB |    13.51 B | Vulkan     | 999 |           tg128 |         52.59 ± 0.30 |


### Running in PyTorch

I was not able to rum Misrral Models via PyTorch and Rocm

    PyTorch Version: 2.11.0.dev20251230+rocm7.1
    ROCm Version:    7.1.52802
    transformers Version:    5.0.0rc1

    PyTorch Version: 2.11.0.dev20260105+rocm7.1
    ROCm Version:    7.1.52802
    transformers Version:    5.0.0rc1

The call to `model.generate` hangs forever: no errors visible at system or driver level.
Activating AMD logs lead to a flood of logs ...

#### 3B FP16

**NVidia**

Run from [Cuda-Inference-Mistral](../notebooks/notebooks/Cuda-Inference-Mistral.ipynb):

    Time to First Token: 0.0515 s
    Generation Speed:    39.84 tokens/sec
    Total Tokens:        300
    Model Parameters: 3.85 Billion
    Memory Footprint: 4.35 GB

#### 8B Q8

**NVidia**

Run from [Cuda-Inference-Mistral](../notebooks/notebooks/Cuda-Inference-Mistral.ipynb):

    Time to First Token: 0.4879 s
    Generation Speed:    25.03 tokens/sec
    Total Tokens:        300
    Model Parameters: 8.92 Billion
    Memory Footprint: 9.71 GB

#### 14B Q4

**Nvidia**

I was not able to load the 14B model into the 12GB of VRAM:

 - using the default FP8 model does not allow to do a 4bits quantization
 - using the FP16 model and then apply BitesAndBytes with 4Bits quantization does not fit even when trying to load in CPU first

