# Image.DDS

Import `Image.DDS` to load DDS files as `TTextureData`, preserving compressed
blocks and mip levels. It registers itself with `BRL.TextureData`; no graphics
backend is required to read a file.

```blitzmax
SuperStrict
Framework BRL.StandardIO
Import Image.DDS

Local data:TTextureData=LoadTextureData("terrain.dds")
If Not data Then Throw "Texture could not be opened or recognised"
Print data.Width()+" x "+data.Height()+", "+data.LevelCount()+" levels"
```

## Using it with Max2D

```blitzmax
Framework Max2D.GLMax2D
Import Image.DDS

Graphics 640,480
Local data:TTextureData=LoadTextureData("terrain.dds")
If Not data Then Throw "Texture could not be loaded"
If Max2DTextureDataSupport(data,FILTEREDIMAGE)=ETextureFormatSupport.Unsupported Then
	Throw "This device cannot upload the texture"
End If
Local image:TImage=LoadImage(data,FILTEREDIMAGE)
```

You can also call `LoadImage("terrain.dds",FILTEREDIMAGE)` or
`LoadAnimImage("sheet.dds",...)` directly. Format detection uses the file signature,
not its extension. Multiple mip levels enable mip sampling automatically.
Animation frames share the supplied texture, so prepare padding between sprites
at every mip level. Single-level compressed files cannot request automatic
mipmap generation.

Only importing this module adds DDS support. Existing PNG/JPEG and other pixmap
loaders continue to handle their own formats. Recognised DDS errors propagate
instead of silently trying a pixmap decoder.

## Supported files

- Legacy `DXT1` → `PF_BC1_RGBA` and `DXT5` → `PF_BC3_RGBA`.
- DX10 headers with `BC1_UNORM` or `BC3_UNORM`.
- One 2D texture, with a single level, complete chain or partial chain.
- DX10 unknown, straight and opaque alpha modes. Unknown alpha follows the usual
  straight-alpha interpretation; encoded bytes remain unchanged.

Uncompressed DDS, other BC formats, sRGB/typeless formats, premultiplied/custom
alpha, texture arrays, cubemaps and volume textures are rejected explicitly.
This is a container reader, not a compressor or decoder: it does not provide
`TPixmap` conversion.

Dimensions and mip counts are validated before reading payloads. Rows are computed
from the format's block layout, not the advisory DDS pitch/linear-size field.
Known remaining stream length is checked before allocating texture buffers.
GPU restrictions are separate: use `Max2DTextureDataSupport` after choosing the
renderer. For example, D3D11 requires block-aligned base dimensions.

## Streams and virtual files

`LoadTextureData`, Max2D's image loaders and `LoadTextureDDS` accept filenames,
stream URLs and `TStream` objects through `ReadStream`. This preserves BRL.IO
virtual-filesystem support, including mounted archives.

Generic detection requires a seekable stream. It starts at the current position,
restores that position when no provider recognises the data, and advances past the
texture on success. Caller-owned streams are left open; streams opened from URLs
are closed. Trailing bytes are not consumed.

For a forward-only stream whose format you already know, call
`LoadTextureDDS(stream)` directly. It handles short reads and does not seek.
Unlike generic probing, an unrecognised signature still consumes up to four bytes.

An unavailable URL or unrecognised signature returns `Null`. Once the DDS
signature is recognised, truncated, invalid or unsupported data throws an
informative error.

## Tests

`tests/dds.bmx` covers legacy and DX10 headers, both formats, partial chains,
stream offsets and ownership, forward-only short reads, malformed sizes, truncated
payloads and unsupported layouts. Max2D's `dds_loading.bmx` additionally checks
file and stream-URL loading, PNG fallback, animation sheets and GPU mip sampling;
`dds_disabled.bmx` checks optional registration.

The parser follows Microsoft's [DDS programming guide](https://learn.microsoft.com/en-us/windows/win32/direct3ddds/dx-graphics-dds-pguide)
and [DX10 header definition](https://learn.microsoft.com/en-us/windows/win32/direct3ddds/dds-header-dxt10).
