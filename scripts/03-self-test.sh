#!/usr/bin/env bash
set -euo pipefail

. "${REPRO_ROOT:-$HOME/systemtap-readdir-repro}/repro-env.sh"

for p in \
  "$STAP_HOME/bin/stap" \
  "$ELFUTILS_HOME/lib" \
  "$TOOLCHAIN_BIN/gcc-10" \
  "$BT/Makefile" \
  "$BT/System.map"
do
  test -e "$p" || { echo "missing: $p"; exit 1; }
done

"$STAP_HOME/bin/stap" -V
PATH="$TOOLCHAIN_BIN:$PATH" gcc-10 --version | head -1

sudo env \
  PATH="$TOOLCHAIN_BIN:$STAP_HOME/bin:$PATH" \
  LD_LIBRARY_PATH="$ELFUTILS_HOME/lib:${LD_LIBRARY_PATH:-}" \
  "$STAP_HOME/bin/stap" -v -k \
  -r "$BT" \
  -B CC="$TOOLCHAIN_BIN/gcc-10" \
  -B KERNELRELEASE="$KREL" \
  -B KERNELVERSION="$KREL" \
  -B CONFIG_MODULE_SIG= \
  -B CONFIG_MODULE_SIG_ALL= \
  -B CFLAGS_MODULE="-DPKG_ABI=$PKG_ABI -DSTAPCONF_GET_USER_PAGES_REMOTE -DSTAPCONF_TASK_USER_REGSET_VIEW_EXPORTED -DSTAPCONF_SYNCHRONIZE_RCU -DSTAPCONF_PDE_DATA2 -DSTAPCONF_KERN_PATH -Wno-error -g0" \
  -e 'probe kprobe.function("__lock_page") {
        printf("lock_page pid=%d exec=%s\n", pid(), execname())
        exit()
      }'
