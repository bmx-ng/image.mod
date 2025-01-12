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

Import "source.bmx"

Extern
	Function bmx_ilbm_load_iff:Byte Ptr(callbacks:Object)
	Function bmx_ilbm_get_image:SIlbmImageOut Ptr(ilbmImage:Byte Ptr, pixelScaleFactor:UInt)
	Function ILBM_extractImages:Byte Ptr Ptr(handle:Byte Ptr, imagesLength:UInt Var)
	Function ILBM_checkImages:Int(handle:Byte Ptr, images:Byte Ptr Ptr, imagesLength:UInt)
	Function ILBM_freeImages(images:Byte Ptr Ptr, imagesLength:UInt)
	Function ILBM_free(handle:Byte Ptr)
End Extern

Struct SIlbmImageOut
	Field width:UInt
	Field height:UInt
	Field depth:UInt
	Field colorsCount:UInt
	Field palette:Byte Ptr
	Field pixels:Byte Ptr
End Struct
