#!/usr/bin/env bash

# Load configuration
source ./llama_config.env

#### VULKAN version
if [ "$ENABLE_VULKAN" = true ]; then
  ## E.g. gpt-oss-20b on Vulkan
  llama-amd \
    -m "$VULKAN_MODEL_PATH" \
    -fa on \
    -c "$VULKAN_CONTEXT" \
    --host "$VULKAN_HOST" \
    --port "$VULKAN_PORT" \
    --grammar-file "$VULKAN_GRAMMAR_FILE" &
fi

#### CUDA version
if [ "$ENABLE_CUDA" = true ]; then
  ## E.g.devstral:20b on CUDA
  CUDA_VISIBLE_DEVICES=0 llama-nvidia \
    -m "$CUDA_MODEL_PATH" \
    -fa on \
    -c "$CUDA_CONTEXT" \
    --host "$CUDA_HOST" \
    --port "$CUDA_PORT" &
fi