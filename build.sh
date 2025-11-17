#!/bin/sh

if [ ! -f /.dockerenv ]; then
    echo "Must be run from a container"
    exit -2
fi

CBD=`pwd`/out/build/linux-release-package
VER=`cat version.json | jq -r '."rocm-version"'`
VER_SUF=1

THEROCK_AMDGPU_TARGETS="gfx1100,gfx1103"
CMAKE_SOURCE_DIR=`pwd`
THEROCK_BINARY_DIR=`pwd`/out/build/linux-release-package

#cmake --build ${CBD}
#./build_tools/packaging/linux/build_package.py --artifacts-dir ${CBD}/artifacts --dest-dir `pwd`/out --pkg-type DEB --rocm-#version ${VER} --version-suffix ${VER_SUF} --target ${THEROCK_AMDGPU_FAMILIES}

#sudo apt install -y binutils-gold
#  --clang_path=${THEROCK_BINARY_DIR}/dist/rocm/lib/llvm/bin/clang \
cd ${CMAKE_SOURCE_DIR}/ml-libs/jax
python3 ${CMAKE_SOURCE_DIR}/ml-libs/jax/build/build.py build \
  --rocm_amdgpu_targets="${THEROCK_AMDGPU_TARGETS}" \
  --wheels=jaxlib,jax-rocm-plugin,jax-rocm-pjrt \
  --clang_path=/usr/bin/clang-18 \
  --local_xla_path=${CMAKE_SOURCE_DIR}/ml-libs/xla \
  --rocm_path=${THEROCK_BINARY_DIR}/dist/rocm \
  --rocm-device-lib-path=${THEROCK_BINARY_DIR}/dist/rocm/lib/llvm/amdgcn/bitcode \
  --rocm_version=70
