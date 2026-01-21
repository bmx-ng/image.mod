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
bbdoc: Image/JXL Loader
about: The JXL loader module provides the ability to load JXL format #pixmaps.
End Rem
Module Image.JXL

ModuleInfo "Version: 1.00"
ModuleInfo "License: BSD"
ModuleInfo "Copyright: Wrapper - 2022 Bruce A Henderson"

ModuleInfo "History: 1.00"
ModuleInfo "History: Initial Release."

ModuleInfo "CPP_OPTS: -std=c++11 -D__STDC_FORMAT_MACROS"
ModuleInfo "C_OPTS: -std=c99"
ModuleInfo "CC_OPTS: -DJPEGXL_MAJOR_VERSION=0"
ModuleInfo "CC_OPTS: -DJPEGXL_MINOR_VERSION=7"
ModuleInfo "CC_OPTS: -DJPEGXL_PATCH_VERSION=0"

?ptr64
Import "common.bmx"

Rem
bbdoc: Number of threads to use during Jxl decoding.
about: The default is to use only the current thread.
End Rem
Global JxlDecoderThreadCount:Int = 0

Private

Type TPixmapLoaderJXL Extends TPixmapLoader

	Method LoadPixmap:TPixmap( stream:TStream ) Override
		
		Local data:Byte[] = LoadByteArray(stream)

		If data Then

			Local sig:EJxlSignature = JxlSignatureCheck(data, Size_T(data.Length))

			If sig = EJxlSignature.JXL_SIG_NOT_ENOUGH_BYTES Or sig = EJxlSignature.JXL_SIG_INVALID Then
				Return Null
			End If

			Local decoder:TJxlDecoder = New TJxlDecoder()

			Local pix:TPixmap = decoder.Load(data)

			Return pix

		End If

	End Method

End Type

Type TJxlDecoder

	Field decoderPtr:Byte Ptr
	Field runnerPtr:Byte Ptr

	Method New()
		decoderPtr = JxlDecoderCreate(Null)
	End Method

	Method Load:TPixmap(data:Byte[])
		Local pix:TPixmap

		Local status:Int = JxlDecoderSubscribeEvents(decoderPtr, JXL_DEC_BASIC_INFO | JXL_DEC_FULL_IMAGE)

		If status <> JXL_DEC_SUCCESS Then
			Return Null
		End If

		runnerPtr = JxlResizableParallelRunnerCreate(Null)
		JxlResizableParallelRunnerSetThreads(runnerPtr, Size_T(Max(0, JxlDecoderThreadCount)))

		If bmx_jxl_JxlDecoderSetParallelRunner(decoderPtr, runnerPtr) <> JXL_DEC_SUCCESS Then
			Return Null
		End If

		Local info:SJxlBasicInfo
		Local format:SJxlPixelFormat = New SJxlPixelFormat(4, EJxlDataType.JXL_TYPE_UINT8, EJxlEndianness.JXL_BIG_ENDIAN, 4)
		Local pixFormat:Int = PF_RGBA8888

		Local width:Int
		Local height:Int

		JxlDecoderSetInput(decoderPtr, data, Size_T(data.Length))
		JxlDecoderCloseInput(decoderPtr)

		While True

			status = JxlDecoderProcessInput(decoderPtr)

			If status = JXL_DEC_ERROR Then

				Return Null

			Else If status = JXL_DEC_NEED_MORE_INPUT Then
				Return Null
			Else If status = JXL_DEC_BASIC_INFO Then

				If JxlDecoderGetBasicInfo(decoderPtr, info) <> JXL_DEC_SUCCESS Then
					Return Null
				End If
				width = info.xsize
				height = info.ysize

				If info.alpha_bits = 0 Then
					format.num_channels = 3
					format.align = 4
					pixFormat = PF_RGB888
				End If

				pix = TPixmap.Create(width, height, pixFormat, Int(format.align))
				
			Else If status = JXL_DEC_NEED_IMAGE_OUT_BUFFER Then

				Local bufferSize:Size_T
				If JxlDecoderImageOutBufferSize(decoderPtr, format, bufferSize) <> JXL_DEC_SUCCESS Then
					Return Null
				End If

				If JxlDecoderSetImageOutBuffer(decoderPtr, format, pix.pixels, Size_T(pix.capacity)) <> JXL_DEC_SUCCESS Then
					Return Null
				End If

			Else If status = JXL_DEC_FULL_IMAGE Then

				Exit

			Else If status = JXL_DEC_SUCCESS Then

				Exit
			Else
				Return Null
			End If

		Wend

		Return pix
	End Method

	Method Free()
		If runnerPtr Then
			JxlResizableParallelRunnerDestroy(runnerPtr)
			runnerPtr = Null
		End If

		If decoderPtr Then
			JxlDecoderDestroy(decoderPtr)
			decoderPtr = Null
		End If
	End Method

	Method Delete()
		Free()
	End Method

End Type

New TPixmapLoaderJXL

?
