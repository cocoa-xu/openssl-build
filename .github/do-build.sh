#!/bin/sh

set -x

OPENSSL_VERSION=$1
ARCH=$2
TRIPLET=$3
PERFIX_DIR="/openssl-${TRIPLET}"

case $TRIPLET in
    *-linux-gnu* )
         yum install -y openssl-devel ncurses-devel perl-IPC-Cmd python3
         ;;
    *-linux-musl* )
         apk add make curl gcc g++ perl linux-headers
         ;;
    * )
         echo "Unknown triplet: ${TRIPLET}"
         exit 1
         ;;
esac

mkdir -p "${PERFIX_DIR}" && \
    cd / && \
    curl -fSL https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -o openssl-${OPENSSL_VERSION}.tar.gz && \
    tar xf openssl-${OPENSSL_VERSION}.tar.gz && \
    cd openssl-${OPENSSL_VERSION} && \
    ./Configure --prefix="${PERFIX_DIR}" --openssldir="${PERFIX_DIR}" no-tests && \
    make -j`nproc` && \
    make -j`nproc` install_sw && \
    make -j`nproc` install_ssldirs && \
    cd "/openssl-${TRIPLET}" && \
    tar -czf "/work/openssl-${TRIPLET}.tar.gz" .