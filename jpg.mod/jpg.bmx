' Copyright (c) 2022 Bruce A Henderson
' Copyright (c) 2007- Blitz Research Ltd
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
bbdoc: Image/JPG Loader
about: The JPG loader module provides the ability to load JPG format #pixmaps.
End Rem
Module Image.JPG

ModuleInfo "Version: 1.06"
ModuleInfo "Author: Simon Armstrong, Jeffrey D. Panici"
ModuleInfo "License: zlib/libpng"
ModuleInfo "Copyright: Blitz Research Ltd"
ModuleInfo "Modserver: BRL"

ModuleInfo "History: 1.06"
ModuleInfo "History: Moved to image namespace"
ModuleInfo "History: 1.05 Release"
ModuleInfo "History: Fixed SavePixmapJPeg"
ModuleInfo "History: 1.04 Release"
ModuleInfo "History: Removed print"
ModuleInfo "History: 1.03 Release"
ModuleInfo "History: Changed ReadBytes to Read for loader"
ModuleInfo "History: Added SaveJPEG function, thanks to Jeffrey D. Panici for the writefunc `fix'"
ModuleInfo "History: 1.02 Release"
ModuleInfo "History: Added support for monochrome / single channel"

Import BRL.pixmap

Import "common.bmx"

Private

Function readfunc:Int( buf:Byte Ptr,count:Int,src:Object )
	Local stream:TStream
	stream=TStream(src)
	Local n:Int=stream.Read( buf,count )
	Return n
End Function

Function writefunc:Int( buf:Byte Ptr,count:Int,src:Object )
	Local stream:TStream
	stream=TStream(src)
	Local n:Int=stream.Write( buf,count )
	Return n
End Function

Public

Rem
bbdoc: Load a Pixmap in JPeg format
about:
#LoadPixmapJPeg loads a pixmap from @url in JPeg format.

If the pixmap cannot be loaded, Null is returned.
End Rem
Function LoadPixmapJPeg:TPixmap( url:Object )

	Local	jpg:Int,width:Int,height:Int,depth:Int,y:Int
	Local	pix:Byte Ptr	
	Local	pixmap:TPixmap
	Local	stream:TStream
	
	stream=ReadStream( url )
	If Not stream Return Null
	
	Local res:Int=loadjpg(stream,readfunc,width,height,depth,pix)
	stream.Close
	If res Return Null
	
	If width=0 Return Null
	Select depth
	Case 1
		pixmap=CreatePixmap( width,height,PF_I8 )
		For y=0 Until height
			CopyPixels pix+y*width,pixmap.PixelPtr(0,y),PF_I8,width
		Next
	Case 3
		pixmap=CreatePixmap( width,height,PF_RGB888 )
		For y=0 Until height
			CopyPixels pix+y*width*3,pixmap.PixelPtr(0,y),PF_RGB888,width
		Next
	End Select
	free_ pix			
	Return pixmap
End Function

Rem
bbdoc: Save a Pixmap in JPeg format
about:
Saves @pixmap to @url in JPeg format. If successful, #SavePixmapJPeg returns
True, otherwise False.

The optional @quality parameter should be in the range 0 to 100, where
0 indicates poor quality (smallest) and 100 indicates best quality (largest).
End Rem
Function SavePixmapJPeg:Int( pixmap:TPixmap,url:Object,quality:Int=75 )

	quality = Min( Max( quality, 1 ), 100 )

	Local stream:TStream=WriteStream( url )
	If Not stream Return False
	
	pixmap=pixmap.convert(PF_RGB888)

	Local pix:Byte Ptr=pixmap.PixelPtr( 0,0 )

	savejpg(stream,writefunc,pixmap.width,pixmap.height,pixmap.pitch,pix,quality)

	stream.Close
	Return True
End Function

Private

Type TPixmapLoaderJPG Extends TPixmapLoader
	Method LoadPixmap:TPixmap( stream:TStream ) Override
		Return LoadPixmapJPeg( stream )
	End Method
End Type

New TPixmapLoaderJPG
