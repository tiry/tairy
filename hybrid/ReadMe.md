# Hybrid LLM Inference Architecture: AMD Strix Halo + NVIDIA eGPU

## Goal

See if I can find a way to leverage both the iGPU and the eGPU to run AI workload:

 - leverage large memory of AMD Strix Halo APU
 - the low-latency compute power of an NVIDIA eGPU


## Software Constraints: vLLM or **llama.cpp**

While **vLLM** is the industry standard for high-throughput serving, it is unsuitable for this specific hybrid hardware configuration.

**Single-Backend Architecture:** vLLM requires compiling against a specific hardware backend—either **CUDA** or **ROCm**. I am currently using a dedicated container for each.

**Lack of Heterogeneous Orchestration:** vLLM is designed for homogeneous clusters (e.g., 8x H100s). It lacks the logic to efficiently split a model between a high-bandwidth internal iGPU and a latency-constrained eGPU without significant custom engineering.

**Solution:** We utilize **llama.cpp** (via Vulkan or RPC), which offers the flexibility to address mixed-vendor hardware either through a unified graphics API or by splitting the model across separate processes.


## Hardware Limitations

### 1. The Interconnect Bottleneck
The eGPU connects via Thunderbolt/USB4, offering a bandwidth of roughly **40 Gbps** in the best case scenario (I probablu have less)
* **Impact:** This is orders of magnitude slower than internal PCIe lanes or NVLink.
* **Result:** Strategies relying on high-frequency synchronization (like **Tensor Parallelism**) are non-viable. Data transfer must be minimized to "per-layer" or "per-batch" operations.

### 2. The Compute vs. Memory Mismatch
* **AMD Strix Halo:** Excellent memory bandwidth and capacity, but lower raw FP16 compute (FLOPs) compared to high-end dedicated desktop GPUs.
* **NVIDIA 4070 Ti:** Excellent raw compute and latency, but insufficient memory to hold 70B+ parameter models.


## Experimentation 1: Speculative Decoding

This approach treats the GPUs as a hierarchy rather than peers, playing to their specific strengths.

* **The Concept:**
    Instead of waiting for the large model to generate tokens one by one (serial), we use the faster NVIDIA GPU to "predict" future tokens, which the AMD GPU then validates in parallel.
    
* **The Workflow:**
    1.  **Drafting (NVIDIA eGPU):** The low-latency NVIDIA card runs a small, fast model (e.g., 8B parameters). It rapidly "drafts" a sequence of 5–10 potential tokens.
    2.  **Verification (AMD Strix Halo):** The massive AMD APU receives this draft sequence. Leveraging its high memory bandwidth, it verifies all tokens in a single parallel forward pass.
    3.  **Result:** We achieve the intelligence of the 70B model with generation speeds approaching the 8B model.


## Experimentation 2 : Mixture of Experts

It would be great to be able to offload a few experts to the nvidia card.
