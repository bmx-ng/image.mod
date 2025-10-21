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
' 1. The origin of this software must not be misrepresented; you must not
'    claim that you wrote the original software. If you use this software
'    in a product, an acknowledgment in the product documentation would be
'    appreciated but is not required.
' 2. Altered source versions must be plainly marked as such, and must not be
'    misrepresented as being the original software.
' 3. This notice may not be removed or altered from any source distribution.
' 
SuperStrict

Rem
bbdoc: Image/PCX Loader
about: The PCX loader module provides the ability to load PCX format #pixmaps.
End Rem
Module Image.PCX

ModuleInfo "Version: 1.00"
ModuleInfo "License: ZLib/PNG License"
ModuleInfo "Author: Bruce A Henderson"

ModuleInfo "History: 1.00"
ModuleInfo "History: Initial Release."

ModuleInfo "C_OPTS: -std=c99"

Import BRL.pixmap

Import "common.bmx"

Rem
bbdoc: PCX image format files.
End Rem
Type TPcxImage

	Rem
	bbdoc: Loads PCX image from a file as a #TPixmap.
	End Rem
	Function Load:TPixmap(file:String, channels:Int = 0)
		Local stream:TStream = ReadStream(file)
		If stream Then
			Local pix:TPixmap = Load(stream, channels)
			stream.Close()
			Return pix
		End If
	End Function

	Rem
	bbdoc: Loads PCX image from stream as a #TPixmap.
	End Rem
	Function Load:TPixmap(stream:TStream, channels:Int = 0)

		Local width:Int
		Local height:Int
		Local components:Int

		Local pixels:Byte Ptr = drpcx_load(_ReadCallback, stream, False, width, height, components, 0)
		If pixels Then
			Local format:Int = PF_RGB888
			Local align:Int = 3
			If components = 4 Then
				format = PF_RGBA8888
				align = 4
			End If
			Local pix:TPixmap = TPixmap.Create(width, height, format, align)
			
			MemCopy(pix.pixels, pixels, Size_T(width * height * align))

			drpcx_free(pixels)
			Return pix
		End If

	End Function

	Function _ReadCallback:Size_T(streamObj:Object, bufferOut:Byte Ptr, bytesToRead:Size_T)
		Try
			Local stream:TStream = TStream(streamObj)
			If stream Then
				Local res:Long = stream.ReadBytes(bufferOut, Long(bytesToRead))
				Return res
			End If
		Catch e:Object
		End Try
		Return 0
	End Function

End Type

Private

Type TPixmapLoaderPcx Extends TPixmapLoader

	Method LoadPixmap:TPixmap( stream:TStream ) Override

		Return TPcxImage.Load(stream)

	End Method

End Type

New TPixmapLoaderPcx
