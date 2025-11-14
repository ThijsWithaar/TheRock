#!/bin/bash
set -e

do_hash() {
    HASH_NAME=$1
    HASH_CMD=$2
    echo "${HASH_NAME}:"
    for f in $(find -type f); do
        f=$(echo $f | cut -c3-) # remove ./ prefix
        if [ "$f" = "Release" ]; then
            continue
        fi
        echo " $(${HASH_CMD} ${f}  | cut -d" " -f1) $(wc -c $f)"
    done
}

# Date
BUILD_DATE="$(date --utc --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" -Ru)"

# Get OS codename
. /etc/os-release

# Get architecture, https://askubuntu.com/a/804654
ARCH=$(uname -m)
if [[ "$ARCH" == x86_64* ]]; then
  ARCH="amd64"
elif [[ "$ARCH" == i*86 ]]; then
  ARCH="i386"
elif  [[ "$ARCH" == armv8* ]]; then
  echo "arm64"
elif  [[ "$ARCH" == arm* ]]; then
  echo "arm"
fi

cat << EOF
Origin: ROCM Repository
Label: ROCM
Suite: stable
Codename: ${VERSION_CODENAME}
Date: ${BUILD_DATE}
Architectures: ${ARCH}
Components: main
Description: ROCm Repository
EOF
do_hash "MD5Sum" "md5sum"
do_hash "SHA1" "sha1sum"
do_hash "SHA256" "sha256sum"
