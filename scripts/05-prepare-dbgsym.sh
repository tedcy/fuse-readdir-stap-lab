#!/usr/bin/env bash
set -euo pipefail

. "${REPRO_ROOT:-$HOME/systemtap-readdir-repro}/repro-env.sh"

BASE=${UBUNTU_LINUX_POOL:-http://archive.ubuntu.com/ubuntu/pool/main/l/linux}
KERNEL_SRC_WORK=$SRC_ROOT/kernel-source
SRC_DEB=$DEB_ROOT/linux-source-5.4.0_${KPKGVER}_all.deb
SRC_DEB_ROOT=$KERNEL_SRC_WORK/linux-source-deb-root
LINUX_SRC=$KERNEL_SRC_WORK/linux-source-5.4.0

mkdir -p "$KERNEL_SRC_WORK" "$SRC_DEB_ROOT"

test -s "$SRC_DEB" ||
  wget -q -O "$SRC_DEB" "$BASE/linux-source-5.4.0_${KPKGVER}_all.deb"

dpkg-deb -x "$SRC_DEB" "$SRC_DEB_ROOT"
tar -C "$KERNEL_SRC_WORK" \
  -xf "$SRC_DEB_ROOT/usr/src/linux-source-5.4.0/linux-source-5.4.0.tar.bz2"

EXTRACT_VMLINUX_SCRIPT=$LINUX_SRC/scripts/extract-vmlinux
test -x "$EXTRACT_VMLINUX_SCRIPT"

BOOT_VMLINUZ=/boot/vmlinuz-$KREL
VMLINUX_STRIPPED=$DBGSYM_ROOT/vmlinux-$KREL.stripped

printf 'KREL=%s\nBOOT_VMLINUZ=%s\nVMLINUX_STRIPPED=%s\n' \
  "$KREL" "$BOOT_VMLINUZ" "$VMLINUX_STRIPPED"

ls -lh "$BOOT_VMLINUZ" "$EXTRACT_VMLINUX_SCRIPT"
head -1 "$EXTRACT_VMLINUX_SCRIPT"

mkdir -p "$(dirname "$VMLINUX_STRIPPED")"
sudo "$EXTRACT_VMLINUX_SCRIPT" "$BOOT_VMLINUZ" > "$VMLINUX_STRIPPED"

file "$VMLINUX_STRIPPED"
readelf -n "$VMLINUX_STRIPPED" | grep -A2 'Build ID'
readelf -n "$VMLINUX_STRIPPED" | grep -q "$EXPECTED_BUILD_ID"

DDEB=$DBGSYM_ROOT/linux-image-unsigned-${KREL}-dbgsym_${KPKGVER}_amd64.ddeb
mkdir -p "$DBGSYM_ROOT"

curl -fL --connect-timeout 20 --retry 2 --retry-delay 3 \
  -o "$DDEB" "$DBGSYM_URL"

ls -lh "$DDEB"
stat -c '%s' "$DDEB"
test "$(stat -c '%s' "$DDEB")" = "$EXPECTED_DDEB_SIZE"
dpkg-deb -I "$DDEB" | sed -n '1,80p'

VMLINUX_DEBUG=$DBGSYM_ROOT/extract/usr/lib/debug/boot/vmlinux-$KREL
mkdir -p "$DBGSYM_ROOT/extract"

dpkg-deb --fsys-tarfile "$DDEB" |
  tar -C "$DBGSYM_ROOT/extract" -xf - ./usr/lib/debug/boot/vmlinux-$KREL

ln -sfn "$VMLINUX_DEBUG" "$BT/vmlinux"

ls -lh "$VMLINUX_DEBUG" "$BT/vmlinux"
file "$VMLINUX_DEBUG"
readelf -n "$VMLINUX_DEBUG" | grep -A2 'Build ID'
readelf -n "$VMLINUX_DEBUG" | grep -q "$EXPECTED_BUILD_ID"
readelf -S "$VMLINUX_DEBUG" | egrep 'debug_info|debug_line|symtab|strtab'

