' Copyright (c) 2022-2024 Bruce A Henderson
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

Module Image.STB

ModuleInfo "Version: 1.06"
ModuleInfo "Author: Sean Barrett and contributers (see stb_image.h)"
ModuleInfo "License: ZLib/PNG License"
ModuleInfo "Credit: Adapted for BlitzMax by Bruce A Henderson"

ModuleInfo "History: 1.06"
ModuleInfo "History: Update to stb_image 2.30"
ModuleInfo "History: Update to stb_image_resize2 2.10"
ModuleInfo "History: Fixed gif build."
ModuleInfo "History: 1.05"
ModuleInfo "History: Update to stb_image 2.29"
ModuleInfo "History: 1.04"
ModuleInfo "History: Update to stb_image 2.28"
ModuleInfo "History: 1.03"
ModuleInfo "History: Update to stb_image 2.27"
ModuleInfo "History: 1.02"
ModuleInfo "History: Update to stb_image 2.19"
ModuleInfo "History: 1.01"
ModuleInfo "History: Update to stb_image 2.16"
ModuleInfo "History: 1.00"
ModuleInfo "History: Initial Release. stb_image 2.13"

Import BRL.Pixmap

Import "common.bmx"

' Notes
' stbi__compute_y_16() and stbi__convert_format16() need aditional  "&& defined(STBI_NO_PNM)"

Private

Type TPixmapLoaderSTB Extends TPixmapLoader

	Method LoadPixmap:TPixmap( stream:TStream ) Override
	
		Local pixmap:TPixmap
	
		Local cb:TStbioCallbacks = New TStbioCallbacks
		cb.stream = stream
		
		Local width:Int, height:Int, channels:Int
		
		Local imgPtr:Byte Ptr = bmx_stbi_load_image(cb, Varptr width, Varptr height, Varptr channels)
		
		If imgPtr Then
		
			Local pf:Int
		
			Select channels
				Case STBI_grey
					pf = PF_I8
				Case STBI_rgb
					pf = PF_RGB888
				Case STBI_rgb_alpha
					pf = PF_RGBA8888
				Case STBI_grey_alpha
					pixmap = CreatePixmap( width,height,PF_RGBA8888 )
					
					Local src:Byte Ptr = imgPtr
					Local dst:Byte Ptr = pixmap.pixels

					For Local y:Int = 0 Until height
						For Local x:Int = 0 Until width
							Local a:Int=src[0]
							Local i:Int=src[1]
							dst[0] = i
							dst[1] = i
							dst[2] = i
							dst[3] = a
							src:+2
							dst:+4
						Next
					Next
			End Select
			
			If pf Then
				pixmap = CreatePixmap( width, height, pf )

				MemCopy(pixmap.pixels, imgPtr, Size_T(width * height * BytesPerPixel[pf]))
			End If
			
			stbi_image_free(imgPtr)
		
		End If
	
		Return pixmap
		
	End Method

End Type

Public

Type TStbioCallbacks

	Field stream:TStream
	
	Method Read:Int(buffer:Byte Ptr, size:Int)
		Return stream.Read(buffer, size)
	End Method
	
	Method Skip(n:Int)
		stream.Seek(SEEK_CUR_, n)
	End Method
	
	Method Eof:Int()
		Return stream.Eof()
	End Method

	Function _Read:Int(cb:TStbioCallbacks, buffer:Byte Ptr, size:Int) { nomangle }
		Return cb.Read(buffer, size)
	End Function

	Function _Skip(cb:TStbioCallbacks, n:Int) { nomangle }
		cb.Skip(n)
	End Function

	Function _Eof:Int(cb:TStbioCallbacks) { nomangle }
		Return cb.Eof()
	End Function
	
End Type

Private
New TPixmapLoaderSTB
