#!/bin/sh

set -eux

OPENSSL_VERSION=$1
ARCH=$2
TRIPLET=$3
PERFIX_DIR="/openssl-${TRIPLET}"

case $TRIPLET in
  riscv64-linux-gnu )
    apt-get update && \
    apt-get install -y gcc g++ curl make automake autoconf libncurses5-dev perl python3
    ;;
  armv7l-linux-gnueabihf )
    apt-get update && \
    apt-get install -y gcc g++ curl make automake autoconf libncurses5-dev perl python3
    ;;
  *-linux-gnu )
    yum install -y curl automake autoconf openssl-devel ncurses-devel perl-IPC-Cmd python3
    if [ "${TRIPLET}" = "s390x-linux-gnu" ]; then
      yum install -y perl-App-cpanminus && \
      cpanm Math::BigInt ;
    fi
    ;;
  *-linux-musl )
    apk add make curl gcc g++ perl linux-headers
    ;;
  * )
    echo "Unknown triplet: ${TRIPLET}"
    exit 1
    ;;
esac

mkdir -p "${PERFIX_DIR}"
cd /
case $OPENSSL_VERSION in
  3.* )
    curl -fSL "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz" -o "openssl-${OPENSSL_VERSION}.tar.gz"
    ;;
  1.1.1* )
    curl -fSL "https://openssl.org/source/old/1.1.1/openssl-${OPENSSL_VERSION}.tar.gz" -o "openssl-${OPENSSL_VERSION}.tar.gz"
    ;;
  * )
    echo "Unknown version: ${OPENSSL_VERSION}"
    exit 1
    ;;
esac

tar -xf "openssl-${OPENSSL_VERSION}.tar.gz"
cd "openssl-${OPENSSL_VERSION}"

case $OPENSSL_VERSION in
  3.* )
    case $TRIPLET in
      *i386* | *i686* )
        ./Configure --prefix="${PERFIX_DIR}" --openssldir="${PERFIX_DIR}" no-tests linux-generic32 -m32
        ;;
      * )
        ./Configure --prefix="${PERFIX_DIR}" --openssldir="${PERFIX_DIR}" no-tests
        ;;
    esac
    ;;
  1.1.1* )
    case $TRIPLET in
      *i386* | *i686* )
        ./Configure --prefix="${PERFIX_DIR}" --openssldir="${PERFIX_DIR}" linux-generic32 -m32
        ;;
      * )
        ./Configure --prefix="${PERFIX_DIR}" --openssldir="${PERFIX_DIR}" linux-generic64
        ;;
    esac
    ;;
  * )
    echo "Unknown version: ${OPENSSL_VERSION}"
    exit 1
    ;;
esac

make -j$(nproc) && \
  make -j$(nproc) install_sw && \
  make -j$(nproc) install_ssldirs

cd "/openssl-${TRIPLET}"
tar -czf "/work/openssl-${TRIPLET}.tar.gz" .

cd /work
sha256sum "openssl-${TRIPLET}.tar.gz" | tee "openssl-${TRIPLET}.tar.gz.sha256"
