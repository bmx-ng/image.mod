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

Import "stb/*.h"
Import "glue.c"

Extern
	Function stbi_image_free(handle:Byte Ptr)
	Function bmx_stbi_load_image:Byte Ptr(cb:Object, width:Int Ptr, height:Int Ptr, channels:Int Ptr)
	Function bmx_stbi_load_gif:Byte Ptr(cb:Object, delays:Int Ptr Ptr, x:Int Var, y:Int Var, z:Int Var, comp:Int Var, requiredComp:Int)
	Function bmx_stbi_free_delays(delays:Int Ptr Ptr)
End Extern


Const STBI_grey:Int       = 1
Const STBI_grey_alpha:Int = 2
Const STBI_rgb:Int        = 3
Const STBI_rgb_alpha:Int  = 4
