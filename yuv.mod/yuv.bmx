'
' Copyright (c) 2024 Bruce A Henderson
' All rights reserved.
'
' Redistribution and use in source and binary forms, with or without
' modification, are permitted provided that the following conditions are met:
'     * Redistributions of source code must retain the above copyright
'       notice, this list of conditions and the following disclaimer.
'     * Redistributions in binary form must reproduce the above copyright
'       notice, this list of conditions and the following disclaimer in the
'       documentation and/or other materials provided with the distribution.
'     * Neither the name of the author nor the
'       names of its contributors may be used to endorse or promote products
'       derived from this software without specific prior written permission.
'
' THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY
' EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
' WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
' DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
' DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
' (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
' LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
' ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
' (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
' SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
'
SuperStrict

Rem
bbdoc: Image/YUV-ARGB Converter
about: Provides functions to convert between YUV and RGB.
End Rem
Module Image.yuv

ModuleInfo "Version: 1.00"
ModuleInfo "License: BSD"
ModuleInfo "Copyright: Wrapper - 2024 Bruce A Henderson"

ModuleInfo "History: 1.00"
ModuleInfo "History: Initial Release."

ModuleInfo "CC_OPTS: -DLIBYUV_DISABLE_NEON"
ModuleInfo "CC_OPTS: -DLIBYUV_DISABLE_SVE"

Import brl.pixmap

Import "common.bmx"


Rem
bbdoc: Converts I420 YUV planar data to ARGB, populating a TPixmap of the same size.
End Rem
Function ConvertI420ToARGB:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:TPixmap)
	Return I420ToARGB(srcY, strideY, srcU, strideU, srcV, strideV, dst.pixels, dst.pitch, dst.width, dst.height)
End Function

Rem
bbdoc: Converts I420 YUV planar data to ABGR, populating a TPixmap of the same size.
End Rem
Function ConvertI420ToABGR:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:TPixmap)
	Return I420ToABGR(srcY, strideY, srcU, strideU, srcV, strideV, dst.pixels, dst.pitch, dst.width, dst.height)
End Function

Rem
bbdoc: Converts J420 YUV planar data to ARGB.
End Rem
Function ConvertJ420ToARGB:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return J420ToARGB(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function

Rem
bbdoc: Converts J420 YUV planar data to ABGR.
End Rem
Function ConvertJ420ToABGR:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return J420ToABGR(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function

Rem
bbdoc: Converts H420 YUV planar data to ARGB.
End Rem
Function ConvertH420ToARGB:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return H420ToARGB(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function

Rem
bbdoc: Converts H420 YUV planar data to ABGR.
End Rem
Function ConvertH420ToABGR:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return H420ToABGR(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function

Rem
bbdoc: Converts U420 YUV planar data to ARGB.
End Rem
Function ConvertU420ToARGB:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return U420ToARGB(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function

Rem
bbdoc: Converts U420 YUV planar data to ABGR.
End Rem
Function ConvertU420ToABGR:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return U420ToABGR(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function

Rem
bbdoc: Converts I422 YUV planar data to ARGB.
End Rem
Function ConvertI422ToARGB:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return I422ToARGB(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function

Rem
bbdoc: Converts I422 YUV planar data to ABGR.
End Rem
Function ConvertI422ToABGR:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return I422ToABGR(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function

Rem
bbdoc: Converts J422 YUV planar data to ARGB.
End Rem
Function ConvertJ422ToARGB:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return J422ToARGB(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function

Rem
bbdoc: Converts J422 YUV planar data to ABGR.
End Rem
Function ConvertJ422ToABGR:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return J422ToABGR(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function

Rem
bbdoc: Converts H422 YUV planar data to ARGB.
End Rem
Function ConvertH422ToARGB:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return H422ToARGB(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function

Rem
bbdoc: Converts H422 YUV planar data to ABGR.
End Rem
Function ConvertH422ToABGR:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return H422ToABGR(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function

Rem
bbdoc: Converts U422 YUV planar data to ARGB.
End Rem
Function ConvertU422ToARGB:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return U422ToARGB(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function

Rem
bbdoc: Converts U422 YUV planar data to ABGR.
End Rem
Function ConvertU422ToABGR:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return U422ToABGR(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function

Rem
bbdoc: Converts I444 YUV planar data to ARGB.
End Rem
Function ConvertI444ToARGB:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return I444ToARGB(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function

Rem
bbdoc: Converts I444 YUV planar data to ABGR.
End Rem
Function ConvertI444ToABGR:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return I444ToABGR(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function

Rem
bbdoc: Converts J444 YUV planar data to ARGB.
End Rem
Function ConvertJ444ToARGB:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return J444ToARGB(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function

Rem
bbdoc: Converts J444 YUV planar data to ABGR.
End Rem
Function ConvertJ444ToABGR:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return J444ToABGR(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function

Rem
bbdoc: Converts H444 YUV planar data to ARGB.
End Rem
Function ConvertH444ToARGB:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return H444ToARGB(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function

Rem
bbdoc: Converts H444 YUV planar data to ABGR.
End Rem
Function ConvertH444ToABGR:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return H444ToABGR(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function

Rem
bbdoc: Converts U444 YUV planar data to ARGB.
End Rem
Function ConvertU444ToARGB:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return U444ToARGB(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function

Rem
bbdoc: Converts U444 YUV planar data to ABGR.
End Rem
Function ConvertU444ToABGR:Int(srcY:Byte Ptr, strideY:Int, srcU:Byte Ptr, strideU:Int, srcV:Byte Ptr, strideV:Int, dst:Byte Ptr, dstStride:Int, width:Int, height:Int)
	Return U444ToABGR(srcY, strideY, srcU, strideU, srcV, strideV, dst, dstStride, width, height)
End Function
