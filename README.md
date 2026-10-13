# openssl-build

Precompiled OpenSSL binaries for CI, published across a wide matrix of
OS / ABI / architecture targets (see [Availability](#availability)). Built as a
dependency of other projects; consume them either through the bundled
[GitHub Action](#github-action) or by [downloading](#direct-download) the
release archives directly.

- [GitHub Action](#github-action) — resolve a version, download, and install
- [Direct download](#direct-download) — release URL scheme + archive layout
- [Availability](#availability) — supported version / OS / ABI / arch matrix

## GitHub Action

This repo ships a composite action that resolves an OpenSSL version, downloads
the matching precompiled build for the current runner, and (by default)
installs it — adding `bin` to `PATH` and exporting `OPENSSL_DIR`,
`OPENSSL_ROOT_DIR`, `OPENSSL_LIB_DIR`, `OPENSSL_INCLUDE_DIR` and
`PKG_CONFIG_PATH`.

```yaml
- uses: cocoa-xu/openssl-build@main
  with:
    openssl-version: "3.6.3"
- run: openssl version   # now on PATH
```

> The repo's `v*` tags are OpenSSL release markers, not action versions —
> reference the action at `@main` (or a commit SHA).

Version resolution follows Elixir's requirement syntax: an exact version matches
that release; a requirement resolves to the highest available release that
satisfies it.

| `openssl-version` | resolves to |
|---|---|
| `3.6.3` | exactly 3.6.3 |
| `~> 3.5` | highest `3.x` `>= 3.5.0` |
| `~> 3.5.0` | highest `3.5.x` |
| `>= 3.4.0` | highest release `>= 3.4.0` |
| `< 4` | highest release below `4.0.0` |

Letter releases such as `1.1.1w` are outside the numeric range space and must be
pinned exactly.

### Inputs

| Input | Default | Description |
|---|---|---|
| `openssl-version` | — | Version or Elixir-style requirement (required). `openssl_version` is an accepted alias. |
| `triplet` | auto | Override the auto-detected `ARCH-OS-ABI` triplet (any value from the availability table). |
| `linkage` | `shared` | Windows only: `shared` or `static`. |
| `install-dir` | `.openssl` | Where to extract OpenSSL (or where to save the archive when `download-only`). |
| `add-to-path` | `true` | Append `<install-dir>/bin` to `PATH`. |
| `download-only` | `false` | Only download + checksum-verify the archive; skip extraction and env setup. |
| `repository` | `cocoa-xu/openssl-build` | Release source repository. |
| `token` | `${{ github.token }}` | Token for listing releases when resolving a requirement. |

### Outputs

| Output | Description |
|---|---|
| `openssl-version` | The concrete version that was resolved. |
| `triplet` | The triplet that was used. |
| `install-dir` / `openssl-dir` | Absolute install prefix (install mode). |
| `bindir` / `libdir` | Absolute `bin` / `lib` directories. |
| `archive-path` | Absolute path of the downloaded archive (`download-only` mode). |

### Examples

Pin a requirement into a custom prefix and hand it to CMake:

```yaml
- uses: cocoa-xu/openssl-build@main
  with:
    openssl-version: "~> 3.6"
    install-dir: ${{ runner.temp }}/openssl
- run: cmake -B build   # OPENSSL_ROOT_DIR is already exported
```

Windows, static libraries:

```yaml
- uses: cocoa-xu/openssl-build@main
  with:
    openssl-version: "3.6.3"
    linkage: static
```

Download the archive only (no install), e.g. to cache or repackage it:

```yaml
- uses: cocoa-xu/openssl-build@main
  id: ossl
  with:
    openssl-version: "3.6.3"
    download-only: true
- run: echo "got ${{ steps.ossl.outputs.archive-path }}"
```

Force a specific triplet — e.g. an old FreeBSD release whose asset name carried
the OS version:

```yaml
- uses: cocoa-xu/openssl-build@main
  with:
    openssl-version: "3.2.0"
    triplet: x86_64-unknown-freebsd13
```

## Direct download

Every build is a GitHub release asset named `openssl-<triplet>.tar.gz`, under a
`v<version>` tag:

```
https://github.com/cocoa-xu/openssl-build/releases/download/v<version>/openssl-<triplet>.tar.gz
```

`<triplet>` is an `ARCH-OS-ABI` string from the [Availability](#availability)
table — e.g. `x86_64-linux-gnu`, `aarch64-linux-musl`, `arm64-apple-darwin`,
`shared-x86_64-windows-msvc`, or `x86_64-unknown-freebsd`. Each archive has a
companion `.tar.gz.sha256` (Windows builds have none; older NetBSD releases
have empty checksums).

```bash
# x86_64 glibc Linux, OpenSSL 3.6.3
curl -fSL https://github.com/cocoa-xu/openssl-build/releases/download/v3.6.3/openssl-x86_64-linux-gnu.tar.gz -o openssl.tar.gz
mkdir -p openssl && tar -xzf openssl.tar.gz -C openssl
openssl/bin/openssl version
```

Archives unpack flat — the extraction root **is** the install prefix (built with
`--prefix` == `--openssldir`):

```
bin/  include/  lib/ (or lib64/ on glibc targets)  certs/  misc/  private/  openssl.cnf  ...
```

## Availability

<table>
<thead>
  <tr>
    <th colspan="11">Availability<br></th>
  </tr>
</thead>
<tbody>
  <tr>
    <td></td>
    <td></td>
    <td><b>Version →</b><sup>4</sup></td>
    <td>4.0.x</td>
    <td>3.6.x</td>
    <td>3.5.x</td>
    <td>3.4.x</td>
    <td>3.3.x</td>
    <td>3.2.1</td>
    <td>3.2.0</td>
    <td>1.1.1w</td>
  </tr>
  <tr>
    <td><b>OS ↓</b></td>
    <td><b>ABI ↓</b></td>
    <td><b>Arch ↓</b></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td rowspan="14">Linux</td>
    <td rowspan="7">gnu<sup>1</sup></td>
    <td>x86_64</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <td>i686<sup>2</sup></td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <td>armv7l</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>aarch64</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <td>riscv64</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <td>ppc64le</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <td>s390x</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <td rowspan="7">musl</td>
    <td>x86_64</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <td>i686</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <td>armv7l</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>aarch64</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <td>riscv64</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <td>ppc64le</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <td>s390x</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <td rowspan="2">macOS</td>
    <td rowspan="2">darwin</td>
    <td>arm64</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <td>x86_64</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <td rowspan="2">Windows</td>
    <td rowspan="2">msvc</td>
    <td>arm64</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td></td>
    <td>✓</td>
  </tr>
  <tr>
    <td>x86_64</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td></td>
    <td>✓</td>
  </tr>
  <tr>
    <td>FreeBSD<sup>3</sup></td>
    <td>13</td>
    <td>x86_64</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <td>OpenBSD<sup>3</sup></td>
    <td>7</td>
    <td>x86_64</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <td>NetBSD<sup>3</sup></td>
    <td>9</td>
    <td>x86_64</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
</tbody>
</table>

<footer>

  *1. `manylinux_2_28_$ARCH` will be used for `x86_64`, `aarch64`, `ppc64le` and `s390x` with glibc starting from OpenSSL 3.3.2*

  *2. Support for `i686-linux-gnu` is deprecated*

  *3. Through 3.3.2, FreeBSD shipped as separate `freebsd13` and `freebsd14` archives; from 3.3.3 a single unversioned `freebsd` archive is published (currently built on FreeBSD 13.5). NetBSD (`netbsd9` → `netbsd`, 9.4) and OpenBSD (`openbsd7` → `openbsd`, 7.7) were renamed the same way.*

  *4. Cells reflect the latest patch of each series. Some intermediate patches shipped incomplete asset sets — e.g. 3.3.5, 3.5.1–3.5.4 and 3.6.0 are missing some glibc and/or Windows builds.*

</footer>
