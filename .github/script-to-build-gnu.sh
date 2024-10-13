#!/bin/sh

set -eux

OPENSSL_VERSION=$1
ARCH=$2
IMAGE_NAME=$3
DOCKER_PLATFORM=$4

TARGET="${ARCH}-linux-gnu"
if [ "${ARCH}" = "armv7l" ]; then
  TARGET="armv7l-linux-gnueabihf"
fi

if [ ! -z "${DOCKER_PLATFORM}" ]; then
  sudo docker run --privileged --network=host --rm -v $(pwd):/work --platform="${DOCKER_PLATFORM}" "${IMAGE_NAME}" \
    sh -c "chmod a+x /work/do-build.sh && /work/do-build.sh ${OPENSSL_VERSION} ${ARCH} ${TARGET}"
else
  sudo docker run --privileged --network=host --rm -v $(pwd):/work "${IMAGE_NAME}" \
    sh -c "chmod a+x /work/do-build.sh && /work/do-build.sh ${OPENSSL_VERSION} ${ARCH} ${TARGET}"
fi
