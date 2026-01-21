' Copyright (c) 2021 Bruce A Henderson
' 
' Permission is hereby granted, free of charge, to any person obtaining a copy
' of this software and associated documentation files (the "Software"), to deal
' in the Software without restriction, including without limitation the rights
' to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
' copies of the Software, and to permit persons to whom the Software is
' furnished to do so, subject to the following conditions:
' 
' The above copyright notice and this permission notice shall be included in
' all copies or substantial portions of the Software.
' 
' THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
' IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
' FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
' AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
' LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
' OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
' THE SOFTWARE.
'
SuperStrict

Rem
bbdoc: Image/Qoi Loader and Writer
about: The Qoi module provides the ability to load and save Qoi format #pixmaps.
End Rem
Module Image.Qoi

ModuleInfo "Version: 1.00"
ModuleInfo "License: MIT"
ModuleInfo "Copyright: Wrapper - 2021 Bruce A Henderson"

ModuleInfo "History: 1.00"
ModuleInfo "History: Initial Release."

Import BRL.Pixmap
Import Pub.StdC

Import "common.bmx"

Rem
bbdoc: Qoi image format files.
about: See https://qoiformat.org/ for more information.
End Rem
Type TQoiImage

	Rem
	bbdoc: Loads Qoi image from a file as a #TPixmap.
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
	bbdoc: Loads Qoi image from stream as a #TPixmap.
	End Rem
	Function Load:TPixmap(stream:TStream, channels:Int = 0)

		Local desc:SQoiDesc
		Local data:Byte[] = LoadByteArray(stream)
		
		Local pixels:Byte Ptr = qoi_decode(data, data.Length, desc, channels)
		If pixels Then

			Local format:Int = PF_RGB888
			Local align:Int = 3
			If desc.channels = 4 Then
				format = PF_RGBA8888
				align = 4
			End If
			Local pix:TPixmap = TPixmap.Create(desc.width, desc.height, format, align)
			
			MemCopy(pix.pixels, pixels, Size_T(desc.width * desc.height * desc.channels))

			free_(pixels)
			Return pix
		End If

	End Function

	Rem
	bbdoc: Saves pixmap to a #TStream as Qoi image.
	about: Returns #True if the #TPixmap was successfully written to the stream.
	End Rem
	Function Save:Int(stream:TStream, pix:TPixmap)
		Local desc:SQoiDesc
		desc.width = pix.width
		desc.height = pix.height
		desc.colorspace = EQoiColorspace.LINEAR

		If pix.format <> PF_RGB888 And pix.format <> PF_RGBA8888 Then
			pix = pix.Convert(PF_STDFORMAT)
		End If

		Select pix.format
			Case PF_RGB888
				desc.channels = 3
			Case PF_RGBA8888
				desc.channels = 4
		End Select

		Local result:Int
		Local data:Byte Ptr
		Try
			Local outLen:Int
			data = qoi_encode(pix.pixels, desc, outLen)
			stream.WriteBytes(data, outLen)
		Finally
			If data Then
				free_(data)
				If outLen > 0 Then
					result = True
				End If
			End If
		End Try
		Return result
	End Function
End Type


Rem
bbdoc: Save a Pixmap in Qoi format
about:
#SavePixmapQoi saves @pixmap to @url in Qoi format. If successful, #SavePixmapPNG returns
True, otherwise False.
End Rem
Function SavePixmapQoi:Int( pixmap:TPixmap, url:Object )
	Local qoi_stream:TStream = WriteStream( url )
	If Not qoi_stream Return False
	
	Local result:Int = TQoiImage.Save(qoi_stream, pixmap)
		
	qoi_stream.Close()
	qoi_stream=Null
		
	Return result
End Function

Private

Type TPixmapLoaderQoi Extends TPixmapLoader

	Method LoadPixmap:TPixmap( stream:TStream ) Override

		Return TQoiImage.Load(stream)

	End Method

End Type

New TPixmapLoaderQoi
