#!/bin/bash
# please run in <GeneFace> root dir.

# Set build optimizations for faster compilation
export MAKEFLAGS="-j$(nproc)"
export CMAKE_BUILD_PARALLEL_LEVEL="$(nproc)"
export TORCH_CUDA_ARCH_LIST="6.0;6.1;7.0;7.5;8.0;8.6"
export FORCE_CUDA="1"
export MAX_JOBS="$(nproc)"

echo "Installing torch extensions with parallel compilation..."

# Install extensions with verbose output and error handling
for ext in freqencoder shencoder gridencoder raymarching; do
    echo "Installing $ext..."
    if pip install ./modules/radnerfs/encoders/$ext -v; then
        echo "✓ $ext installed successfully"
    else
        echo "✗ Failed to install $ext"
        exit 1
    fi
done

echo "All torch extensions installed successfully!"
