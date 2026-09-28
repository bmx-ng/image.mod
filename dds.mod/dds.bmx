SuperStrict

Rem
bbdoc: Optional DDS texture-container loader preserving BC1/BC3 blocks and mip levels.
about: Importing Image.DDS registers support with BRL.TextureData and Max2D image loading. This module does not decode compressed pixels into TPixmap or require a graphics context.
End Rem
Module Image.DDS
ModuleInfo "Version: 1.00"
ModuleInfo "License: zlib/libpng"

Import BRL.TextureData

Rem
bbdoc: Loads BC1/BC3 texture data from a DDS filename, stream URL or TStream.
about: Supports 2D DXT1/DXT5 and DX10 BC1/BC3 UNORM headers, including partial mip chains. Returns Null for unrecognised data or an unavailable URL. Recognised invalid or unsupported DDS files throw informative errors. Does not close a caller-owned stream. Forward-only streams are supported; this function consumes bytes even when the signature is unrecognised. Unknown legacy/DX10 alpha is interpreted as straight alpha. Premultiplied/custom alpha, sRGB, arrays, cube maps and volumes are rejected.
End Rem
Function LoadTextureDDS:TTextureData(url:Object)
	Local stream:TStream=ReadStream(url)
	If Not stream Then Return Null
	Local data:TTextureData
	Try
		data=ReadDDS(stream)
	Catch error:Object
		stream.Close()
		Throw error
	End Try
	stream.Close()
	Return data
End Function

Private

Function UIntLE:Long(bytes:Byte[],offset:Int)
	Return Long(bytes[offset]) | (Long(bytes[offset+1]) Shl 8) | (Long(bytes[offset+2]) Shl 16) | (Long(bytes[offset+3]) Shl 24)
End Function

Function ReadExact(stream:TStream,bytes:Byte[],offset:Int,count:Int)
	Try
		stream.ReadBytes(Varptr bytes[offset],count)
	Catch error:TStreamException
		Throw "DDS: truncated header or texture payload"
	End Try
End Function

Function ReadDDS:TTextureData(stream:TStream)
	Local header:Byte[]=New Byte[128]
	Local read:Int
	While read<4
		Local count:Long=stream.Read(Varptr header[read],4-read)
		If count<=0 Then Return Null
		read:+Int(count)
	Wend
	If UIntLE(header,0)<>$20534444 Then Return Null
	ReadExact(stream,header,4,124)
	If UIntLE(header,4)<>124 Or UIntLE(header,76)<>32 Then Throw "DDS: invalid header size"
	Local widthValue:Long=UIntLE(header,16)
	Local heightValue:Long=UIntLE(header,12)
	If widthValue=0 Or heightValue=0 Or widthValue>$7fffffff Or heightValue>$7fffffff Then Throw "DDS: invalid texture dimensions"
	If (UIntLE(header,112) & $20fe00) Or (UIntLE(header,8) & $800000) Or UIntLE(header,24)>1 Then Throw "DDS: cube maps and volume textures are unsupported"
	If Not (UIntLE(header,80) & 4) Then Throw "DDS: only BC1 and BC3 FourCC formats are supported"
	Local format:Int
	Select UIntLE(header,84)
		Case $31545844 ' DXT1
			format=PF_BC1_RGBA
		Case $35545844 ' DXT5
			format=PF_BC3_RGBA
		Case $30315844 ' DX10
			Local extension:Byte[]=New Byte[20]
			ReadExact(stream,extension,0,20)
			If UIntLE(extension,4)<>3 Or UIntLE(extension,12)<>1 Or (UIntLE(extension,8) & 4) Then Throw "DDS: only one 2D texture is supported"
			Local alpha:Long=UIntLE(extension,16)
			If alpha<>0 And alpha<>1 And alpha<>3 Then Throw "DDS: premultiplied, custom or unknown alpha mode is unsupported"
			Select UIntLE(extension,0)
				Case 71
					format=PF_BC1_RGBA
				Case 77
					format=PF_BC3_RGBA
				Default
					Throw "DDS: only BC1/BC3 UNORM are supported; sRGB and typeless formats are unsupported"
			End Select
		Default
			Throw "DDS: unsupported FourCC (expected DXT1, DXT5 or DX10)"
	End Select
	Local width:Int=Int(widthValue)
	Local height:Int=Int(heightValue)
	Local countValue:Long=UIntLE(header,28)
	If countValue=0 Then countValue=1
	Local maximum:Int=1
	Local extent:Int=Max(width,height)
	While extent>1
		extent:/2
		maximum:+1
	Wend
	If countValue>maximum Then Throw "DDS: invalid mip-level count"
	Local count:Int=Int(countValue)
	Local info:TPixelFormatInfo=GetPixelFormatInfo(format)
	Local total:Long
	Local w:Int=width,h:Int=height
	For Local index:Int=0 Until count
		Local size:Long=info.StorageSize(w,h)
		If size>$7fffffff Then Throw "DDS: mip level exceeds byte-array size limit"
		total:+size
		w=Max(1,w/2)
		h=Max(1,h/2)
	Next
	' Check known remaining length before allocating any payload buffers.
	Local position:Long=stream.Pos()
	Local length:Long=stream.Size()
	If position>=0 And length>=0 And (position>length Or total>length-position) Then Throw "DDS: truncated texture payload"
	Local levels:TTextureLevel[]=New TTextureLevel[count]
	For Local index:Int=0 Until count
		Local bytes:Byte[]=New Byte[Int(info.StorageSize(width,height))]
		ReadExact(stream,bytes,0,bytes.Length)
		levels[index]=TTextureLevel.Create(width,height,format,bytes)
		width=Max(1,width/2)
		height=Max(1,height/2)
	Next
	Return TTextureData.Create(levels)
End Function

Type TDDSLoader Extends TTextureDataLoader
	Method LoadTextureData:TTextureData(stream:TStream) Override
		Return ReadDDS(stream)
	End Method
End Type

Global _ddsLoader:TDDSLoader=New TDDSLoader
