' Copyright (c) 2022-2025 Bruce A Henderson
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
bbdoc: Image/ILBM loader
about:
The ILBM loader module provides the ability to load ILBM format #pixmaps.
End Rem
Module Image.ILBM

ModuleInfo "Version: 1.01"
ModuleInfo "License: MIT"
ModuleInfo "Copyright: libiff/libilbm/libamivideo - 2012 Sander van der Burg"
ModuleInfo "Copyright: sdl ilbm image - 2012 Sander van der Burg & 2014 Roman Hiestand"
ModuleInfo "Copyright: Wrapper - 2022-2025 Bruce A Henderson"

ModuleInfo "History: 1.01 Fixed compilation error."
ModuleInfo "History: 1.00 Initial Release"

Import BRL.Pixmap

Import "common.bmx"

Private

Type TPixmapLoaderILBM Extends TPixmapLoader

	Method LoadPixmap:TPixmap( stream:TStream ) Override
	
		Local pixmap:TPixmap
	
		Local cb:TIlbmIoCallbacks = New TIlbmIoCallbacks
		cb.stream = stream
		
		
		Local chunkPtr:Byte Ptr = bmx_ilbm_load_iff(cb)

		If Not chunkPtr Then
			Return Null
		End If

		Local imagesLength:UInt
		Local imagesPtr:Byte Ptr Ptr = ILBM_extractImages(chunkPtr, imagesLength)

		If Not ILBM_checkImages(chunkPtr, imagesPtr, imagesLength) Or imagesLength = 0 Then
			ILBM_freeImages(imagesPtr, imagesLength)
			ILBM_free(chunkPtr)
			Return Null
		End If

		Local image:Byte Ptr = imagesPtr[0]
		Local rgbImage:SIlbmImageOut Ptr = bmx_ilbm_get_image(image, 0)

		If Not rgbImage Then
			ILBM_freeImages(imagesPtr, imagesLength)
			ILBM_free(chunkPtr)
			Return Null
		End If

		Local pix:TPixmap = CreatePixmap( rgbImage.width, rgbImage.height, PF_RGBA8888, 4 )
		MemCopy(pix.pixels, rgbImage.pixels, size_T(pix.width * pix.height * 4))

		free_(rgbImage)
		ILBM_freeImages(imagesPtr, imagesLength)
		ILBM_free(chunkPtr)

		' set alpha channel
		Local pixel:Byte Ptr = pix.pixels
		For Local i:Int = 0 until pix.width * pix.height
			pixel[3] = 255
			pixel :+ 4
		Next

		Return pix
	End Method

End Type

Type TIlbmIoCallbacks

	Field stream:TStream
	
	Method Read:Int(buffer:Byte Ptr, size:Int)
		Return stream.Read(buffer, size)
	End Method
	
	Method Write:Int(buffer:Byte Ptr, size:Int)
		Return stream.Write(buffer, size)
	End Method
	
	Method Eof:Int()
		Return stream.Eof()
	End Method

	Function _Read:Int(cb:TIlbmIoCallbacks, buffer:Byte Ptr, size:Int) { nomangle }
		Return cb.Read(buffer, size)
	End Function

	Function _Write:Int(cb:TIlbmIoCallbacks, buffer:Byte Ptr, size:Int) { nomangle }
		Return cb.Write(buffer, size)
	End Function

	Function _Eof:Int(cb:TIlbmIoCallbacks) { nomangle }
		Return cb.Eof()
	End Function
	
End Type

New TPixmapLoaderILBM