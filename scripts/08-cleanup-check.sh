#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' '-- residual stap modules --'
cat /proc/modules | egrep '^(stap_|hello)' || true

printf '%s\n' '-- residual stap processes --'
ps -ef | grep -E 'stap|staprun' | grep -v grep || true

