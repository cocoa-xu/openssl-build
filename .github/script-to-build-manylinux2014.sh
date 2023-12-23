#!/bin/sh

set -x

OPENSSL_VERSION=$1
ARCH=$2

ARCHIVE_FILE="openssl-${ARCH}.tar.gz"

sudo docker run --privileged --network=host --rm -v `pwd`:/work "quay.io/pypa/manylinux2014_$ARCH:latest" \
    sh -c "chmod a+x /work/do-build-manylinux2014.sh && /work/do-build-manylinux2014.sh ${OPENSSL_VERSION} ${ARCH}"

if [ -e "${ARCHIVE_FILE}" ]; then
  sudo chmod -R a+r "${ARCHIVE_FILE}" ;
fi
