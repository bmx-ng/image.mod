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

Import "source.bmx"

Extern
	Function WebPGetInfo:Int(data:Byte Ptr, data_size:Size_T, width:Int Var, height:Int Var)
	Function WebPDecodeRGBAInto:Byte Ptr(data:Byte Ptr, data_size:Size_t, output_buffer:Byte Ptr, output_buffer_size:Size_T, output_stride:Int)
End Extern
