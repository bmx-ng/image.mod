' Copyright (c) 2021-2023 Bruce A Henderson
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
bbdoc: Image/WebP Loader
about: The WebP loader module provides the ability to load WebP format #pixmaps.
End Rem
Module Image.Webp

ModuleInfo "Version: 1.02"
ModuleInfo "License: libwebp - BSD"
ModuleInfo "License: Wrapper - zlib/libpng"
ModuleInfo "Copyright: libwebp - 2010 Google"
ModuleInfo "Copyright: Wrapper - 2021-2023 Bruce A Henderson"

ModuleInfo "History: 1.02"
ModuleInfo "History: Updated to libwebp 1.3.2.d7a0506"
ModuleInfo "History: 1.01"
ModuleInfo "History: Updated to libwebp 1.3.2."
ModuleInfo "History: 1.00"
ModuleInfo "History: Initial Release."

Import BRL.Pixmap

Import "common.bmx"

Private

Type TPixmapLoaderWebp Extends TPixmapLoader

	Method LoadPixmap:TPixmap( stream:TStream ) Override
		
		Local data:Byte[] = LoadByteArray(stream)

		If data Then

			Local width:Int
			Local height:Int

			If WebPGetInfo(data, Size_T(data.Length), width, height) Then

				Local pix:TPixmap = CreatePixmap( width, height, PF_RGBA8888, 4)

				Local res:Byte Ptr = WebPDecodeRGBAInto(data, Size_T(data.Length), pix.pixels, Size_T(width * height * 4), pix.pitch)

				If res Then
					Return pix
				End If
			End If

		End If

	End Method

End Type

New TPixmapLoaderWebp
