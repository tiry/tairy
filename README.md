# tairy

Code and results for testing GPU configurations, mainly for AI workloads (LLM inference, Image Generation, Fine Tuning) but also unrelated workloads like video compression tasks.

## System Configuration

**Hardware:**
- [Framework Desktop](https://frame.work/desktop?tab=specs) with AMD Ryzen™ AI Max+ 395
- NVIDIA RTX 4070 Ti connected as eGPU via Razer Core X

**GPUs Tested:**
- AMD Radeon 8060S (integrated in Ryzen™ AI Max+ 395)
- NVIDIA RTX 4070 Ti (eGPU)

**Backends:**
- CUDA (NVIDIA)
- ROCm (AMD)
- Vulkan (both GPUs)

## Repository Structure

- **`benchmark/`** - LLM inference benchmarks and performance comparisons using llama.cpp
- **`scripts/`** - Helper scripts for building and running llama.cpp and other tools
- **`notebooks/`** - Jupyter notebooks for various AI experiments
- **`utils/`** - Utility scripts for model conversion and downloads
- **`install/`** - Installation guides and setup documentation
- **`vllm/`** - Installation guides and and benchmarks using vllm


## Benchmarks

See [`benchmark/`](benchmark/) for LLM inference performance comparisons across different backends and GPUs.
