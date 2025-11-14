#!/bin/sh

if [ ! -f /.dockerenv ]; then
    echo "Must be run from a container"
    exit -2
fi

CBD=`pwd`/out/build/linux-release-package
VER=`cat version.json | jq -r '."rocm-version"'`
VER_SUF=1

cmake --build ${CBD}
./build_tools/packaging/linux/build_package.py --artifacts-dir ${CBD}/artifacts --dest-dir `pwd`/out --pkg-type DEB --rocm-version ${VER} --version-suffix ${VER_SUF} --target ${THEROCK_AMDGPU_FAMILIES}
