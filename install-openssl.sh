#!/usr/bin/env bash
# Resolve an OpenSSL version requirement and download the matching precompiled
# build from the cocoa-xu/openssl-build releases, optionally installing it into
# a prefix and wiring up PATH / OPENSSL_* / PKG_CONFIG_PATH.
#
# Driven by INPUT_* environment variables (set by action.yml). Can also be run
# directly for testing, e.g.:
#   INPUT_OPENSSL_VERSION='~> 3.5' RESOLVE_ONLY=1 ./install-openssl.sh
set -euo pipefail

req="${INPUT_OPENSSL_VERSION:-}"
repo="${INPUT_REPOSITORY:-cocoa-xu/openssl-build}"
triplet="${INPUT_TRIPLET:-}"
linkage="${INPUT_LINKAGE:-shared}"
install_dir="${INPUT_INSTALL_DIR:-.openssl}"
add_to_path="${INPUT_ADD_TO_PATH:-true}"
download_only="${INPUT_DOWNLOAD_ONLY:-false}"
token="${INPUT_TOKEN:-${GH_TOKEN:-${GITHUB_TOKEN:-}}}"
resolve_only="${RESOLVE_ONLY:-}"

err() { echo "::error::$*" >&2; exit 1; }
log() { echo "$*" >&2; }

[ -n "$req" ] || err "openssl-version input is required"

# ----------------------------------------------------------------------------
# Detect the ARCH-OS-ABI triplet of the current runner, unless the caller
# passed one explicitly via INPUT_TRIPLET.
# ----------------------------------------------------------------------------
detect_triplet() {
  local os arch a libc osl
  os="$(uname -s)"
  arch="$(uname -m)"
  case "$os" in
    Linux)
      case "$arch" in
        x86_64|amd64)        a=x86_64 ;;
        aarch64|arm64)       a=aarch64 ;;
        armv7l|armv7*|armhf) a=armv7l ;;
        i?86)                a=i686 ;;
        riscv64)             a=riscv64 ;;
        ppc64le|powerpc64le) a=ppc64le ;;
        s390x)               a=s390x ;;
        *) err "unsupported Linux architecture: $arch" ;;
      esac
      if [ -f /etc/alpine-release ] || (command -v ldd >/dev/null 2>&1 && ldd --version 2>&1 | grep -qi musl); then
        libc=musl
      else
        libc=gnu
      fi
      if [ "$a" = armv7l ]; then
        printf 'armv7l-linux-%seabihf' "$libc"
      else
        printf '%s-linux-%s' "$a" "$libc"
      fi
      ;;
    Darwin)
      case "$arch" in
        arm64|aarch64) printf 'arm64-apple-darwin' ;;
        x86_64)        printf 'x86_64-apple-darwin' ;;
        *) err "unsupported macOS architecture: $arch" ;;
      esac
      ;;
    FreeBSD|OpenBSD|NetBSD)
      osl="$(echo "$os" | tr '[:upper:]' '[:lower:]')"
      case "$arch" in
        x86_64|amd64) printf 'x86_64-unknown-%s' "$osl" ;;
        *) err "unsupported $os architecture: $arch (only x86_64 is published)" ;;
      esac
      ;;
    MINGW*|MSYS*|CYGWIN*)
      # uname -m misreports under WOW64; trust RUNNER_ARCH on Actions runners.
      case "${RUNNER_ARCH:-$arch}" in
        ARM64|aarch64|arm64) a=aarch64 ;;
        X64|x86_64|amd64)    a=x86_64 ;;
        *) err "unsupported Windows architecture: ${RUNNER_ARCH:-$arch}" ;;
      esac
      case "$linkage" in
        shared|static) ;;
        *) err "linkage must be 'shared' or 'static' (got '$linkage')" ;;
      esac
      printf '%s-%s-windows-msvc' "$linkage" "$a"
      ;;
    *) err "unsupported OS: $os" ;;
  esac
}

# ----------------------------------------------------------------------------
# Version comparison (sort -V handles OpenSSL's dotted numeric versions).
# ----------------------------------------------------------------------------
ver_le() { [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]; }   # a <= b
ver_lt() { [ "$1" != "$2" ] && ver_le "$1" "$2"; }                                # a <  b

# Upper bound (exclusive) for a `~>` requirement, per Elixir semantics:
#   ~> 3       -> < 4         ~> 3.5   -> < 4
#   ~> 3.5.0   -> < 3.6.0     ~> 3.5.2 -> < 3.6
tilde_upper() {
  local IFS='.'; local -a p; read -ra p <<<"$1"; local n=${#p[@]}
  if [ "$n" -le 1 ]; then
    echo "$(( p[0] + 1 ))"
  else
    p[n-2]=$(( p[n-2] + 1 )); unset 'p[n-1]'
    echo "${p[*]}"
  fi
}

# ----------------------------------------------------------------------------
# Released versions (numeric tags only). Letter releases such as 1.1.1w are
# excluded from range resolution and must be pinned exactly.
# ----------------------------------------------------------------------------
list_versions() {
  local auth=() page=1 body
  [ -n "$token" ] && auth=(-H "Authorization: Bearer $token")
  while :; do
    body="$(curl -fsSL "${auth[@]}" -H 'Accept: application/vnd.github+json' \
      "https://api.github.com/repos/$repo/releases?per_page=100&page=$page" 2>/dev/null)" || break
    [ "$body" = "[]" ] || [ -z "$body" ] && break
    printf '%s' "$body" | grep -oE '"tag_name":[[:space:]]*"v?[^"]+"' \
      | sed -E 's/.*"v?([^"]+)"/\1/'
    page=$((page+1)); [ "$page" -gt 10 ] && break
  done | grep -E '^[0-9]+(\.[0-9]+)+$' | sort -uV
}

# ----------------------------------------------------------------------------
# Parse the requirement into (op, ver). No operator => exact match.
# ----------------------------------------------------------------------------
strip() { echo "$1" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'; }
req="$(strip "$req")"
case "$req" in
  "~>"*) op="~>"; ver="$(strip "${req#\~>}")" ;;
  ">="*) op=">="; ver="$(strip "${req#>=}")" ;;
  "<="*) op="<="; ver="$(strip "${req#<=}")" ;;
  "=="*) op="=="; ver="$(strip "${req#==}")" ;;
  ">"*)  op=">";  ver="$(strip "${req#>}")" ;;
  "<"*)  op="<";  ver="$(strip "${req#<}")" ;;
  v[0-9]*) op="=="; ver="${req#v}" ;;
  *)     op="=="; ver="$req" ;;
esac
[ -n "$ver" ] || err "could not parse version requirement: '$req'"

[ -n "$triplet" ] || triplet="$(detect_triplet)"
log "Platform: $triplet  |  requirement: ${op} ${ver}"

asset_ok() { # version -> 0 if openssl-<triplet>.tar.gz exists for it
  local code
  code="$(curl -s -o /dev/null -w '%{http_code}' -I -L \
    "https://github.com/$repo/releases/download/v$1/openssl-$triplet.tar.gz" 2>/dev/null || echo 000)"
  [ "$code" = 200 ]
}

# Read versions on stdin, echo those satisfying the requirement ($op/$ver/$upper).
constraint_match() {
  local v
  while read -r v; do
    case "$op" in
      "~>") if ver_le "$ver" "$v" && ver_lt "$v" "$upper"; then echo "$v"; fi ;;
      ">=") if ver_le "$ver" "$v"; then echo "$v"; fi ;;
      ">")  if ver_lt "$ver" "$v"; then echo "$v"; fi ;;
      "<=") if ver_le "$v" "$ver"; then echo "$v"; fi ;;
      "<")  if ver_lt "$v" "$ver"; then echo "$v"; fi ;;
    esac
  done
}

# ----------------------------------------------------------------------------
# Resolve to a concrete version that actually has an artifact for this triplet.
# ----------------------------------------------------------------------------
resolved=""
if [ "$op" = "==" ]; then
  if asset_ok "$ver"; then
    resolved="$ver"
  else
    err "OpenSSL $ver has no precompiled build for $triplet (exact match)"
  fi
else
  upper=""; if [ "$op" = "~>" ]; then upper="$(tilde_upper "$ver")"; fi
  candidates="$(list_versions | constraint_match | sort -rV)"
  [ -n "$candidates" ] || err "no OpenSSL release satisfies '${op} ${ver}'"
  while read -r v; do
    [ -z "$v" ] && continue
    if asset_ok "$v"; then resolved="$v"; break; fi
    log "  (skipping $v — no $triplet build)"
  done <<<"$candidates"
  [ -n "$resolved" ] || err "no OpenSSL release satisfying '${op} ${ver}' has a $triplet build"
fi

log "Resolved '${req}' -> OpenSSL ${resolved}"

emit() { [ -n "${GITHUB_OUTPUT:-}" ] && echo "$1" >> "$GITHUB_OUTPUT"; return 0; }
emit "openssl-version=$resolved"
emit "triplet=$triplet"
[ -n "$resolve_only" ] && { echo "$resolved"; exit 0; }

# ----------------------------------------------------------------------------
# Download, and verify the checksum when the release publishes a usable one
# (Windows archives ship none; NetBSD's is empty).
# ----------------------------------------------------------------------------
mkdir -p "$install_dir"
install_dir="$(cd "$install_dir" && pwd)"
archive="$install_dir/openssl-$triplet.tar.gz"
url="https://github.com/$repo/releases/download/v$resolved/openssl-$triplet.tar.gz"
log "Downloading $url"
curl -fSL --retry 3 --retry-all-errors "$url" -o "$archive" || err "failed to download $url"

sha_code="$(curl -s -o /dev/null -w '%{http_code}' -I -L "$url.sha256" 2>/dev/null || echo 000)"
expected=""
[ "$sha_code" = 200 ] && expected="$(curl -fsSL "$url.sha256" 2>/dev/null | awk '{print $1}')"
if printf '%s' "$expected" | grep -qiE '^[0-9a-f]{64}$'; then
  if command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "$archive" | awk '{print $1}')"
  else
    actual="$(shasum -a 256 "$archive" | awk '{print $1}')"
  fi
  [ "$expected" = "$actual" ] || err "checksum mismatch (expected $expected, got $actual)"
  log "Checksum OK ($actual)"
else
  log "No usable checksum published for openssl-$triplet.tar.gz; skipping verification"
fi

if [ "$download_only" = "true" ]; then
  emit "archive-path=$archive"
  log "Downloaded OpenSSL ${resolved} to ${archive}"
  exit 0
fi

# ----------------------------------------------------------------------------
# Extract and wire up PATH / OPENSSL_* / PKG_CONFIG_PATH / loader path.
# ----------------------------------------------------------------------------
tar -xzf "$archive" -C "$install_dir"
rm -f "$archive"

bindir="$install_dir/bin"
incdir="$install_dir/include"
if [ -d "$install_dir/lib64" ]; then libdir="$install_dir/lib64"; else libdir="$install_dir/lib"; fi
ossl="$bindir/openssl"; [ -e "$ossl" ] || ossl="$bindir/openssl.exe"
[ -e "$ossl" ] || err "extracted archive does not contain bin/openssl"

prepend() { # NAME VALUE -> "NAME=VALUE[:existing]" preserving any prior value
  local cur; cur="$(printenv "$1" 2>/dev/null || true)"
  if [ -n "$cur" ]; then echo "$1=$2:$cur"; else echo "$1=$2"; fi
}

if [ "$add_to_path" = "true" ] && [ -n "${GITHUB_PATH:-}" ]; then
  echo "$bindir" >> "$GITHUB_PATH"
fi
if [ -n "${GITHUB_ENV:-}" ]; then
  {
    echo "OPENSSL_DIR=$install_dir"
    echo "OPENSSL_ROOT_DIR=$install_dir"
    echo "OPENSSL_INCLUDE_DIR=$incdir"
    echo "OPENSSL_LIB_DIR=$libdir"
    prepend PKG_CONFIG_PATH "$libdir/pkgconfig"
    case "$triplet" in
      *-apple-darwin) prepend DYLD_LIBRARY_PATH "$libdir" ;;
      *-windows-msvc) ;;  # DLLs live in bin/, already added to PATH
      *)              prepend LD_LIBRARY_PATH "$libdir" ;;
    esac
  } >> "$GITHUB_ENV"
fi

emit "install-dir=$install_dir"
emit "openssl-dir=$install_dir"
emit "bindir=$bindir"
emit "libdir=$libdir"

log "OpenSSL ${resolved} installed to ${install_dir}"
case "$triplet" in
  *-apple-darwin) DYLD_LIBRARY_PATH="$libdir${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" "$ossl" version 2>/dev/null ;;
  *)              LD_LIBRARY_PATH="$libdir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" "$ossl" version 2>/dev/null ;;
esac || log "(note: could not run openssl version; PATH/env are still set)"
