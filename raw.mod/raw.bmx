' Copyright (c) 2021 Bruce A Henderson
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
bbdoc: Image/RAW Loader
about: The RAW loader module provides the ability to load RAW format #pixmaps.
End Rem
Module Image.Raw

ModuleInfo "Version: 1.00"
ModuleInfo "License: libRaw - CDDL"
ModuleInfo "License: Wrapper - zlib/libpng"
ModuleInfo "Copyright: libRaw - 2008-2021 LibRaw LLC"
ModuleInfo "Copyright: Wrapper - 2021 Bruce A Henderson"

ModuleInfo "History: 1.00"
ModuleInfo "History: Initial Release."

ModuleInfo "CPP_OPTS: -fexceptions -DLIBRAW_NOTHREADS"

Import BRL.Pixmap
Import "common.bmx"


Type TRawImage

	Field imagePtr:Byte Ptr

	Method New()
		imagePtr = libraw_init(0)
	End Method

	Method Free()
		If imagePtr Then
			libraw_recycle(imagePtr)
			libraw_close(imagePtr)
			imagePtr = Null
		End If
	End Method

	Method Delete()
		Free()
	End Method

	Rem
	bbdoc: 
	End Rem
	Method Load:TPixmap(stream:TStream)
		Recycle()

		Return bmx_image_raw_load(imagePtr, stream)
	End Method

	Method Recycle()
		libraw_recycle(imagePtr)
	End Method

	Function _NewPixmap:TPixmap(width:Int, height:Int) { nomangle }
		Return TPixmap.Create( width,height,PF_RGB888,3)
	End Function

	Function _PixmapVar(pix:TPixmap, pixels:Byte Ptr Var, pitch:Int Var) { nomangle }
		pixels = pix.pixels
		pitch = pix.pitch
	End Function
End Type

Private

Function _stream_seek:Int(stream:TStream, pos:Long, whence:Int) { nomangle }
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

Function _stream_eof:Int(stream:TStream) { nomangle }
	Return stream.Eof()
End Function

Type TPixmapLoaderRaw Extends TPixmapLoader

	Method LoadPixmap:TPixmap( stream:TStream ) Override
		Local image:TRawImage = New TRawImage()
		Local pix:TPixmap = image.Load(stream)
		image.Free()
		Return pix
	End Method

End Type

New TPixmapLoaderRaw
