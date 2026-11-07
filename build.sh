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
#cmake --build --preset linux-release-package --target therock-jax
#cmake --build --preset linux-release-package --target therock-torch
#cmake --build --preset linux-release-package --target therock-deb
#cmake --build --preset linux-release-package --target therock-ppa


CMAKE_SOURCE_DIR=/mnt/workspace
THEROCK_BINARY_DIR=${CMAKE_SOURCE_DIR}/out/build/linux-release-package
ROCM_PATH=${THEROCK_BINARY_DIR}/dist/rocm
THEROCK_AMDGPU_TARGETS="gfx1100;gfx1103"
GPU_TARGETS_COMMAS="gfx1100,gfx1103"

## therock-torch
#cd ${CMAKE_SOURCE_DIR}/ml-libs/pytorch
#CMAKE_CUDA_COMPILER_LAUNCHER=ccache NUMA_DIR=${CMAKE_SOURCE_DIR}/cmake/finders ROCM_PATH=${THEROCK_BINARY_DIR}/dist/rocm PYTORCH_ROCM_ARCH="${THEROCK_AMDGPU_TARGETS}" USE_ROCM=ON USE_VULKAN=ON USE_CUDA=0 python3 -m build --wheel --no-isolation

## therock-jax
# From https://github.com/ROCm/jax/blob/amd-main/ci/build_rocm_artifacts.sh, dropped options:
#   --verbose --detailed_timestamped_log
#   --bazel_options=--override_repository=xla=${CMAKE_SOURCE_DIR}/ml-libs/xla --bazel_options=--override_module=xla=${CMAKE_SOURCE_DIR}/ml-libs/xla
# This one causes 'cannot call external function float /= from kernel':
#	--bazel_options=--repo_env=ROCM_PATH=${THEROCK_BINARY_DIR}/dist/rocm
cd ${CMAKE_SOURCE_DIR}/ml-libs/jax
sudo ln -sf ${THEROCK_BINARY_DIR}/dist/rocm /opt
mkdir -p ${THEROCK_BINARY_DIR}/jax.build
python3 build/build.py build --wheels=jax,jaxlib,jax-rocm-plugin,jax-rocm-pjrt --rocm_amdgpu_targets=${GPU_TARGETS_COMMAS} --bazel_startup_options="--bazelrc=build/rocm/rocm.bazelrc" --bazel_options=--config=rocm_release_wheel --python_version=3.13 --output_path=${THEROCK_BINARY_DIR}/jax.build --bazel_options=--repo_env=ML_WHEEL_TYPE=release --bazel_options=--repo_env=ROCM_PATH=${THEROCK_BINARY_DIR}/dist/rocm

## therock-deb
#/mnt/workspace/build_tools/packaging/linux/build_package.py --artifacts-dir /mnt/workspace/out/build/linux-release-package/artifacts --dest-dir /mnt/workspace/out/build/linux-release-package/apt-repo/pool/main --pkg-type DEB --rocm-version 10.1.0 --version-suffix 1 --target gfx110X-all

## Adaptive C++
#cd ${CMAKE_SOURCE_DIR}/compiler/AdaptiveCpp
#if [ ! -d ${THEROCK_BINARY_DIR}/acpp.build ]; then
#    cmake -B${THEROCK_BINARY_DIR}/acpp.build -DCMAKE_INSTALL_PREFIX=/opt/acpp -DROCM_PATH=${THEROCK_BINARY_DIR}/dist/rocm -DCPACK_GENERATOR=DEB -DGPU_TARGETS=${GPU_TARGETS_COMMAS} -DCMAKE_CXX_COMPILER=clang++-18 -DWITH_OPENCL_BACKEND=OFF
#fi
#cmake --build ${THEROCK_BINARY_DIR}/acpp.build --target package

## Adaptive C++
cd ${CMAKE_SOURCE_DIR}/compiler/AdaptiveCpp
if [ ! -d ${THEROCK_BINARY_DIR}/acpp.build ]; then
    cmake -B${THEROCK_BINARY_DIR}/acpp.build -DCMAKE_INSTALL_PREFIX=/opt/acpp -DROCM_PATH=${THEROCK_BINARY_DIR}/dist/rocm -DCPACK_GENERATOR=DEB -DGPU_TARGETS=${GPU_TARGETS_COMMAS} -DCMAKE_CXX_COMPILER=clang++-18 -DWITH_OPENCL_BACKEND=OFF
fi
#cmake --build ${THEROCK_BINARY_DIR}/acpp.build --target package
