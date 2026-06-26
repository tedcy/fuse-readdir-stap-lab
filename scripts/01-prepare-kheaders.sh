#!/usr/bin/env bash
set -euo pipefail

. "${REPRO_ROOT:-$HOME/systemtap-readdir-repro}/repro-env.sh"

BASE=${UBUNTU_LINUX_POOL:-http://archive.ubuntu.com/ubuntu/pool/main/l/linux}
HEADERS_COMMON=$DEB_ROOT/linux-headers-${KBASE}_${KPKGVER}_all.deb
HEADERS_FLAVOR=$DEB_ROOT/linux-headers-${KREL}_${KPKGVER}_amd64.deb

test -s "$HEADERS_COMMON" ||
  wget -q -O "$HEADERS_COMMON" \
    "$BASE/linux-headers-${KBASE}_${KPKGVER}_all.deb"

test -s "$HEADERS_FLAVOR" ||
  wget -q -O "$HEADERS_FLAVOR" \
    "$BASE/linux-headers-${KREL}_${KPKGVER}_amd64.deb"

dpkg-deb -x "$HEADERS_COMMON" "$KHEADERS_ROOT"
dpkg-deb -x "$HEADERS_FLAVOR" "$KHEADERS_ROOT"

sudo cat /proc/kallsyms > "$BT/System.map"

test -e "$BT/Makefile"
test -e "$BT/System.map"
ls -lh "$BT/Makefile" "$BT/System.map"

