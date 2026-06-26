#!/usr/bin/env bash
set -euo pipefail

. "${REPRO_ROOT:-$HOME/systemtap-readdir-repro}/repro-env.sh"

test -e "$BT/vmlinux"

export LD_LIBRARY_PATH="$ELFUTILS_HOME/lib:${LD_LIBRARY_PATH:-}"
export PATH="$TOOLCHAIN_BIN:$STAP_HOME/bin:$PATH"

COMMON_STAP_ARGS="-r $BT \
  -B KERNELRELEASE=$KREL \
  -B KERNELVERSION=$KREL"

"$STAP_HOME/bin/stap" $COMMON_STAP_ARGS \
  -L 'kernel.function("fuse_parse_cache")'

"$STAP_HOME/bin/stap" $COMMON_STAP_ARGS \
  -L 'kernel.statement("fuse_readdir_cached@fs/fuse/readdir.c:502")'

"$STAP_HOME/bin/stap" $COMMON_STAP_ARGS \
  -L 'kernel.statement("fuse_readdir_cached@fs/fuse/readdir.c:539")'

"$STAP_HOME/bin/stap" $COMMON_STAP_ARGS \
  -L 'kernel.statement("fuse_parse_cache@fs/fuse/readdir.c:388")'

"$STAP_HOME/bin/stap" $COMMON_STAP_ARGS \
  -L 'kernel.statement("fuse_readdir@fs/fuse/readdir.c:502")'

