' Copyright (c) 2022 Bruce A Henderson
'
' This software is provided 'as-is', without any express or implied
' warranty. In no event will the authors be held liable for any damages
' arising from the use of this software.
'
' Permission is granted to anyone to use this software for any purpose,
' including commercial applications, and to alter it and redistribute it
' freely, subject to the following restrictions:
'
'    1. The origin of this software must not be misrepresented; you must not
'    claim that you wrote the original software. If you use this software
'    in a product, an acknowledgment in the product documentation would be
'    appreciated but is not required.
'
'    2. Altered source versions must be plainly marked as such, and must not be
'    misrepresented as being the original software.
'
'    3. This notice may not be removed or altered from any source
'    distribution.
'
SuperStrict

Rem
bbdoc: Image/TIFF Loader
about: The TIFF loader module provides the ability to load TIFF format #pixmaps.
End Rem
Module Image.Tiff

ModuleInfo "Version: 1.00"
ModuleInfo "License: libtiff - BSD-like"
ModuleInfo "License: Wrapper - zlib/libpng"
ModuleInfo "Copyright: libtiff - 1988-1997 Sam Leffler, 1991-1997 Silicon Graphics, Inc"
ModuleInfo "Copyright: Wrapper - 2022 Bruce A Henderson"

ModuleInfo "History: 1.00"
ModuleInfo "History: Initial Release."

?ptr64
ModuleInfo "CC_OPTS: -DSIZEOF_SIZE_T=8"
?ptr32
ModuleInfo "CC_OPTS: -DSIZEOF_SIZE_T=4"
?

Import "common.bmx"


Type TTiffImage

	Rem
	bbdoc: Loads TIFF image from a file as a #TPixmap.
	End Rem
	Function Load:TPixmap(file:String)
		Local stream:TStream = ReadStream(file)
		If stream Then
			Local pix:TPixmap = Load(stream)
			stream.Close()
			Return pix
		End If
	End Function

	Rem
	bbdoc: Loads AVIF image from stream as a #TPixmap.
	End Rem
	Function Load:TPixmap(stream:TStream)

		Local tiff:Byte Ptr = bmx_tiff_clientOpen(stream)

		If tiff Then
			Local width:UInt
			Local height:UInt

			bmx_tiff_dimensions(tiff, width, height)

			Local pix:TPixmap = TPixmap.Create(width, height, PF_RGBA8888, 4)

			Local res:Int = bmx_tiff_readRGBAImage(tiff, width, height, pix.pixels, 0)

			bmx_tiff_close(tiff)

			If res Then
				Return pix
			End If
		End If
	End Function

End Type

Private

Function _stream_seek:ULong(stream:TStream, pos:Long, whence:Int) { nomangle }
	Return stream.seek(pos, whence)
End Function

Function _stream_read:Int(stream:TStream, buf:Byte Ptr, count:Size_T) { nomangle }
	Return stream.Read(buf, count)
End Function

Function _stream_tell:Long(stream:TStream) { nomangle }
	Return stream.Pos()
End Function

Function _stream_size:Long(stream:TStream) { nomangle }
	Return stream.Size()
End Function

Function _stream_close(stream:TStream) { nomangle }
	stream.close()
End Function

Type TPixmapLoaderTiff Extends TPixmapLoader

	Method LoadPixmap:TPixmap( stream:TStream ) Override

		Return TTiffImage.Load(stream)

	End Method

End Type

New TPixmapLoaderTiff
