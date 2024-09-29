# openssl-build

Precompiled OpenSSL for CI builds (as a dependency of other projects).

<table>
<thead>
  <tr>
    <th colspan="10">Availability<br></th>
  </tr>
</thead>
<tbody>
  <tr>
    <td></td>
    <td></td>
    <td><b>Version →</b></td>
    <td>3.3.2<sup>1</sup></td>
    <td>3.3.0-3.3.1</td>
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
  </tr>
  <tr>
    <td rowspan="12">Linux</td>
    <td rowspan="6">gnu</td>
    <td>x86_64</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <td>i686</td>
    <td><sup>2</sup></td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <td>aarch64</td>
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
  </tr>
  <tr>
    <td>ppcle64</td>
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
  </tr>
  <tr>
    <td rowspan="6">musl</td>
    <td>x86_64</td>
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
  </tr>
  <tr>
    <td>aarch64</td>
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
  </tr>
  <tr>
    <td>ppcle64</td>
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
  </tr>
  <tr>
    <td>x86_64</td>
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
    <td></td>
    <td>✓</td>
  </tr>
  <tr>
    <td>x86_64</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td></td>
    <td>✓</td>
  </tr>
  <tr>
    <td rowspan="2">FreeBSD</td>
    <td>13</td>
    <td>x86_64</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <td>14</td>
    <td>x86_64</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <td>OpenBSD</td>
    <td>7</td>
    <td>x86_64</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
  <tr>
    <td>NetBSD</td>
    <td>9</td>
    <td>x86_64</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
    <td>✓</td>
  </tr>
</tbody>
</table>

<footer>
  
  *1. `manylinux_2_28_$ARCH` will be used for `x86_64`, `aarch64`, `ppc64le` and `s390x` with glibc Starting from OpenSSL 3.3.2*

  *2. Support for i686-linux-gnu is deprecated*
  
</footer>
