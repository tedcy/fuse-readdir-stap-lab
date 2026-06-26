#!/usr/bin/env bash
set -euo pipefail

. "${REPRO_ROOT:-$HOME/systemtap-readdir-repro}/repro-env.sh"

sudo apt-get install -y gcc-10 g++-10 binutils

ln -sfn "$(command -v gcc-10)" "$TOOLCHAIN_BIN/gcc-10"
ln -sfn "$(command -v g++-10)" "$TOOLCHAIN_BIN/g++-10"

for t in as ld objcopy objdump readelf strip ar nm ranlib; do
  ln -sfn "$(command -v "$t")" "$TOOLCHAIN_BIN/$t"
done

PATH="$TOOLCHAIN_BIN:$PATH" gcc-10 --version | head -1
PATH="$TOOLCHAIN_BIN:$PATH" as --version | head -1
PATH="$TOOLCHAIN_BIN:$PATH" ld --version | head -1

ELF_TAR=$SRC_ROOT/elfutils-0.195.tar.bz2
ELF_URL=${ELF_URL:-https://sourceware.org/elfutils/ftp/0.195/elfutils-0.195.tar.bz2}

test -s "$ELF_TAR" ||
  wget --no-check-certificate -q -O "$ELF_TAR" "$ELF_URL"

tar -C "$SRC_ROOT" -xf "$ELF_TAR"
mkdir -p "$BUILD_ROOT/elfutils-0.195"
cd "$BUILD_ROOT/elfutils-0.195"

"$SRC_ROOT/elfutils-0.195/configure" \
  --prefix="$ELFUTILS_HOME" \
  --disable-debuginfod

nice -n 15 make -j1
nice -n 15 make install

BOOST_DEB=$DEB_ROOT/libboost1.71-dev_1.71.0-6ubuntu6_amd64.deb
BOOST_URL=${BOOST_URL:-http://archive.ubuntu.com/ubuntu/pool/main/b/boost1.71/libboost1.71-dev_1.71.0-6ubuntu6_amd64.deb}

test -s "$BOOST_DEB" ||
  wget -q -O "$BOOST_DEB" "$BOOST_URL"

dpkg-deb -x "$BOOST_DEB" "$BOOST_ROOT"
test -e "$BOOST_ROOT/usr/include/boost/asio/thread_pool.hpp"

STAP_TAR=$SRC_ROOT/systemtap-5.5.tar.gz
STAP_URL=${STAP_URL:-https://sourceware.org/systemtap/ftp/releases/systemtap-5.5.tar.gz}

test -s "$STAP_TAR" ||
  wget --no-check-certificate -q -O "$STAP_TAR" "$STAP_URL"

tar -C "$SRC_ROOT" -xf "$STAP_TAR"
mkdir -p "$BUILD_ROOT/systemtap-5.5"
cd "$BUILD_ROOT/systemtap-5.5"

export PATH="$TOOLCHAIN_BIN:$PATH"
export CC="$TOOLCHAIN_BIN/gcc-10"
export CXX="$TOOLCHAIN_BIN/g++-10"
export PKG_CONFIG_PATH="$ELFUTILS_HOME/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export CPPFLAGS="-I$ELFUTILS_HOME/include -I$BOOST_ROOT/usr/include"
export LDFLAGS="-L$ELFUTILS_HOME/lib -Wl,-rpath,$ELFUTILS_HOME/lib"
export LD_LIBRARY_PATH="$ELFUTILS_HOME/lib:${LD_LIBRARY_PATH:-}"

"$SRC_ROOT/systemtap-5.5/configure" \
  --prefix="$STAP_HOME" \
  --without-nss \
  --without-avahi \
  --without-bpf \
  --disable-Werror

nice -n 15 make -j1 CXXFLAGS="-O0 -g0"
nice -n 15 make install CXXFLAGS="-O0 -g0"

