# Image.ICNS

`Image.ICNS` is a native BlitzMax reader and writer for Apple Icon Image
(`.icns`) containers. It has no Python or command-line tool dependency.

Importing the module registers an ICNS pixmap loader. `LoadPixmap` therefore
loads the largest supported image in an ICNS file, while `TIcnsFile` exposes
the individual elements and container-writing API.

## Creating an ICNS file

```blitzmax
SuperStrict

Framework BRL.StandardIO
Import Image.ICNS

Local icon:TIcnsFile = New TIcnsFile
icon.AddPixmap(LoadPixmap("icon-16.png"))
icon.AddPixmap(LoadPixmap("icon-32.png"))
icon.AddPixmap(LoadPixmap("icon-128.png"))
icon.AddPixmap(LoadPixmap("icon-256.png"))
icon.AddPixmap(LoadPixmap("icon-512.png"))
icon.AddPixmap(LoadPixmap("icon-1024.png"))
icon.Save("application.icns", True) ' True adds a fresh TOC element
```

Pixmaps are stored as embedded PNG data. Standard non-Retina dimensions are
16, 18, 24, 32, 48, 128, 256, 512, and 1024 pixels. For Retina elements pass
`True` as the `retina` argument to `AddPixmap`, or pass an explicit four-byte
element key where a size is ambiguous.

PNG bytes can also be added directly:

```blitzmax
Local icon:TIcnsFile = New TIcnsFile
icon.AddMedia(LoadByteArray("icon-256.png"), "ic08")
icon.Save("application.icns")
```

## Reading

```blitzmax
Local icon:TIcnsFile = TIcnsFile.Load("application.icns")
Local largest:TPixmap = icon.ToPixmap()
Local small:TPixmap = icon.ToPixmap("icp4")

For Local key:String = EachIn icon.MediaKeys()
	Print key
Next
```

`LoadPixmapICNS` and the registered `TPixmapLoaderICNS` provide the convenient
single-pixmap path. `TIcnsFile.Load` additionally accepts a `TStream`, `TPath`,
or `Byte[]`.

## Element support

The container reader and writer preserve known and unknown four-byte element
types. The following known types are described by the module:

| Kind | Element keys | Payloads |
| --- | --- | --- |
| Modern icons | `icp4`, `icp5`, `icp6`, `ic07`-`ic14`, `ic04`, `ic05`, `icsb`, `icsB`, `sb24`, `SB24` | PNG and JPEG 2000; ARGB where defined by the format |
| Legacy 24-bit icons | `is32`, `il32`, `ih32`, `it32` | ICNS PackBits planar RGB |
| Legacy 8-bit masks | `s8mk`, `l8mk`, `h8mk`, `t8mk` | Uncompressed alpha bytes |
| Classic indexed/mono | `ICON`, `ICN#`, `icm#`, `icm4`, `icm8`, `ics#`, `ics4`, `ics8`, `icl4`, `icl8`, `ich#`, `ich4`, `ich8` | Preserved as binary elements |
| Nested ICNS | `sbtp`, `slct`, dark-icon key `FD D9 2F A8` | ICNS body without its outer header |
| Metadata | `TOC `, `icnV`, `name`, `info` | Binary data or binary plist |

Pixmap decoding supports embedded PNG, modern compressed ARGB, and legacy
compressed 24-bit RGB with its matching 8-bit mask. JPEG 2000 and classic
indexed/monochrome elements are retained and can be accessed with `GetMedia`,
but are not converted to pixmaps by this module. When a file contains several
elements, `ToPixmap()` chooses the largest element it can decode.

`ToByteArray` and `Save` preserve insertion/file order. Passing `True` for
`includeToc` discards any loaded TOC and writes a new, consistent one.

## Validation

Loading rejects truncated headers, invalid element lengths, duplicate keys,
and a declared container size that does not match the supplied data. Returned
media bytes and key arrays are copies, so callers cannot accidentally mutate
the parsed container.

The compatibility fixtures used by the tests originate from the MIT-licensed
[`icnsutil`](https://github.com/relikd/icnsutil) project and are used only as
format fixtures; the runtime implementation is entirely BlitzMax. See
`LICENSE.icnsutil` for the upstream copyright and license.

The focused reference matrix under `tests/fixtures/reference` contains 38
upstream-verified ICNS files. It exercises every modern key available in the
reference archive with PNG and JPEG 2000 payloads, every officially permitted
ARGB combination, and the legacy 48x48 RGB/mask pair. Tests decode every PNG
and ARGB image, preserve every JPEG 2000 payload byte-for-byte across an ICNS
round trip, and validate the legacy mask during pixel reconstruction. The
smaller original fixtures additionally cover classic mono elements, 16/32/128
legacy RGB and masks, nested selected icons, binary plist metadata, malformed
containers, TOC rebuilding, caller-owned stream behavior, and native pixmap
creation.
