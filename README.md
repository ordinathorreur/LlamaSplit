# Llama Server Management Scripts

This repository contains a collection of Bash scripts and configuration files for managing Llama-based AI servers. It supports both AMD Vulkan and NVIDIA CUDA backends, with options for dual-GPU setups.

## Project Structure

```
├── grammar/                  # Directory for grammar files
├── install_llama_dual.sh     # Script to build and install Llama for AMD and NVIDIA
├── list_llama_processes.sh   # Script to list running Llama processes with resource usage
├── llama_restart.log         # Log file for restart events
├── restart_llama.sh          # Script to restart Llama servers
├── start_llama.sh            # Script to start Llama servers
├── stop_llama.sh             # Script to stop Llama servers
```

## Scripts Overview

### Installation
- **install_llama_dual.sh**: Builds and installs Llama for both AMD Vulkan and NVIDIA CUDA backends. Includes optional systemd unit creation for managing servers.

### Server Management
- **start_llama.sh**: Starts the Llama servers. Configured for both AMD Vulkan and NVIDIA CUDA backends.
- **stop_llama.sh**: Stops all running Llama processes.
- **restart_llama.sh**: Restarts the Llama servers, ensuring all processes are terminated before starting new ones. Logs restart events to `llama_restart.log`.

### Monitoring
- **list_llama_processes.sh**: Lists running Llama processes with detailed resource usage (CPU, memory, GPU). Includes color-coded output for high resource usage.

## Usage

### Install Llama
Run the installation script to build and install Llama for your system:
```bash
./install_llama_dual.sh
```
Use the `--systemd` flag to create systemd units for managing the servers:
```bash
./install_llama_dual.sh --systemd
```

### Start Servers
Start the Llama servers:
```bash
./start_llama.sh
```

### Stop Servers
Stop all running Llama processes:
```bash
./stop_llama.sh
```

### Restart Servers
Restart the Llama servers:
```bash
./restart_llama.sh
```

### Monitor Processes
List running Llama processes and their resource usage:
```bash
./list_llama_processes.sh
```

## Logs
Restart events are logged in `llama_restart.log`.

## Dependencies
The installation script installs the required dependencies, including:
- Build tools: `cmake`, `gcc`, `make`
- Vulkan libraries: `libvulkan1`, `vulkan-tools`
- NVIDIA CUDA Toolkit (if available)

## Notes
- Place your model files in the directory specified during installation (default: `~/models/llama`).
- Update the `start_llama.sh` script to configure the model paths and server settings as needed.

### Configuration

Before starting the servers, configure the model paths, ports, and other settings in the `llama_config.sample.env` file. Copy this file to `llama_config.env` and update the values as needed. Here is an example:

```bash
# Vulkan configuration
VULKAN_DEVICE=0
VULKAN_MODEL_PATH=/path/to/vulkan/model/file.gguf
VULKAN_GRAMMAR_FILE=/path/to/vulkan/grammar/file.gbnf
VULKAN_HOST=127.0.0.1
VULKAN_PORT=8081
VULKAN_CONTEXT=128000

# CUDA configuration
CUDA_VISIBLE_DEVICES=0
CUDA_MODEL_PATH=/path/to/cuda/model/file.gguf
CUDA_GRAMMAR_FILE=/path/to/cuda/grammar/file.gbnf
CUDA_HOST=127.0.0.1
CUDA_PORT=8082
CUDA_CONTEXT=32000
```

Update these values to match your setup.

## License
This project is licensed under the MIT License.