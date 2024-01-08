#!/bin/sh

set -x

OPENSSL_VERSION=$1
ARCH=$2
IMAGE_NAME=$3

sudo docker run --privileged --network=host --rm -v `pwd`:/work --platform=linux/$ARCH "${IMAGE_NAME}" \
    sh -c "chmod a+x /work/do-build-alpine.sh && /work/do-build-alpine.sh ${OPENSSL_VERSION} ${ARCH} ${ARCH}-linux-musl"
