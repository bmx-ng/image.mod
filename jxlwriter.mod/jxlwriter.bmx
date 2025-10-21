'
' Copyright (c) 2022 Bruce A Henderson
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
bbdoc: Image/JXL Writer
about: The JXL writer module provides the ability to save JXL format #pixmaps.
End Rem
Module Image.JXLWriter

ModuleInfo "Version: 1.00"
ModuleInfo "License: BSD"
ModuleInfo "Copyright: Wrapper - 2022 Bruce A Henderson"

ModuleInfo "History: 1.00"
ModuleInfo "History: Initial Release."

ModuleInfo "CPP_OPTS: -std=c++11"
ModuleInfo "CC_OPTS: -DJPEGXL_MAJOR_VERSION=0"
ModuleInfo "CC_OPTS: -DJPEGXL_MINOR_VERSION=7"
ModuleInfo "CC_OPTS: -DJPEGXL_PATCH_VERSION=0"

ModuleInfo "CC_OPTS: -DHAVE_PROTOTYPES"

?ptr64

Import "common.bmx"


Rem
bbdoc: 
End Rem
Function SavePixmapJxl:Int( pixmap:TPixmap, url:Object, useLossless:Int = True, distance:Float = 0 )

	Local stream:TStream=WriteStream( url )
	If Not stream Return False
	
	Local encoder:TJxlEncoder = New TJxlEncoder()
	Local result:Int = encoder.Save(pixmap, stream, useLossless, distance)

	stream.Close
	Return result
End Function

Rem
bbdoc: Number of threads to use during Jxl encoding.
about: The default is to use only the current thread.
End Rem
Global JxlEncoderThreadCount:Int = 0

Private

Type TJxlEncoder

	Field encoderPtr:Byte Ptr
	Field runnerPtr:Byte Ptr

	Method New()
		encoderPtr = JxlEncoderCreate(Null)
		runnerPtr = JxlResizableParallelRunnerCreate(Null)
	End Method

	Method Save:Int(pixmap:TPixmap, stream:TStream, useLossless:Int, distance:Float)

		If bmx_jxl_JxlEncoderSetParallelRunner(encoderPtr, runnerPtr) <> JXL_ENC_SUCCESS Then
			Return False
		End If

		JxlResizableParallelRunnerSetThreads(runnerPtr, Size_T(Max(0, JxlEncoderThreadCount)))

		Local align:Int = pixmap.pitch - ((BytesPerPixel[pixmap.format] * pixmap.width) - 1)
		If align <> 1 Then
			align = 4
		End If
		Local info:SJxlBasicInfo
		JxlEncoderInitBasicInfo(info)
		info.xsize = pixmap.width
		info.ysize = pixmap.height
		info.bits_per_sample = 8
		info.alpha_bits = AlphaBitsPerPixel[pixmap.format]
		info.num_color_channels = BytesPerPixel[pixmap.format] - (AlphaBitsPerPixel[pixmap.format] > 0)
		info.num_extra_channels = AlphaBitsPerPixel[pixmap.format] > 0

		If useLossless Then
			info.uses_original_profile = True
		End If

		Local format:SJxlPixelFormat = New SJxlPixelFormat(UInt(BytesPerPixel[pixmap.format]), EJxlDataType.JXL_TYPE_UINT8, EJxlEndianness.JXL_NATIVE_ENDIAN, Size_T(align))

		If JxlEncoderSetBasicInfo(encoderPtr, info) <> JXL_ENC_SUCCESS Then
			Return False
		End If

		Local colorEncoding:SJxlColorEncoding
		JxlColorEncodingSetToSRGB(colorEncoding, pixmap.format = PF_I8)

		If JxlEncoderSetColorEncoding(encoderPtr, colorEncoding) <> JXL_ENC_SUCCESS Then
			Return False
		End If

		Local frameSettingsPtr:Byte Ptr = JxlEncoderFrameSettingsCreate(encoderPtr, Null)

		If useLossless Then
			JxlEncoderSetFrameLossless(frameSettingsPtr, True)
		End If
		JxlEncoderSetFrameDistance(frameSettingsPtr, distance)

		If JxlEncoderAddImageFrame(frameSettingsPtr, format, pixmap.pixels, Size_T(pixmap.pitch * pixmap.height)) <> JXL_ENC_SUCCESS Then
			Return False
		End If

		JxlEncoderCloseInput(encoderPtr)

		Local compressed:Byte[1024]
		Local nextOut:Byte Ptr = compressed
		Local availOut:Size_T = compressed.Length

		Local result:Int = JXL_ENC_NEED_MORE_OUTPUT

		While result = JXL_ENC_NEED_MORE_OUTPUT
			result = JxlEncoderProcessOutput(encoderPtr, VarPtr nextOut, availOut)

			If result = JXL_ENC_NEED_MORE_OUTPUT Then
				Local offset:Size_T = nextOut - compressed
				compressed = compressed[..compressed.Length * 2]
				nextOut = Byte Ptr(compressed) + offset
				availOut = compressed.Length - offset
			End If
		Wend

		Local size:Size_T = nextOut - Byte Ptr(compressed)
		compressed = compressed[..size]

		If result <> JXL_ENC_SUCCESS Then
			Return False
		End If

		stream.Write(compressed, compressed.Length)

		Return True

	End Method

	Method Free()
		If runnerPtr Then
			JxlResizableParallelRunnerDestroy(runnerPtr)
			runnerPtr = Null
		End If

		If encoderPtr Then
			JxlEncoderDestroy(encoderPtr)
			encoderPtr = Null
		End If
	End Method

	Method Delete()
		Free()
	End Method

End Type

?
