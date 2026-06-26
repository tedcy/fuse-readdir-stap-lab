#!/usr/bin/env bash
set -euo pipefail

. "${REPRO_ROOT:-$HOME/systemtap-readdir-repro}/repro-env.sh"

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TARGET_READER_COMM=${TARGET_READER_COMM:-readdir_worker}
WORK=$DBGSYM_ROOT
STP_TEMPLATE=$REPO_ROOT/stap/field-readdir-15s.stp
STP_WORK=$WORK/field-readdir-15s.stp

test -e "$BT/vmlinux"
mkdir -p "$WORK"

sed "s/@TARGET_READER_COMM@/$TARGET_READER_COMM/g" \
  "$STP_TEMPLATE" > "$STP_WORK"

sudo env \
  PATH="$TOOLCHAIN_BIN:$STAP_HOME/bin:$PATH" \
  LD_LIBRARY_PATH="$ELFUTILS_HOME/lib:${LD_LIBRARY_PATH:-}" \
  "$STAP_HOME/bin/stap" -q \
  -r "$BT" \
  -B CC="$TOOLCHAIN_BIN/gcc-10" \
  -B KERNELRELEASE="$KREL" \
  -B KERNELVERSION="$KREL" \
  -B CONFIG_MODULE_SIG= \
  -B CONFIG_MODULE_SIG_ALL= \
  -B CFLAGS_MODULE='-DPKG_ABI=48 -DSTAPCONF_GET_USER_PAGES_REMOTE -DSTAPCONF_TASK_USER_REGSET_VIEW_EXPORTED -DSTAPCONF_SYNCHRONIZE_RCU -DSTAPCONF_PDE_DATA2 -DSTAPCONF_KERN_PATH -Wno-error -g0' \
  "$STP_WORK"

