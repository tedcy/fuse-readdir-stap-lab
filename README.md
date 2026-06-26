# fuse-readdir-stap-lab

SystemTap scripts and reproducible setup notes for debugging Linux FUSE cached
readdir loops. The lab was written for an Ubuntu 20.04 host running
`5.4.0-48-generic`, but most function-level scripts only require matching
kernel headers and a working SystemTap toolchain.

The field-level script reads FUSE cached readdir state directly from kernel
DWARF debug info. It therefore needs the exact matching Ubuntu dbgsym
`vmlinux`.

## What this lab checks

The scripts are split into two layers:

* Function-level SystemTap: checks whether `__lock_page`, `unlock_page`,
  `wake_up_page_bit`, `fuse_readdir`, and `fuse_readdir_uncached` are being hit.
* Field-level SystemTap: reads `fi->rdc.cached`, `fi->rdc.size`,
  `ff->readdir.cache_off`, page index, and the current `struct fuse_dirent`.

The field-level probe points are named P1 to P4 in
[`stap/field-readdir-15s.stp`](stap/field-readdir-15s.stp):

* P1 / `L502 cached_state`: cache state and reader position.
* P2 / `L539 before_parse`: page index and parse size before `fuse_parse_cache`.
* P3 / `L388 dirent`: current cached `struct fuse_dirent`.
* P4 / `L553 retry_before_align`: `cache_off` before retry alignment.

## Quick start

Run on the host whose running kernel should be inspected.

```bash
git clone git@github.com:tedcy/fuse-readdir-stap-lab.git
cd fuse-readdir-stap-lab

scripts/00-init-env.sh
scripts/01-prepare-kheaders.sh
scripts/02-build-systemtap-toolchain.sh
scripts/03-self-test.sh
```

Function-level checks do not need dbgsym:

```bash
scripts/04-run-function-level.sh lock-page
scripts/04-run-function-level.sh lock-wake
scripts/04-run-function-level.sh readdir-entry
```

Field-level checks need the exact matching dbgsym `vmlinux`:

```bash
scripts/05-prepare-dbgsym.sh
scripts/06-check-field-vars.sh

TARGET_READER_COMM=readdir_worker \
  scripts/07-run-field-readdir.sh
```

After testing:

```bash
scripts/08-cleanup-check.sh
```

## Important assumptions

The defaults match Ubuntu `5.4.0-48-generic` / package version `5.4.0-48.52`.
If you use another Ubuntu kernel, override these variables before running the
scripts:

```bash
export KREL=$(uname -r)
export KBASE=${KREL%-generic}
export UBUNTU_REV=$(uname -v | sed -n 's/^#\([0-9]\+\)-Ubuntu.*/\1/p')
export KPKGVER="$KBASE.$UBUNTU_REV"
export EXPECTED_BUILD_ID=
export DBGSYM_URL=
export EXPECTED_DDEB_SIZE=
```

The scripts compile and load SystemTap kernel modules. Secure Boot and kernel
lockdown must allow unsigned modules, and the running kernel, headers,
`System.map`, and dbgsym `vmlinux` must all match.

## File map

* `scripts/00-init-env.sh`: checks the target system, installs base packages,
  and writes `$HOME/systemtap-readdir-repro/repro-env.sh`.
* `scripts/01-prepare-kheaders.sh`: downloads Ubuntu kernel headers and writes
  `System.map` from `/proc/kallsyms`.
* `scripts/02-build-systemtap-toolchain.sh`: builds elfutils 0.195 and
  SystemTap 5.5, and prepares gcc/binutils wrappers.
* `scripts/03-self-test.sh`: runs a minimal `__lock_page` kprobe.
* `scripts/04-run-function-level.sh`: runs one of the function-level `.stp`
  scripts in `stap/`.
* `scripts/05-prepare-dbgsym.sh`: extracts a stripped Build ID baseline from
  `/boot/vmlinuz-*`, downloads dbgsym, and links unstripped `vmlinux` into the
  headers build tree.
* `scripts/06-check-field-vars.sh`: runs `stap -L` checks for the variables
  required by the field-level script.
* `scripts/07-run-field-readdir.sh`: runs the P1-P4 field-level script.
* `scripts/08-cleanup-check.sh`: checks for residual `stap_*` modules or
  `staprun` processes.

