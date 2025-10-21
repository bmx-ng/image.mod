' Copyright (c) 2023 Bruce A Henderson
' 
' Redistribution and use in source and binary forms, with or without
' modification, are permitted provided that the following conditions
' are met:
' 1. Redistributions of source code must retain the above copyright
'    notice, this list of conditions and the following disclaimer.
' 2. Redistributions in binary form must reproduce the above copyright
'    notice, this list of conditions and the following disclaimer in the
'    documentation and/or other materials provided with the distribution.
' 
' THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
' IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
' ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
' LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
' CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
' SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
' INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
' CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
' ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
' POSSIBILITY OF SUCH DAMAGE.
'
SuperStrict

Rem
bbdoc: Image/JPEG 2000 Loader
about: The JPEG2000 loader module provides the ability to load JPEG 2000 format #pixmaps.
End Rem
Module Image.JPEG2000

ModuleInfo "Version: 1.00"
ModuleInfo "License: BSD 2-Clause"
ModuleInfo "Copyright: Wrapper - 2023 Bruce A Henderson"

ModuleInfo "History: 1.00 Initial Release"

?win32
ModuleInfo "CC_OPTS: -DOPJ_STATIC"
?

Import "common.bmx"


Type TJpeg2000Image

	Function Load:TPixmap( stream:TStream )
		Return bmx_jpeg2000_load( stream )
	End Function

	Function _NewPixmap:TPixmap(width:Int, height:Int) { nomangle }
		Return TPixmap.Create( width,height,PF_STDFORMAT,4)
	End Function

	Function _PixmapPixels:Byte Ptr(pix:TPixmap) { nomangle }
		Return pix.pixels
	End Function

	Function _stream_seek:Int(pos:Long, stream:TStream) { nomangle }
		Local res:Long = stream.seek(pos)
		If res = -1 Then
			Return False
		Else
			Return True
		End If
	End Function
	
	Function _stream_read:Size_T(buf:Byte Ptr, count:Size_T, stream:TStream) { nomangle }

		Local res:Long = stream.Read(buf, count)

		If res = -1 Then
			Return 0
		Else
			Return res
		End If
	End Function

	Function _stream_skip:Long(count:Long, stream:TStream) { nomangle }
		Return stream.seek(count, SEEK_CUR_)
	End Function

	Function _stream_size:Size_T(stream:TStream) { nomangle }
		Return stream.size()
	End Function
		
End Type

Private

Type TPixmapLoaderJPG2000 Extends TPixmapLoader
	Method LoadPixmap:TPixmap( stream:TStream ) Override
		Return TJpeg2000Image.Load( stream )
	End Method
End Type

New TPixmapLoaderJPG2000

Extern
	Function bmx_jpeg2000_load:TPixmap( stream:TStream )
End Extern
