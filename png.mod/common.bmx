' Copyright (c) 2022-2025 Bruce A Henderson
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

Import Archive.ZLib
Import "../../archive.mod/zlib.mod/zlib/*.h"

Import "libpng/png.c"
Import "libpng/pngerror.c"
Import "libpng/pngget.c"
Import "libpng/pngmem.c"
Import "libpng/pngpread.c"
Import "libpng/pngread.c"
Import "libpng/pngrio.c"
Import "libpng/pngrtran.c"
Import "libpng/pngrutil.c"
Import "libpng/pngset.c"
Import "libpng/pngtrans.c"
Import "libpng/pngwio.c"
Import "libpng/pngwrite.c"
Import "libpng/pngwtran.c"
Import "libpng/pngwutil.c"
?armv7 or arm64 or arm
Import "libpng/arm/arm_init.c"
Import "libpng/arm/filter_neon_intrinsics.c"
Import "libpng/arm/palette_neon_intrinsics.c"
?x86
Import "libpng/intel/filter_sse2_intrinsics.c"
Import "libpng/intel/intel_init.c"
?x64
Import "libpng/intel/filter_sse2_intrinsics.c"
Import "libpng/intel/intel_init.c"
?

Extern

Const PNG_COLOR_MASK_PALETTE:Int=		1
Const PNG_COLOR_MASK_COLOR:Int=			2
Const PNG_COLOR_MASK_ALPHA:Int=			4

Const PNG_COLOR_TYPE_GRAY:Int=			0
Const PNG_COLOR_TYPE_PALETTE:Int=		(PNG_COLOR_MASK_COLOR | PNG_COLOR_MASK_PALETTE)
Const PNG_COLOR_TYPE_RGB:Int=			(PNG_COLOR_MASK_COLOR)
Const PNG_COLOR_TYPE_RGB_ALPHA:Int=		(PNG_COLOR_MASK_COLOR | PNG_COLOR_MASK_ALPHA)
Const PNG_COLOR_TYPE_GRAY_ALPHA:Int=	(PNG_COLOR_MASK_ALPHA)
Const PNG_COLOR_TYPE_RGBA:Int=			PNG_COLOR_TYPE_RGB_ALPHA
Const PNG_COLOR_TYPE_GA:Int=			PNG_COLOR_TYPE_GRAY_ALPHA

Const PNG_TRANSFORM_IDENTITY:Int=		$0000		'read and write
Const PNG_TRANSFORM_STRIP_16:Int=		$0001		'read only
Const PNG_TRANSFORM_STRIP_ALPHA:Int=	$0002		'read only
Const PNG_TRANSFORM_PACKING:Int=		$0004		'read and write
Const PNG_TRANSFORM_PACKSWAP:Int=		$0008		'read and write
Const PNG_TRANSFORM_EXPAND:Int=			$0010		'read only
Const PNG_TRANSFORM_INVERT_MONO:Int=	$0020		'read and write
Const PNG_TRANSFORM_SHIFT:Int=			$0040		'read and write
Const PNG_TRANSFORM_BGR:Int=			$0080		'read and write
Const PNG_TRANSFORM_SWAP_ALPHA:Int=		$0100		'read and write
Const PNG_TRANSFORM_SWAP_ENDIAN:Int=	$0200		'read and write
Const PNG_TRANSFORM_INVERT_ALPHA:Int=   $0400		'read and write
Const PNG_TRANSFORM_STRIP_FILLER:Int=   $0800		'write only

Const PNG_COMPRESSION_TYPE_DEFAULT:Int=	0

Const PNG_FILTER_TYPE_DEFAULT:Int=		0
Const PNG_INTRAPIXEL_DIFFERENCING:Int=	64

Const PNG_INTERLACE_NONE:Int=			0
Const PNG_INTERLACE_ADAM7:Int=			1

Function png_sig_cmp:Int( buf:Byte Ptr,start:Int,count:Int ) = "bmx_png_sig_cmp"

Function png_create_read_struct:Byte Ptr( ver_string$z,user_error_ptr:Byte Ptr,user_error_fn:Byte Ptr,user_warning_fn:Byte Ptr) = "bmx_png_create_read_struct"
Function png_create_write_struct:Byte Ptr( ver_string$z,user_error_ptr:Byte Ptr,user_error_fn:Byte Ptr,user_warning_fn:Byte Ptr) = "bmx_png_create_write_struct"

Function png_destroy_read_struct( png_ptr:Byte Ptr,info_ptr1:Byte Ptr,info_ptr2:Byte Ptr ) = "bmx_png_destroy_read_struct"
Function png_destroy_write_struct( png_ptr:Byte Ptr,info_ptr1:Byte Ptr,info_ptr2:Byte Ptr ) = "bmx_png_destroy_write_struct"

Function png_create_info_struct:Byte Ptr( png_ptr:Byte Ptr ) = "bmx_png_create_info_struct"

Function png_init_io( png_ptr:Byte Ptr,c_stream:Byte Ptr ) = "bmx_png_init_io"
Function png_set_sig_bytes( png_ptr:Byte Ptr,number:Int ) = "bmx_png_set_sig_bytes"

Function png_set_read_fn( png_ptr:Byte Ptr,user:Object,read_fn:Int(png_ptr:Byte Ptr,buf:Byte Ptr,size:Int) ) = "bmx_png_set_read_fn"
Function png_set_write_fn( png_ptr:Byte Ptr,user:Object,write_fn:Int(png_ptr:Byte Ptr,buf:Byte Ptr,size:Int),flush_fn(png_ptr:Byte Ptr) ) = "bmx_png_set_write_fn"

Function png_set_expand( png_ptr:Byte Ptr ) = "bmx_png_set_expand"
Function png_set_strip_16( png_ptr:Byte Ptr ) = "bmx_png_set_strip_16"
Function png_set_gray_to_rgb( png_ptr:Byte Ptr ) = "bmx_png_set_gray_to_rgb"

Function png_set_compression_level( png_ptr:Byte Ptr,level:Int ) = "bmx_png_set_compression_level"
Function png_set_compression_strategy( png_ptr:Byte Ptr,strategy:Int ) = "bmx_png_set_compression_strategy"

Function png_read_png( png_ptr:Byte Ptr,info_ptr:Byte Ptr,png_transforms:Int,reserved:Byte Ptr ) = "bmx_png_read_png"
Function png_write_png( png_ptr:Byte Ptr,info_ptr:Byte Ptr,png_transforms:Int,reserved:Byte Ptr ) = "bmx_png_write_png"

Function png_get_rows:Byte Ptr Ptr( png_ptr:Byte Ptr,info_ptr:Byte Ptr ) = "bmx_png_get_rows"
Function png_set_rows( png_ptr:Byte Ptr,info_ptr:Byte Ptr,rows:Byte Ptr ) = "bmx_png_set_rows"

Function png_get_IHDR:Int( png_ptr:Byte Ptr,info_ptr:Byte Ptr,width:Int Var,height:Int Var,bit_depth:Int Var,color_type:Int Var,interlace_type:Int Var,compression_type:Int Var,filter_method:Int Var ) = "bmx_png_get_IHDR"
Function png_set_IHDR( png_ptr:Byte Ptr,info_ptr:Byte Ptr,width:Int,height:Int,bit_depth:Int,color_type:Int,interlace_type:Int,compression_type:Int,filter_method:Int ) = "bmx_png_set_IHDR"

Function png_get_io_ptr:Object(png_ptr:Byte Ptr) = "bmx_png_get_io_ptr"

End Extern
