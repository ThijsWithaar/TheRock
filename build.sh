#!/bin/sh

if [ ! -f /.dockerenv ]; then
    echo "Starting container..."
    ./build_tools/devcontainer.py ./build.sh
    exit 0
fi

CBD=`pwd`/out/build/linux-release-package
if [ ! -d ${CBD} ]; then
    cmake --preset linux-release-package
fi

cmake --build --verbose=1 --preset linux-release-package --target therock-deb

# The various stages of the build
#cmake --build --preset linux-release-package --target therock-dist
#cmake --build --preset linux-release-package --target therock-llama-cpp
#cmake --build ${CBD} --target therock-torch
#cmake --build ${CBD} --target therock-deb
#cmake --build ${CBD} --target therock-ppa


CMAKE_SOURCE_DIR=/mnt/workspace
THEROCK_BINARY_DIR=${CMAKE_SOURCE_DIR}/out/build/linux-release-package
THEROCK_AMDGPU_TARGETS="gfx1100;gfx1103"
GPU_TARGETS_COMMAS="gfx1100,gfx1103"

## therock-jax
#cd ${CMAKE_SOURCE_DIR}/ml-libs/jax
#python3 /mnt/workspace/ml-libs/jax/build/build.py build --rocm_amdgpu_targets=gfx1100,gfx1101,gfx1102,gfx1103 \
#	--wheels=jax,jaxlib,jax-rocm-plugin,jax-rocm-pjrt \
#	--rocm_path=/mnt/workspace/out/build/linux-release-package/dist/rocm \
#	--local_xla_path=/mnt/workspace/ml-libs/xla --rocm_version=101 \
#	--bazel_options=--repo_env=ML_WHEEL_TYPE=release

## therock-deb
#/mnt/workspace/build_tools/packaging/linux/build_package.py --artifacts-dir /mnt/workspace/out/build/linux-release-package/artifacts --dest-dir /mnt/workspace/out/build/linux-release-package/apt-repo/pool/main --pkg-type DEB --rocm-version 10.1.0 --version-suffix 1 --target gfx110X-all
