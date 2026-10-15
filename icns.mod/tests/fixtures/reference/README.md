# ICNS format reference fixtures

These fixtures are a verifier-clean subset of `icnsutil`'s
`format-support-icns.zip` compatibility matrix. They are retained under the
upstream MIT license in `../../../LICENSE.icnsutil`.

The selected files cover every modern ICNS key represented by the archive:

- PNG and JPEG 2000 payloads for `icp4`, `icp5`, `icp6`, `ic07`, `ic08`,
  `ic09`, `ic10`, `ic11`, `ic12`, `ic13`, `ic14`, `ic04`, `ic05`, `icsb`,
  `icsB`, `sb24`, and `SB24`.
- ARGB payloads for the keys which officially permit them: `ic04`, `ic05`,
  and `icsb`.
- A 48x48 legacy PackBits RGB `ih32` element paired with its `h8mk` alpha
  mask.

The PNG, JPEG 2000, and ARGB files are unmodified archive members. The upstream
RGB matrix generator placed all four legacy alpha-mask sizes into every RGB
sample. `48-ih32-rgb.icns` was therefore normalized with the upstream
`icnsutil update` command by removing the unrelated `s8mk`, `l8mk`, and `t8mk`
elements, leaving the valid `ih32`/`h8mk` pair.

All 38 files pass `python -m icnsutil test`. Python and `icnsutil` are fixture
provenance/verification tools only and are not used by the module or its test
runner.
