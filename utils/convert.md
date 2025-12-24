

pip install mistral-common[image,audio]

# convert from HF to GGUF
python convert_hf_to_gguf.py --mistral-format ~/models/mistralai_Devstral-Small-2-24B-Instruct-2512 

# Quantize
build-rocm/bin/llama-quantize  ~/models/mistralai_Devstral-Small-2-24B-Instruct-2512-F16.gguf  ~/models/mistralai_Devstral-Small-2-24B-Instruct-2512-Q4_K_M.gguf Q4_K_M