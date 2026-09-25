#!/bin/sh
# Public bootstrap: no GitHub login, Go, Node, or Python required.
set -eu
repo='https://github.com/ConiferKit/stable-remake-releases/releases'
prefix="${STABLE_PREFIX:-$HOME/.local}"
shell_setup=1
key_setup=1
case "${STABLE_NO_LOGIN:-}" in 1|true|yes) key_setup=0;; esac
while [ "$#" -gt 0 ]; do
  case "$1" in
    --prefix) [ "$#" -ge 2 ] || { echo 'missing --prefix value' >&2; exit 2; }; prefix=$2; shift 2;;
    --no-shell) shell_setup=0; shift;;
    --no-login) key_setup=0; shift;;
    *) echo 'usage: install.sh [--prefix DIR] [--no-shell] [--no-login]' >&2; exit 2;;
  esac
done
case "$prefix" in /*) ;; *) echo 'installation prefix must be absolute' >&2; exit 2;; esac
case "$(uname -s)" in Darwin) platform=darwin;; Linux) platform=linux;; *) echo 'Stable supports macOS and Linux.' >&2; exit 1;; esac
case "$(uname -m)" in arm64|aarch64) arch=arm64;; x86_64|amd64) arch=amd64;; *) echo 'Stable supports arm64 and amd64.' >&2; exit 1;; esac
for tool in curl tar awk mktemp; do command -v "$tool" >/dev/null 2>&1 || { echo "Required tool missing: $tool" >&2; exit 1; }; done
work=$(mktemp -d "${TMPDIR:-/tmp}/stable-install.XXXXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
fetch() { curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error --retry 3 --connect-timeout 10 --max-time 180 "$1" -o "$2"; }
fetch "$repo/latest/download/VERSION" "$work/VERSION"
version=$(cat "$work/VERSION")
case "$version" in ''|*[!0-9A-Za-z._-]*) echo 'Invalid release version.' >&2; exit 1;; esac
name="stable-remake-$version-$platform-$arch"
base="$repo/download/v$version"
fetch "$base/SHA256SUMS" "$work/SHA256SUMS"
fetch "$base/$name.tar.gz" "$work/$name.tar.gz"
expected=$(awk -v file="$name.tar.gz" '$2 == file { print $1 }' "$work/SHA256SUMS")
case "$expected" in ''|*[!0-9a-f]*) echo 'Missing or invalid archive checksum.' >&2; exit 1;; esac
[ "${#expected}" -eq 64 ] || { echo 'Invalid checksum length.' >&2; exit 1; }
if command -v sha256sum >/dev/null 2>&1; then actual=$(sha256sum "$work/$name.tar.gz" | awk '{print $1}');
elif command -v shasum >/dev/null 2>&1; then actual=$(shasum -a 256 "$work/$name.tar.gz" | awk '{print $1}');
else echo 'sha256sum or shasum is required.' >&2; exit 1; fi
[ "$actual" = "$expected" ] || { echo 'Release checksum mismatch; installation unchanged.' >&2; exit 1; }
tar -xzf "$work/$name.tar.gz" -C "$work"
"$work/$name/stable" install --prefix "$prefix"
if [ "$shell_setup" -eq 1 ]; then "$prefix/bin/stable" shell install; fi
printf '\nStable %s installed at %s/bin/stable\n' "$version" "$prefix"
# curl | sh keeps stdin on the download pipe; the key prompt uses the
# terminal directly, and is skipped when there is none (CI, provisioning).
if [ "$key_setup" -eq 1 ] && ( : </dev/tty ) 2>/dev/null; then
  "$prefix/bin/stable" login --if-missing </dev/tty >/dev/tty 2>&1 || printf 'Conifer API key not saved; run: stable login\n'
elif ! "$prefix/bin/stable" login --if-missing </dev/null >/dev/null 2>&1; then
  printf 'Add a Conifer API key any time with: stable login\n'
fi
if [ "$shell_setup" -eq 1 ]; then
  printf 'Open a new terminal (or source your shell startup file), then run claude, codex, or pi as usual.\n'
else
  printf 'Add this to your shell configuration if needed: export PATH="%s/bin:$PATH"\n' "$prefix"
  printf 'Then run stable claude, stable codex, or stable pi.\n'
fi
printf 'Subscription execution has no Stable usage fee. Router decisions and explicitly selected API models are billed by the gateway.\n'
