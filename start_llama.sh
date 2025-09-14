#!/usr/bin/env bash

#### VULKAN version

## gpt-oss-20b on Vulkan
# GGML_VULKAN_DEVICE=0 llama-amd \
#   -m ~/.lmstudio/models/lmstudio-community/gpt-oss-20b-GGUF/gpt-oss-20b-MXFP4.gguf \
#   -fa on \
#   -c 128000 \
#   --host 172.17.0.1 \
#   --port 8081 \
#   --grammar-file cline.gbnf &

# CUDA version

## devstral:20b on CUDA
CUDA_VISIBLE_DEVICES=0 llama-nvidia \
 -m ~/.lmstudio/models/lmstudio-community/Devstral-Small-2507-GGUF/Devstral-Small-2507-Q4_K_M.gguf \
 -fa on \
 -c 32000 \
 --host 0.0.0.0 \
 --port 8082 &

## gpt-oss-20b on CUDA
# CUDA_VISIBLE_DEVICES=0 llama-nvidia \
#   -m ~/.lmstudio/models/lmstudio-community/gpt-oss-20b-GGUF/gpt-oss-20b-MXFP4.gguf \
#   --grammar-file cline.gbnf \
#   --host 0.0.0.0 \
#   --port 8082 \
#   -c 128000 \
#   --flash-attn on &