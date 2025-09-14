#!/usr/bin/env bash
# Build llama.cpp for AMD Vulkan + NVIDIA CUDA, install wrappers, optional systemd units.
set -euo pipefail

# --- Settings (override via env or flags) ---
LLAMA_DIR="${LLAMA_DIR:-$HOME/src/llama.cpp}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
MODEL_DIR="${MODEL_DIR:-$HOME/models/llama}"
VULKAN_BUILD="$LLAMA_DIR/build-vulkan"
CUDA_BUILD="$LLAMA_DIR/build-cuda"
LLAMA_REMOTE="${LLAMA_REMOTE:-https://github.com/ggml-org/llama.cpp}"
LLAMA_COMMIT="${LLAMA_COMMIT:-master}"   # pin a hash for reproducible builds
CREATE_SYSTEMD=0

usage(){ echo "Usage: $0 [--systemd] [--commit <hash>]"; exit 1; }
while [[ "${1:-}" != "" ]]; do
  case "$1" in
    --systemd) CREATE_SYSTEMD=1 ;;
    --commit) shift; LLAMA_COMMIT="${1:-master}" ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1"; usage ;;
  esac
  shift || true
done

mkdir -p "$BIN_DIR" "$MODEL_DIR" "$HOME/scripts" "$(dirname "$LLAMA_DIR")"

echo "[1/6] Installing dependencies"
sudo add-apt-repository -y universe || true
sudo apt update
sudo apt install -y \
  build-essential cmake ccache git pkg-config \
  libcurl4-openssl-dev \
  libvulkan1 libvulkan-dev vulkan-tools mesa-vulkan-drivers \
  spirv-tools spirv-headers glslang-tools glslc \
  nvidia-cuda-toolkit

# Detect CUDA
if command -v nvcc >/dev/null 2>&1 || command -v nvidia-smi >/dev/null 2>&1; then
  HAVE_CUDA=1
  echo "[info] NVIDIA driver/toolkit detected -> will build CUDA target"
else
  HAVE_CUDA=0
  echo "[info] NVIDIA CUDA not detected -> skipping CUDA build (install CUDA to enable)"
fi

echo "[2/6] Cloning/updating llama.cpp @ $LLAMA_COMMIT"
if [ -d "$LLAMA_DIR/.git" ]; then
  git -C "$LLAMA_DIR" fetch --all --tags
else
  git clone "$LLAMA_REMOTE" "$LLAMA_DIR"
fi
git -C "$LLAMA_DIR" checkout "$LLAMA_COMMIT" || true
git -C "$LLAMA_DIR" pull --ff-only || true

echo "[3/6] Building Vulkan backend (AMD path)"
cmake -S "$LLAMA_DIR" -B "$VULKAN_BUILD" -DGGML_VULKAN=ON
cmake --build "$VULKAN_BUILD" -j

if [ "$HAVE_CUDA" -eq 1 ]; then
  echo "[4/6] Building CUDA backend (NVIDIA path)"
  cmake -S "$LLAMA_DIR" -B "$CUDA_BUILD" -DGGML_CUDA=ON
  cmake --build "$CUDA_BUILD" -j
else
  echo "[4/6] Skipping CUDA build"
fi

echo "[5/6] Installing wrapper scripts to $BIN_DIR"

# Helper to write an auto-detecting server runner
write_server_wrapper() {
  local path="$1"
  local bin_dir="$2"
  local pre_env="$3"   # lines to export/unset env before exec
  cat > "$path" <<EOF
#!/usr/bin/env bash
set -euo pipefail
$pre_env
BIN="$bin_dir"
: "\${GGML_VULKAN_DEVICE:=0}"
exe=""
for cand in llama-serve llama-server server; do
  if [ -x "\$BIN/\$cand" ]; then exe="\$BIN/\$cand"; break; fi
done
if [ -z "\$exe" ]; then
  echo "Error: no server binary found in \$BIN (tried llama-serve, llama-server, server)" >&2
  echo "Tip: rebuild Vulkan/CUDA targets." >&2
  exit 1
fi
exec "\$exe" -ngl 999 "\$@"
EOF
  chmod +x "$path"
}

# AMD (Vulkan) wrappers — pin to RADV ICD so AMD appears even when NVIDIA is primary
write_server_wrapper "$BIN_DIR/llama-amd" "$VULKAN_BUILD/bin" \
'export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json'

cat > "$BIN_DIR/llama-amd-cli" <<"EOF"
#!/usr/bin/env bash
set -euo pipefail
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json
: "${GGML_VULKAN_DEVICE:=0}"
exec "$HOME/src/llama.cpp/build-vulkan/bin/llama-cli" "$@"
EOF
chmod +x "$BIN_DIR/llama-amd-cli"

cat > "$BIN_DIR/llama-amd-list" <<"EOF"
#!/usr/bin/env bash
set -euo pipefail
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json
exec "$HOME/src/llama.cpp/build-vulkan/bin/llama-cli" --list-devices
EOF
chmod +x "$BIN_DIR/llama-amd-list"

# NVIDIA (CUDA) wrappers — unset ICD pin
if [ "$HAVE_CUDA" -eq 1 ]; then
  write_server_wrapper "$BIN_DIR/llama-nvidia" "$CUDA_BUILD/bin" 'unset VK_ICD_FILENAMES'
  cat > "$BIN_DIR/llama-nvidia-cli" <<"EOF"
#!/usr/bin/env bash
set -euo pipefail
unset VK_ICD_FILENAMES
exec "$HOME/src/llama.cpp/build-cuda/bin/llama-cli" "$@"
EOF
  chmod +x "$BIN_DIR/llama-nvidia-cli"
fi

# Add ~/.local/bin to PATH if missing
if ! grep -q "$BIN_DIR" <<< "$PATH"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
  echo "[info] Added $BIN_DIR to PATH (restart your shell)"
fi

# Optional systemd user units
if [ "$CREATE_SYSTEMD" -eq 1 ]; then
  echo "[6/6] Creating user systemd units"
  mkdir -p "$HOME/.config/systemd/user"

  cat > "$HOME/.config/systemd/user/llama-amd.service" <<'EOF'
[Unit]
Description=llama.cpp AMD Vulkan server

[Service]
Environment=VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json
Environment=GGML_VULKAN_DEVICE=0
ExecStart=%h/.local/bin/llama-amd -m %h/models/llama/amd-model.gguf -c 4096 --host 127.0.0.1 --port 8081
Restart=always

[Install]
WantedBy=default.target
EOF

  if [ "$HAVE_CUDA" -eq 1 ]; then
    cat > "$HOME/.config/systemd/user/llama-nvidia.service" <<'EOF'
[Unit]
Description=llama.cpp NVIDIA CUDA server

[Service]
Environment=VK_ICD_FILENAMES=
Environment=CUDA_VISIBLE_DEVICES=0
ExecStart=%h/.local/bin/llama-nvidia -m %h/models/llama/nvidia-model.gguf -c 4096 --host 127.0.0.1 --port 8082
Restart=always

[Install]
WantedBy=default.target
EOF
  fi

  systemctl --user daemon-reload
  systemctl --user enable llama-amd.service
  [ "$HAVE_CUDA" -eq 1 ] && systemctl --user enable llama-nvidia.service || true

  echo "[ok] Units created. Start with:"
  echo "  systemctl --user start llama-amd"
  [ "$HAVE_CUDA" -eq 1 ] && echo "  systemctl --user start llama-nvidia"
else
  echo "[6/6] Skipping systemd units (pass --systemd to create)"
fi

echo
echo "[done] Builds:"
echo "  $VULKAN_BUILD  (Vulkan)"
[ "$HAVE_CUDA" -eq 1 ] && echo "  $CUDA_BUILD    (CUDA)"
echo "[wrappers] llama-amd{,-cli,-list}"
[ "$HAVE_CUDA" -eq 1 ] && echo "[wrappers] llama-nvidia{,-cli}"
echo "[models]   Put GGUF files in: $MODEL_DIR"
echo
echo "[tip] AMD device index:"
echo "  llama-amd-list"
echo "  GGML_VULKAN_DEVICE=<idx> llama-amd -m ~/models/llama/amd-model.gguf --port 8081"
[ "$HAVE_CUDA" -eq 1 ] && echo "  CUDA_VISIBLE_DEVICES=0 llama-nvidia -m ~/models/llama/nvidia-model.gguf --port 8082"
