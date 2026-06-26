#!/usr/bin/env bash
set -euo pipefail

sudo -n true

if command -v mokutil >/dev/null 2>&1; then
  mokutil --sb-state || true
  if mokutil --sb-state 2>/dev/null | grep -qi 'enabled'; then
    echo "Secure Boot is enabled; stop here or use a host that can load unsigned SystemTap modules."
    exit 1
  fi
fi

if test -e /sys/kernel/security/lockdown; then
  LOCKDOWN_STATE=$(cat /sys/kernel/security/lockdown)
  printf 'lockdown: %s\n' "$LOCKDOWN_STATE"
  if ! printf '%s\n' "$LOCKDOWN_STATE" | grep -q '\[none\]'; then
    echo "Kernel lockdown is active; stop here or use a host that can load SystemTap modules."
    exit 1
  fi
fi

cat /etc/os-release || true
uname -a
uname -r
uname -v
cat /proc/version

sudo apt-get update
sudo apt-get install -y \
  build-essential g++ make pkg-config bison flex gettext \
  python3 python3-distutils python3-setuptools \
  wget curl ca-certificates xz-utils tar bzip2 gzip \
  dpkg-dev dpkg binutils file coreutils sed gawk \
  libsqlite3-dev libjson-c-dev libcap-dev libreadline-dev \
  libncurses-dev zlib1g-dev libbz2-dev liblzma-dev

REPRO_ROOT=${REPRO_ROOT:-$HOME/systemtap-readdir-repro}
KREL=${KREL:-$(uname -r)}
KBASE=${KBASE:-${KREL%-generic}}
UBUNTU_REV=${UBUNTU_REV:-$(uname -v | sed -n 's/^#\([0-9]\+\)-Ubuntu.*/\1/p')}
KPKGVER=${KPKGVER:-$KBASE.$UBUNTU_REV}

mkdir -p "$REPRO_ROOT"

cat > "$REPRO_ROOT/repro-env.sh" <<EOF
export REPRO_ROOT=$REPRO_ROOT
export KREL=$KREL
export KBASE=$KBASE
export UBUNTU_REV=$UBUNTU_REV
export KPKGVER=$KPKGVER

export SRC_ROOT=\$REPRO_ROOT/src
export DEB_ROOT=\$REPRO_ROOT/debs
export BUILD_ROOT=\$REPRO_ROOT/build
export KHEADERS_ROOT=\$REPRO_ROOT/kernel-headers
export BT=\$KHEADERS_ROOT/usr/src/linux-headers-\$KREL

export STAP_HOME=\$REPRO_ROOT/systemtap-5.5
export ELFUTILS_HOME=\$REPRO_ROOT/elfutils-0.195
export BOOST_ROOT=\$REPRO_ROOT/boost-1.71
export TOOLCHAIN_ROOT=\$REPRO_ROOT/toolchain
export TOOLCHAIN_BIN=\$TOOLCHAIN_ROOT/bin

export DBGSYM_ROOT=\$REPRO_ROOT/dbgsym-\$KREL
export EXPECTED_BUILD_ID=\${EXPECTED_BUILD_ID:-d611be3cc02aff171910014d729c574e7cee5087}
export EXPECTED_DDEB_SIZE=\${EXPECTED_DDEB_SIZE:-963796624}
export DBGSYM_URL=\${DBGSYM_URL:-https://launchpadlibrarian.net/497048673/linux-image-unsigned-5.4.0-48-generic-dbgsym_5.4.0-48.52_amd64.ddeb}
EOF

. "$REPRO_ROOT/repro-env.sh"
mkdir -p "$SRC_ROOT" "$DEB_ROOT" "$BUILD_ROOT" \
  "$KHEADERS_ROOT" "$STAP_HOME" "$ELFUTILS_HOME" \
  "$BOOST_ROOT" "$TOOLCHAIN_BIN" "$DBGSYM_ROOT"

printf 'KREL=%s\nKBASE=%s\nUBUNTU_REV=%s\nKPKGVER=%s\n' \
  "$KREL" "$KBASE" "$UBUNTU_REV" "$KPKGVER"
printf 'REPRO_ROOT=%s\nBT=%s\nSTAP_HOME=%s\nELFUTILS_HOME=%s\nTOOLCHAIN_BIN=%s\nDBGSYM_ROOT=%s\n' \
  "$REPRO_ROOT" "$BT" "$STAP_HOME" "$ELFUTILS_HOME" "$TOOLCHAIN_BIN" "$DBGSYM_ROOT"

