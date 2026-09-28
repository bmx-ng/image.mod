# image.mod

BlitzMax includes support for loading many different image formats.

Simply import one of the image modules, and you will be able to load images of that format into a `TPixmap`.

## DDS texture containers

Import `Image.DDS` to load BC1/BC3 DDS containers into `TTextureData`, retaining
compressed blocks and mip levels. This also enables DDS in the new Max2D image
loaders. DDS data is not decoded into `TPixmap`. See [Image.DDS](dds.mod/README.md)
for supported headers, stream loading and backend limitations.

## Supported formats

The following image formats are currently supported : 

### BMP

Usage :
```blitzmax
Import Image.BMP
```

See [Wikipedia](https://en.wikipedia.org/wiki/BMP_file_format) for more information about the format.

### GIF

Usage :
```blitzmax
Import Image.GIF
```

Supports both static and animated GIFs.

To load an animated GIF, use the following function, `TGifImage.LoadImage(url:Object)` :
```blitzmax
Local image:TImage = TGifImage.LoadImage("image-name.gif")
```
This function returns a fully populated Max2D `TImage` object directly (similar to calling `LoadAnimImage`), rather than a `TPixmap`.
GIF frame delays are stored in the `frameDuration:Int[]` field of `TImage` as a time in milliseconds.

See [Wikipedia](https://en.wikipedia.org/wiki/GIF) for more information about the format.

### IFF/ILBM

Usage :
```blitzmax
Import Image.ILBM
```

See [Wikipedia](https://en.wikipedia.org/wiki/ILBM) for more information about the format.

### JPG

Usage :
```blitzmax
Import Image.JPG
```

See [Wikipedia](https://en.wikipedia.org/wiki/JPEG) for more information about the format.

### PCX

Usage :
```blitzmax
Import Image.PCX
```

See [Wikipedia](https://en.wikipedia.org/wiki/PCX) for more information about the format.

### PIC

Usage :
```blitzmax
Import Image.PIC
```

See [Wikipedia](https://en.wikipedia.org/wiki/PICtor_PIC_image_format) for more information about the format.

### PNG

Usage :
```blitzmax
Import Image.PNG
```

See [Wikipedia](https://en.wikipedia.org/wiki/Portable_Network_Graphics) for more information about the format.

### PNM

Usage :
```blitzmax
Import Image.PNM
```

See [Wikipedia](https://en.wikipedia.org/wiki/Netpbm#File_formats) for more information about the format.

### QOI

Usage :
```blitzmax
Import Image.QOI
```

See https://qoiformat.org/

### RAW

Usage :
```blitzmax
Import Image.RAW
```

See [Wikipedia](https://en.wikipedia.org/wiki/Raw_image_format) for more information about the format.

### SVG

Usage :
```blitzmax
Import Image.SVG
```

See [Wikipedia](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) for more information about the format.

### TGA

Usage :
```blitzmax
Import Image.TGA
```

See [Wikipedia](https://en.wikipedia.org/wiki/Truevision_TGA) for more information about the format.

### WEBP

Usage :
```blitzmax
Import Image.WEBP
```

See [Wikipedia](https://en.wikipedia.org/wiki/WebP) for more information about the format.

