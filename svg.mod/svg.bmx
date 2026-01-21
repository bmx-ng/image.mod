' Copyright (c) 2024 Bruce A Henderson
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
bbdoc: Image/SVG Loader
about: The SVG loader module provides the ability to load SVG format #pixmaps.
End Rem
Module Image.SVG

ModuleInfo "Version: 1.03"
ModuleInfo "Author: 2020 Nwutobo Samuel Ugochukwu <sammycageagle@gmail.com>"
ModuleInfo "License: MIT License"
ModuleInfo "Credit: Adapted for BlitzMax by Bruce A Henderson"

ModuleInfo "History: 1.03"
ModuleInfo "History: Changed to use lunasvg, which supports more SVG features."
ModuleInfo "History: 1.02"
ModuleInfo "History: Added support for scaling images into a pixmap of a specified size."
ModuleInfo "History: 1.01"
ModuleInfo "History: Update to nanosvg 706eb06"
ModuleInfo "History: 1.00"
ModuleInfo "History: Initial Release. nanosvg"

ModuleInfo "CPP_OPTS: -DLUNASVG_BUILD_STATIC"
ModuleInfo "CPP_OPTS: -std=c++11"
ModuleInfo "C_OPTS: -std=c11"

Import BRL.Pixmap
Import "common.bmx"


Rem
bbdoc: An SVG image.
End Rem
Type TSvgImage

	Field svgDocument:Byte Ptr

	Rem
	bbdoc: Loads an SVG image from a stream.
	End Rem
	Method Load:TPixmap(stream:TStream)
		Local data:Byte[] = LoadByteArray( stream )
		
		svgDocument = bmx_svg_loadFromData(data, data.Length)

		If Not svgDocument
			Return Null
		End If

		Return GetPixmap(Int(Width()), Int(Height()))
	End Method

	Rem
	bbdoc: Loads an SVG image from a file, either a path or a stream.
	End Rem
	Function LoadImage:TSvgImage(obj:Object)
		Local image:TSvgImage = New TSvgImage()

		Local data:Byte[] = LoadByteArray( obj )

		image.svgDocument = bmx_svg_loadFromData(data, data.Length)

		Return image
	End Function

	Rem
	bbdoc: Loads an SVG image from a string.
	End Rem
	Function LoadFromData:TSvgImage(txt:String)
		Local image:TSvgImage = New TSvgImage()

		Local s:Byte Ptr = txt.ToUTF8String()
		Local length:Int = strlen_(s)

		image.svgDocument = bmx_svg_loadFromData(s, length)

		MemFree(s)

		Return image
	End Function

	Rem
	bbdoc: Returns the width of the SVG image.
	End Rem
	Method Width:Double()
		If svgDocument Then
			Return bmx_svg_width(svgDocument)
		End If
	End Method

	Rem
	bbdoc: Returns the height of the SVG image.
	End Rem
	Method Height:Double()
		If svgDocument Then
			Return bmx_svg_height(svgDocument)
		End If
	End Method

	Rem
	bbdoc: Gets a rasterized representation of the SVG image of the specified size.
	End Rem
	Method GetPixmap:TPixmap(width:Int, height:Int)
		If svgDocument Then
			Local pix:TPixmap = CreatePixmap( width, height, PF_RGBA8888, 4 )

			bmx_svg_renderToPixmap(svgDocument, pix.pixels, pix.width, pix.height, pix.pitch)

			Return pix
		End If
	End Method

	Rem
	bbdoc: Returns the dimensions of the SVG image.
	End Rem
	Method Dimensions(width:Double Var, height:Double Var)
		If svgDocument Then
			width = Self.Width()
			height = Self.Height()
		End If
	End Method

	Rem
	bbdoc: Gets a rasterized representation of the SVG image that fits within the specified maximum width and height.
	about: The aspect ratio of the image is maintained.
	If the height is not specified, it will be the same as the width.
	End Rem
	Method FitPixmap:TPixmap(maxWidth:Int, maxHeight:Int = 0)
		Local width:Double
		Local height:Double
		Dimensions(width, height)

		If maxHeight = 0 Then
			maxHeight = maxWidth
		End If

		Local ratio:Float = Min(maxWidth / width, maxHeight / height)

		Return GetPixmap(Int(width * ratio), Int(height * ratio))
	End Method

	Rem
	bbdoc: Sets the dimensions of the SVG image.
	End Rem
	Method SetDimensions(width:Double, height:Double)
		If svgDocument
			bmx_svg_setDimensions(svgDocument, width, height)
		End If
	End Method

	Method Free()
		If svgDocument
			bmx_svg_free(svgDocument)
			svgDocument = Null
		End If
	End Method

	Method Delete()
		Free()
	End Method
End Type

Private

Type TPixmapLoaderSvg Extends TPixmapLoader

	Method LoadPixmap:TPixmap( stream:TStream ) Override
		Local image:TSvgImage = New TSvgImage()
		Local pix:TPixmap = image.Load(stream)
		image.Free()
		Return pix
	End Method

End Type

New TPixmapLoaderSvg

