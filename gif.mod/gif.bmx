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
bbdoc: Image/GIF Loader
about: The GIF loader module provides the ability to load GIF format #pixmaps.
End Rem
Module Image.GIF

Import BRL.Max2D
Import Image.Stb

Rem
bbdoc: A GIF image.
End Rem
Type TGifImage
	
	Field imgPtr:Byte Ptr
	Field delays:Int Ptr
	Field w:Int
	Field h:Int
	Field layers:Int
	Field comp:Int
	
	Function Load:TGifImage(url:Object)
		Local stream:TStream=ReadStream( url )
		If Not stream Throw New TStreamReadException
		
		Local gif:TGifImage = New TGifImage()
		
		Local cb:TStbioCallbacks = New TStbioCallbacks
		cb.stream = stream
		
		gif.imgPtr = bmx_stbi_load_gif(cb, Varptr gif.delays, gif.w, gif.h, gif.layers, gif.comp, 0)
		
		If Not gif.imgPtr Then
			Return Null
		End If
		
		Return gif
	EndFunction
	
	Method ToPixmap:TPixmap(layer:Int)
		Local pitch:Int = w * comp
		Local size:Size_T = w * h * comp
		
		If layer > layers
			layer = layers-1
		ElseIf layer < 0
			layer = 0
		EndIf
		
		Local pixmap:TPixmap = CreatePixmap( w, h, PF_RGBA8888, 4 )
		
		MemCopy( pixmap.pixels, imgPtr + pitch * h * layer, size )
		
		Return pixmap
	EndMethod
	
	Method ToImage:TImage(flags:Int=-1)
		Local pitch:Int = w * comp
		Local size:Size_T = w * h * comp

		Local image:TImage = CreateImage(w, h, layers, flags)

		For Local i:Int = 0 Until layers
			Local pixmap:TPixmap = CreatePixmap( w, h, PF_RGBA8888, 4 )
			MemCopy( pixmap.pixels, imgPtr + pitch * h * i, size )
			image.SetPixmap(i, pixmap, delays[i])
		Next

		stbi_image_free(imgPtr)
		bmx_stbi_free_delays(Varptr delays)

		Return image
	EndMethod
	
	Rem
	bbdoc: Loads one layer/frame of a GIF image as a #TPixmap.
	returns: A #TPixmap, or #Null if the image could not be loaded.
	EndRem
	Function LoadPixmap:TPixmap(url:Object, layer:Int=0)
		Local gif:TGifImage = TGifImage.Load(url)
		
		If Not gif
			Return Null
		EndIf
		
		Return gif.ToPixmap(layer)
	EndFunction
	
	Rem
	bbdoc: Loads a GIF image as a #TImage.
	returns: A #TImage, or #Null if the image could not be loaded.
	about: For animated GIF images, the #TImage will be created with the appropriate frames and frame durations.
	End Rem
	Function LoadImage:TImage(url:Object, flags:Int=-1)
		Local gif:TGifImage = TGifImage.Load(url)
		
		If Not gif
			Return Null
		EndIf
		
		Return gif.ToImage(flags)
	EndFunction
	
	Method Free()
		If imgPtr
			stbi_image_free(imgPtr)
		EndIf
		If delays
			bmx_stbi_free_delays(Varptr delays)
		EndIf
	EndMethod
	
	Method Delete()
		Free()
	EndMethod

End Type
