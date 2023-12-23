#!/bin/sh

set -x

OPENSSL_VERSION=$1
ARCH=$2
PERFIX_DIR="/openssl-${ARCH}-linux-gnu"

mkdir -p "${PERFIX_DIR}" && \
    yum install -y openssl-devel ncurses-devel perl-IPC-Cmd python3 && \
    cd / && \
    curl -fSL https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -o openssl-${OPENSSL_VERSION}.tar.gz && \
    tar xf openssl-${OPENSSL_VERSION}.tar.gz && \
    cd openssl-${OPENSSL_VERSION} && \
    ./Configure --prefix="${PERFIX_DIR}" --openssldir="${PERFIX_DIR}" && make -j`nproc` && \
    make -j`nproc` install_sw && \
    make -j`nproc` install_ssldirs && \
    cd "/openssl-${ARCH}-linux-gnu" && \
    tar -czf "/work/openssl-${ARCH}-linux-gnu.tar.gz" .
