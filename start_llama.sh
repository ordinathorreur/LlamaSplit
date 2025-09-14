#!/usr/bin/env bash

# Load configuration
source ./llama_config.env

#### VULKAN version

## gpt-oss-20b on Vulkan
# GGML_VULKAN_DEVICE=0 llama-amd \
#   -m "$VULKAN_MODEL_PATH" \
#   -fa on \
#   -c "$VULKAN_CONTEXT" \
#   --host "$VULKAN_HOST" \
#   --port "$VULKAN_PORT" \
#   --grammar-file "$VULKAN_GRAMMAR_FILE" &

# CUDA version

## devstral:20b on CUDA
CUDA_VISIBLE_DEVICES=0 llama-nvidia \
 -m "$CUDA_MODEL_PATH" \
 -fa on \
 -c "$CUDA_CONTEXT" \
 --host "$CUDA_HOST" \
 --port "$CUDA_PORT" &

## gpt-oss-20b on CUDA
# CUDA_VISIBLE_DEVICES=0 llama-nvidia \
#   -m "$CUDA_MODEL_PATH" \
#   --grammar-file "$CUDA_GRAMMAR_FILE" \
#   --host "$CUDA_HOST" \
#   --port "$CUDA_PORT" \
#   -c "$CUDA_CONTEXT" \
#   --flash-attn on &