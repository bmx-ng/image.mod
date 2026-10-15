' Copyright (c) 2026 Bruce A Henderson
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
bbdoc: Native Apple Icon Image reader and writer.
about: Image.ICNS reads ICNS containers, decodes PNG and legacy RGB/ARGB icon elements to pixmaps, and creates ICNS files from PNG data or pixmaps without external tools.
End Rem
Module Image.ICNS
ModuleInfo "Version: 1.00"
ModuleInfo "License: zlib/libpng"
ModuleInfo "License: icnsutil-derived format metadata - MIT"
ModuleInfo "Copyright: 2026 Bruce A Henderson"
ModuleInfo "Copyright: icnsutil - 2021-2023 relikd"

ModuleInfo "History: 1.00 Initial release"

Import BRL.ByteBuffer
Import BRL.BankStream
Import BRL.Pixmap
Import Collections.HashMap
Import BRL.Path
Import Image.PNG

Rem
bbdoc: An in-memory ICNS container.
End Rem
Type TIcnsFile

Private

	Global HEADER_PNG:Byte[] = [$89, Asc("P"), Asc("N"), Asc("G"), $0D, $0A, $1A, $0A]
	Global HEADER_ICNS:Byte[] = [Asc("i"), Asc("c"), Asc("n"), Asc("s")]
	Global HEADER_ARGB:Byte[] = [Asc("A"), Asc("R"), Asc("G"), Asc("B")]
	Global HEADER_PLIST:Byte[] = [Asc("b"), Asc("p"), Asc("l"), Asc("i"), Asc("s"), Asc("t")]
	Global HEADER_JP2_1:Byte[] = [$00, $00, $00, $0C, Asc("j"), Asc("P"), Asc(" "), Asc(" ")]
	Global HEADER_JP2_2:Byte[] = [$FF, $4F, $FF, $51, $00, $2F, $00, $00]

	Global mediaTypes:THashMap<String, TIcnsMedia> = New THashMap<String, TIcnsMedia>()

	Field data:TByteBuffer

	Field media:THashMap<String, TByteBuffer> = New THashMap<String, TByteBuffer>()
	Field mediaOrder:String[]

Public
	Function Init()
		If mediaTypes.Count() Then Return
		' Readable
		mediaTypes.Add("ICON", New TIcnsMedia("ICON", EDataType.bin, 32, 1, 1, "1.0", "icon"))
		mediaTypes.Add("ICN#", New TIcnsMedia("ICN#", EDataType.bin, 32, 2, 1, "6.0", "iconmask"))
		mediaTypes.Add("icm#", New TIcnsMedia("icm#", EDataType.bin, New SSize(16, 12), 2, 1, "6.0", "iconmask"))
		mediaTypes.Add("icm4", New TIcnsMedia("icm4", EDataType.bin, New SSize(16, 12), 1, 4, "7.0", "icon"))
		mediaTypes.Add("icm8", New TIcnsMedia("icm8", EDataType.bin, New SSize(16, 12), 1, 8, "7.0", "icon"))
		mediaTypes.Add("ics#", New TIcnsMedia("ics#", EDataType.bin, 16, 2, 1, "6.0", "iconmask"))
		mediaTypes.Add("ics4", New TIcnsMedia("ics4", EDataType.bin, 16, 1, 4, "7.0", "icon"))
		mediaTypes.Add("ics8", New TIcnsMedia("ics8", EDataType.bin, 16, 1, 8, "7.0", "icon"))
		mediaTypes.Add("is32", New TIcnsMedia("is32", EDataType.rgb, 16, -1, -1, "8.5", ""))
		mediaTypes.Add("s8mk", New TIcnsMedia("s8mk", EDataType.bin, 16, 1, 8, "8.5", "mask"))
		mediaTypes.Add("icl4", New TIcnsMedia("icl4", EDataType.bin, 32, 1, 4, "7.0", "icon"))
		mediaTypes.Add("icl8", New TIcnsMedia("icl8", EDataType.bin, 32, 1, 8, "7.0", "icon"))
		mediaTypes.Add("il32", New TIcnsMedia("il32", EDataType.rgb, 32, -1, -1, "8.5", ""))
		mediaTypes.Add("l8mk", New TIcnsMedia("l8mk", EDataType.bin, 32, 1, 8, "8.5", "mask"))
		mediaTypes.Add("ich#", New TIcnsMedia("ich#", EDataType.bin, 48, 2, 1, "8.5", "iconmask"))
		mediaTypes.Add("ich4", New TIcnsMedia("ich4", EDataType.bin, 48, 1, 4, "8.5", "icon"))
		mediaTypes.Add("ich8", New TIcnsMedia("ich8", EDataType.bin, 48, 1, 8, "8.5", "icon"))
		mediaTypes.Add("ih32", New TIcnsMedia("ih32", EDataType.rgb, 48, -1, -1, "8.5", ""))
		mediaTypes.Add("h8mk", New TIcnsMedia("h8mk", EDataType.bin, 48, 1, 8, "8.5", "mask"))
		mediaTypes.Add("it32", New TIcnsMedia("it32", EDataType.rgb, 128, -1, -1, "10.0", ""))
		mediaTypes.Add("t8mk", New TIcnsMedia("t8mk", EDataType.bin, 128, 1, 8, "10.0", "mask"))
		' Writeable
		mediaTypes.Add("icp4", New TIcnsMedia("icp4", [EDataType.png, EDataType.jp2, EDataType.rgb], 16, -1, -1, "10.7", ""))
		mediaTypes.Add("icp5", New TIcnsMedia("icp5", [EDataType.png, EDataType.jp2, EDataType.rgb], 32, -1, -1, "10.7", ""))
		mediaTypes.Add("icp6", New TIcnsMedia("icp6", [EDataType.png, EDataType.jp2], 48, -1, -1, "10.7", ""))
		mediaTypes.Add("ic07", New TIcnsMedia("ic07", [EDataType.png, EDataType.jp2], 128, -1, -1, "10.7", ""))
		mediaTypes.Add("ic08", New TIcnsMedia("ic08", [EDataType.png, EDataType.jp2], 256, -1, -1, "10.5", ""))
		mediaTypes.Add("ic09", New TIcnsMedia("ic09", [EDataType.png, EDataType.jp2], 512, -1, -1, "10.5", ""))
		mediaTypes.Add("ic10", New TIcnsMedia("ic10", [EDataType.png, EDataType.jp2], 1024, -1, -1, "10.7", "or 512x512@2x (10.8)"))
		mediaTypes.Add("ic11", New TIcnsMedia("ic11", [EDataType.png, EDataType.jp2], 32, -1, -1, "10.8", "16x16@2x"))
		mediaTypes.Add("ic12", New TIcnsMedia("ic12", [EDataType.png, EDataType.jp2], 64, -1, -1, "10.8", "32x32@2x"))
		mediaTypes.Add("ic13", New TIcnsMedia("ic13", [EDataType.png, EDataType.jp2], 256, -1, -1, "10.8", "128x128@2x"))
		mediaTypes.Add("ic14", New TIcnsMedia("ic14", [EDataType.png, EDataType.jp2], 512, -1, -1, "10.8", "256x256@2x"))
		mediaTypes.Add("ic04", New TIcnsMedia("ic04", [EDataType.argb, EDataType.png, EDataType.jp2], 16, -1, -1, "11.0", ""))
		mediaTypes.Add("ic05", New TIcnsMedia("ic05", [EDataType.argb, EDataType.png, EDataType.jp2], 32, -1, -1, "11.0", ""))
		mediaTypes.Add("icsb", New TIcnsMedia("icsb", [EDataType.argb, EDataType.png, EDataType.jp2], 18, -1, -1, "11.0", ""))
		mediaTypes.Add("icsB", New TIcnsMedia("icsB", [EDataType.png, EDataType.jp2], 36, -1, -1, "", "18x18@2x"))
		mediaTypes.Add("sb24", New TIcnsMedia("sb24", [EDataType.png, EDataType.jp2], 24, -1, -1, "", ""))
		mediaTypes.Add("SB24", New TIcnsMedia("SB24", [EDataType.png, EDataType.jp2], 48, -1, -1, "", "24x24@2x"))
		' ICNS media files
		mediaTypes.Add("sbtp", New TIcnsMedia("sbtp", [EDataType.icns], -1, -1, -1, "", "template"))
		mediaTypes.Add("slct", New TIcnsMedia("slct", [EDataType.icns], -1, -1, -1, "", "selected"))
		mediaTypes.Add(Chr($FD) + Chr($D9) + Chr($2F) + Chr($A8), New TIcnsMedia(Chr($FD) + Chr($D9) + Chr($2F) + Chr($A8), [EDataType.icns], -1, -1, -1, "10.14", "dark"))
		' Meta types
		mediaTypes.Add("TOC ", New TIcnsMedia("TOC ", [EDataType.bin], -1, -1, -1, "10.7", "Table of Contents"))
		mediaTypes.Add("icnV", New TIcnsMedia("icnV", [EDataType.bin], -1, -1, -1, "", "4-byte Icon Composer.app bundle version"))
		mediaTypes.Add("name", New TIcnsMedia("name", [EDataType.bin], -1, -1, -1, "", "Unknown"))
		mediaTypes.Add("info", New TIcnsMedia("info", [EDataType.plist], -1, -1, -1, "", "Info binary plist"))
	End Function

	Rem
	bbdoc: The source filename supplied while loading, if any.
	End Rem
	Field filename:String

	Rem
	bbdoc: Loads an ICNS container from a stream.
	about: The stream is not closed.
	End Rem
	Function Load:TIcnsFile(stream:TStream, filename:String = Null)
		Return _Load(stream, filename)
	End Function

	Rem
	bbdoc: Loads an ICNS container from a file path.
	End Rem
	Function Load:TIcnsFile(path:String)
		Return _Load(path, New TPath(path).Name())
	End Function

	Rem
	bbdoc: Loads an ICNS container from an in-memory byte array.
	End Rem
	Function Load:TIcnsFile(array:Byte[], filename:String = Null)
		Return _Load(Null, filename, array)
	End Function

	Rem
	bbdoc: Loads an ICNS container from a path object.
	End Rem
	Function Load:TIcnsFile(path:TPath)
		Return _Load(path.ToString(), path.Name())
	End Function

Private
	Function _Load:TIcnsFile(url:Object, filename:String = Null, array:Byte[] = Null)

		If Not array Then
			array = LoadByteArray(url, False)
		End If

		If array Then
			If array.Length < 8 Then
				Throw New TIcnsParseException("ICNS data is shorter than its 8-byte header.")
			End If
			Local file:TIcnsFile = New TIcnsFile
			file.data = New TByteArrayBuffer(array)
			file.data.Order(EByteOrder.BigEndian)
			file.filename = filename

			file.Parse()

			Return file
		End If

		Return Null
	End Function

Public

	Rem
	bbdoc: Adds encoded image or metadata bytes to the container.
	about: When @key is omitted, the element type is inferred from the payload, dimensions, and optional @filename. Use an @2x filename suffix for Retina PNG or JPEG 2000 data.
	End Rem
	Method AddMedia(data:Byte[], key:String = Null, filename:String = Null, force:Int = False)
		_AddMedia(key, Null, filename, data, force)
	End Method

	Rem
	bbdoc: Adds encoded image or metadata data from a path object.
	End Rem
	Method AddMedia(path:TPath, key:String = Null, force:Int = False)
		_AddMedia(key, path.ToString(), path.Name(), Null, force)
	End Method

	Rem
	bbdoc: Adds encoded image or metadata data from a file path.
	End Rem
	Method AddMedia(path:String, key:String = Null, force:Int = False)
		Local source:TPath = New TPath(path)
		_AddMedia(key, path, source.Name(), Null, force)
	End Method

	Rem
	bbdoc: Adds encoded image or metadata data from a stream.
	about: The stream is not closed.
	End Rem
	Method AddMedia(stream:TStream, filename:String, key:String = Null, force:Int = False)
		_AddMedia(key, stream, filename, Null, force)
	End Method

	Rem
	bbdoc: Adds a pixmap as a PNG-backed ICNS element.
	about: If @key is omitted, the element type is selected from the pixmap dimensions. Set @retina for an @2x representation, or provide a key to resolve ambiguous dimensions.
	End Rem
	Method AddPixmap(pixmap:TPixmap, key:String = Null, retina:Int = False, force:Int = False, compression:Int = 6)
		If Not pixmap Then Throw New TIcnsAttributeException("Pixmap must not be Null.")
		If pixmap.width <> pixmap.height Then
			Throw New TIcnsAttributeException("ICNS pixmaps must be square.")
		End If
		If Not key Then key = KeyForSize(pixmap.width, retina)
		If key.Length <> 4 Or Not mediaTypes.ContainsKey(key) Or Not mediaTypes[key].IsType(EDataType.png) Then
			Throw New TIcnsAttributeException("ICNS element '" + key + "' does not accept PNG pixmap data.")
		End If
		Local info:TIcnsMedia = mediaTypes[key]
		If info.size.width > 0 And (info.size.width <> pixmap.width Or info.size.height <> pixmap.height) Then
			Throw New TIcnsAttributeException("Pixmap dimensions do not match ICNS element '" + key + "'.")
		End If
		Local bank:TBank = CreateBank()
		If Not SavePixmapPNG(pixmap, bank, compression) Then
			Throw New TIcnsAttributeException("Could not encode pixmap as PNG.")
		End If
		Local bytes:Byte[] = New Byte[Int(bank.Size())]
		If bytes.Length Then MemCopy(bytes, bank.Buf(), Size_T(bytes.Length))
		AddMedia(bytes, key, key + ".png", force)
	End Method

	Rem
	bbdoc: Returns the standard PNG-backed ICNS key for a square pixel size.
	End Rem
	Function KeyForSize:String(size:Int, retina:Int = False)
		If retina Then
			Select size
				Case 32; Return "ic11"
				Case 36; Return "icsB"
				Case 48; Return "SB24"
				Case 64; Return "ic12"
				Case 256; Return "ic13"
				Case 512; Return "ic14"
				Case 1024; Return "ic10"
			End Select
		Else
			Select size
				Case 16; Return "icp4"
				Case 18; Return "icsb"
				Case 24; Return "sb24"
				Case 32; Return "icp5"
				Case 48; Return "icp6"
				Case 128; Return "ic07"
				Case 256; Return "ic08"
				Case 512; Return "ic09"
				Case 1024; Return "ic10"
			End Select
		End If
		Local suffix:String
		If retina Then suffix = " @2x"
		Throw New TIcnsAttributeException("No standard ICNS element type for " + size + "x" + size + suffix + ".")
	End Function

	Rem
	bbdoc: Returns the element keys in file/insertion order.
	End Rem
	Method MediaKeys:String[]()
		Return mediaOrder[..]
	End Method

	Rem
	bbdoc: Returns True when the container has @key.
	End Rem
	Method HasMedia:Int(key:String)
		Return media.ContainsKey(key)
	End Method

	Rem
	bbdoc: Returns a copy of an element payload, or Null if absent.
	End Rem
	Method GetMedia:Byte[](key:String)
		If Not media.ContainsKey(key) Then Return Null
		Return _BufferBytes(media[key])
	End Method

	Rem
	bbdoc: Removes an element and returns True when it existed.
	End Rem
	Method RemoveMedia:Int(key:String)
		If Not media.ContainsKey(key) Then Return False
		media.Remove(key)
		For Local i:Int = 0 Until mediaOrder.Length
			If mediaOrder[i] = key Then
				mediaOrder = mediaOrder[..i] + mediaOrder[i + 1..]
				Exit
			End If
		Next
		Return True
	End Method

	Rem
	bbdoc: Serializes this container to a byte array.
	about: When @includeToc is True a fresh Table of Contents element is written first. Existing TOC data is never reused.
	End Rem
	Method ToByteArray:Byte[](includeToc:Int = False)
		Local keys:String[]
		For Local key:String = EachIn mediaOrder
			If key <> "TOC " Then keys :+ [key]
		Next
		Local tocPayload:Int
		If includeToc Then tocPayload = keys.Length * 8
		Local total:Long = 8
		If includeToc Then total :+ 8 + tocPayload
		For Local key:String = EachIn keys
			total :+ 8 + media[key].Limit()
		Next
		If total > $7fffffff Then Throw New TIcnsAttributeException("ICNS output exceeds the supported 2 GiB size.")

		Local result:Byte[] = New Byte[Int(total)]
		Local pos:Int
		_WriteHeader(result, pos, "icns", Int(total)); pos :+ 8
		If includeToc Then
			_WriteHeader(result, pos, "TOC ", tocPayload + 8); pos :+ 8
			For Local key:String = EachIn keys
				_WriteHeader(result, pos, key, media[key].Limit() + 8); pos :+ 8
			Next
		End If
		For Local key:String = EachIn keys
			Local payload:Byte[] = _BufferBytes(media[key])
			_WriteHeader(result, pos, key, payload.Length + 8); pos :+ 8
			If payload.Length Then MemCopy(Byte Ptr(result) + pos, payload, Size_T(payload.Length))
			pos :+ payload.Length
		Next
		Return result
	End Method

	Rem
	bbdoc: Writes this container to a path, stream, or other writable URL.
	about: A caller-provided stream is not closed.
	End Rem
	Method Save(url:Object, includeToc:Int = False)
		Local bytes:Byte[] = ToByteArray(includeToc)
		Local stream:TStream = TStream(url)
		If stream Then
			If stream.WriteBytes(bytes, bytes.Length) <> bytes.Length Then Throw New TStreamWriteException
		Else
			SaveByteArray(bytes, url)
		End If
	End Method

	Rem
	bbdoc: Decodes an icon element to an RGBA pixmap.
	about: If @key is omitted the largest decodable image is selected. PNG, compressed ARGB, and legacy compressed 24-bit RGB elements are supported.
	End Rem
	Method ToPixmap:TPixmap(key:String = Null)
		If key Then Return _DecodePixmap(key)
		Local best:TPixmap
		Local bestArea:Int = -1
		For Local candidate:String = EachIn mediaOrder
			Local pix:TPixmap = _DecodePixmap(candidate, False)
			If pix And pix.width * pix.height > bestArea Then
				best = pix
				bestArea = pix.width * pix.height
			End If
		Next
		Return best
	End Method

Private
	Method _AddMedia(key:String, url:Object, filename:String, array:Byte[], force:Int)

		If url And Not array Then
			array = LoadByteArray(url, False)
		End If

		If Not array Then
			Throw New TIcnsAttributeException("No data provided, or could not load.")
		End If

		Local data:TByteBuffer
		If array Then
			data = New TByteArrayBuffer(array)
			data.Order(EByteOrder.BigEndian)
		End If

		Local icnsMedia:TIcnsMedia
		Local isIcns:Int = False

		If Not key Then ' Determine ICNS type
			icnsMedia = Guess(data, filename)
			key = icnsMedia.key
			isIcns = icnsMedia.IsType(EDataType.icns)
		Else
			If key.Length <> 4 Then
				Throw New TIcnsAttributeException("An ICNS element key must contain exactly four bytes.")
			End If
			If mediaTypes.ContainsKey(key) Then
				isIcns = mediaTypes[key].IsType(EDataType.icns)
			End If
		End If

		If Not force And media.ContainsKey(key) Then
			Throw New TIcnsKeyException("Image with identical key '" + key + "'. File : " + filename)
		End If

		' Nested icns files must omit the icns header
		If isIcns And data.Limit() >= 8 Then
			Local header:TByteBuffer = data.Slice(0, 4)
			Local headerBytes:Byte Ptr = StackAlloc(4)
			header.GetBytes(headerBytes, 4)
			If CompareBytes(HEADER_ICNS, headerBytes) Then
				data = data.SliceFrom(8)
			End If
		End If

		media.Put(key, data)
		If Not force Or Not _OrderContains(key) Then
			mediaOrder :+ [key]
		End If
	End Method

	Method Parse()
		Local pos:Int = 0
		Local declaredLength:Int
		Local magicNumber:String = ReadIcnsHeader(data.Slice(0, 8), declaredLength)

		If magicNumber <> "icns" Then
			Throw New TIcnsParseException("Not an ICNS file, missing 'icns' header.")
		End If
		If declaredLength <> data.Limit() Then
			Throw New TIcnsParseException("ICNS header size " + declaredLength + " does not match actual size " + data.Limit() + ".")
		End If

		pos = 8
		While pos < declaredLength
			If declaredLength - pos < 8 Then
				Throw New TIcnsParseException("Truncated ICNS element header at offset " + pos + ".")
			End If
			Local elementLength:Int
			Local key:String = ReadIcnsHeader(data.Slice(pos, 8), elementLength)
			If elementLength < 8 Or Long(pos) + Long(elementLength) > Long(data.Limit()) Then
				Throw New TIcnsParseException("Invalid ICNS element length for '" + key + "' at offset " + pos + ".")
			End If
			If media.ContainsKey(key) Then
				Throw New TIcnsParseException("Duplicate ICNS element key '" + key + "'.")
			End If
			media.Add(key, data.Slice(pos + 8, elementLength - 8).AsReadOnly())
			mediaOrder :+ [key]
			pos :+ elementLength
		Wend
	End Method

	Method DetermineDataType:EDataType(buffer:TByteBuffer)
		If Not buffer Or buffer.Remaining() < 4 Then Return EDataType.none
		Local count:Int = Min(8, buffer.Remaining())
		Local header:Byte Ptr = StackAlloc(8)
		MemClear(header, 8)
		Local copy:TByteBuffer = buffer.Slice()
		copy.GetBytes(header, UInt(count))

		If count >= 8 And CompareBytes(HEADER_PNG, header) Then
			Return EDataType.png
		End If

		If CompareBytes(HEADER_ARGB, header) Then
			Return EDataType.argb
		End If

		If count >= 6 And CompareBytes(HEADER_PLIST, header) Then
			Return EDataType.plist
		End If

		If count >= 8 And (CompareBytes(HEADER_JP2_1, header) Or CompareBytes(HEADER_JP2_2, header)) Then
			Return EDataType.jp2
		End If


		If CompareBytes(HEADER_ICNS, header) Then
			Return EDataType.icns
		End If
		If buffer.Remaining() >= 8 And IsIcnsWithoutHeader(buffer.Slice()) Then Return EDataType.icns

		Return EDataType.none
	End Method

	Method DetermineFileExtension:String(buffer:TByteBuffer)
		Local dataType:EDataType = DetermineDataType(buffer)

		Select dataType
			Case EDataType.png
				Return "png"
			Case EDataType.argb
				Return "argb"
			Case EDataType.plist
				Return "plist"
			Case EDataType.jp2
				Return "jp2"
			Case EDataType.icns
				Return "icns"
		End Select

		Return Null
	End Method

	Method CompareBytes:Int(expected:Byte[], bytes:Byte Ptr)
		Local i:Int = 0

		While i < expected.Length
			If expected[i] <> bytes[i] Then
				Return False
			End If
			i :+ 1
		End While

		Return True
	End Method

	Method IsIcnsWithoutHeader:Int(data:TByteBuffer)
		If Not data Or data.Remaining() < 8 Then Return False
		Local offset:Int

		For Local i:Int = 0 Until 2
			If data.Limit() - offset < 8 Then Return False
			Local length:Int
			Local key:String = ReadIcnsHeader(data.Slice(offset, 8), length)

			If Not mediaTypes.ContainsKey(key) Then
				Return False
			End If

			offset :+ length

			If length < 8 Or offset > data.Limit() Then
				Return False
			End If

			If offset = data.Limit() Then
				Return True
			End If
		Next

		Return True

	End Method

	Method ReadIcnsHeader:String(data:TByteBuffer, length:Int Var)
		' "data" should have at least 8 bytes available
		' first 4 bytes is the type (eg. 'icns')
		' second 4 bytes is the length as a big endian integer
		If data.Remaining() <> 8 Then
			length = 0
			Return ""
		End If

		Local header:Byte Ptr = StackAlloc(8)
		data.GetBytes(header, 8)

		Local _type:String = Chr(header[0]) + Chr(header[1]) + Chr(header[2]) + Chr(header[3])
		length = ReadInt(header + 4)

		Return _type
	End Method

	Method ReadInt:Int(data:Byte Ptr)
		' read int as big endian
		Return ((data[0] & $ff) Shl 24) | ((data[1] & $ff) Shl 16) | ((data[2] & $ff) Shl 8) | (data[3] & $ff)
	End Method

	Method Guess:TIcnsMedia(data:TByteBuffer, filename:String = Null)

		Local basename:String

		If filename Then
			basename = New TPath(filename).BaseName()

			If basename Then
				If mediaTypes.ContainsKey(basename) Then
					Return mediaTypes[basename]
				End If
			End If
		End If

		' Guess extension
		Local ext:String = DetermineFileExtension(data.Slice())

		Local size:SSize
		Local maxSize:Int = -1

		If Not ext And filename Then
			If filename.EndsWith(".rgb") Then
				ext = "rgb"
			ElseIf filename.EndsWith(".mask") Then
				ext = "mask"
				maxSize = data.Limit()
			End If
		End If

		' Guess image size
		If ext Then
			size = DetermineImageSize(data.Slice(), ext)
		End If

		Local retina:Int
		Local desc:String

		If filename Then
			' Guess retina flag
			retina = basename.ToLower().Contains("@2x")

			' Guess icns-specific type
			If ext = "icns" Then
				For Local candidate:String = Eachin ["template", "selected", "dark"]
					If basename.ToLower().Contains(candidate) Then
						desc = candidate
						Exit
					End If
				Next
			End If
		End If

		' double usage of ic10, enforce retina flag
		If size.width = 1024 And size.height = 1024 Then
			retina = True
		End If

		Local choices:TIcnsMedia[]

		For Local media:TIcnsMedia = EachIn mediaTypes.Values()
			' png + jp2
			If retina <> media.retina Then
				Continue
			End If

			'  icns or rgb-mask
			If desc And desc <> media.desc Then
				Continue
			End If

			If ext Then
				If size.width <> media.size.width Or size.height <> media.size.height Or Not media.IsType(ext) Then
					Continue
				End If
			Else
				If media.extCertain Then
					Continue
				End If

				If maxSize And media.maxSize And maxSize <> media.maxSize Then
					Continue
				End If
			End If

			choices :+ [media]
		Next

		Return BestOption(choices, ext)
	End Method

	Method BestOption:TIcnsMedia(choices:TIcnsMedia[], ext:String)

		If choices.Length = 1 Then
			Return choices[0]
		End If

		If ext Then
			Local bestI:Int = 99
			Local bestChoices:TIcnsMedia[]

			For Local x:TIcnsMedia = EachIn choices
				Local i:Int = -1

				For Local j:Int = 0 Until x.types.Length
					If x.types[j].ToString() = ext Then
						i = j
						Exit
					End If
				Next

				If i >= 0 Then
					If i < bestI Then
						bestI = i
						bestChoices = [x]
					ElseIf i = bestI Then
						bestChoices :+ [x]
					End If
				End If
			Next

			If bestChoices.Length = 1 Then
				Return bestChoices[0]
			End If

			choices = bestChoices
		End If

		Local msg:String = "Could not determine type - one of ["
		For Local i:Int = 0 Until choices.Length
			msg :+ choices[i].key
			If i < choices.Length - 1 Then
				msg :+ ", "
			End If
		Next
		msg :+ "]."

		Throw New TCannotDetermineTypeException(msg)
	End Method

	Method DetermineImageSize:SSize(data:TByteBuffer, ext:String)
		If Not ext Then
			ext = DetermineFileExtension(data)
		End If

		If ext = "png" Then
			If data.Limit() < 24 Then Throw New TCannotDetermineTypeException("Truncated PNG header.")
			' width and height are big-endian 4 byte integers at offset 16 and 20
			Local header:TByteBuffer = data.Slice(16, 8)
			Local width:Int = header.GetInt()
			Local height:Int = header.GetInt()
			Return New SSize(width, height)
		ElseIf ext = "argb" Then
			If data.Limit() <= 4 Then Throw New TCannotDetermineTypeException("Truncated ARGB data.")
			' without ARGB header
			Local total:Int = GetSize(TByteBuffer(data.Slice(4, data.Limit() - 4)))

			Return MatchMaxSize(total, EDataType.argb).size
		ElseIf ext = "rgb" Then
			If data.Limit() < 4 Then Throw New TCannotDetermineTypeException("Truncated RGB data.")
			Local rgb:TByteBuffer = data.Slice()
			' without it32 header
			If rgb.GetInt() = 0 Then
				rgb.Position(4)
			End If
			Local total:Int = rgb.Limit() - rgb.Position()
			Return MatchMaxSize(total, EDataType.rgb).size
		ElseIf ext = "jp2" Then
			If data.Limit() < 16 Then Throw New TCannotDetermineTypeException("Truncated JPEG 2000 header.")
			Local jp2:TByteBuffer = data.Slice()
			If jp2.GetInt() = $FF4FFF51 Then
				' width and height are big-endian 4 byte integers at offset 8 and 12
				Local header:TByteBuffer = data.Slice(8, 8)
				Local width:Int = header.GetInt()
				Local height:Int = header.GetInt()
				Return New SSize(width, height)
			End If
			jp2 = data.Slice()
			jp2.Position(12)
			' file header + type box + header box (super box) + image header box
			Local ftypeLength:Int = jp2.GetInt()
			Local offset:Int = 12 + ftypeLength + 8 + 8
			If ftypeLength < 8 Or offset < 0 Or offset + 8 > data.Limit() Then
				Throw New TCannotDetermineTypeException("Invalid JPEG 2000 box layout.")
			End If
			Local header:TByteBuffer = data.Slice(offset, 8)
			Local height:Int = header.GetInt()
			Local width:Int = header.GetInt()
			Return New SSize(width, height)
		End If
		Return New SSize(-1, -1) ' icns does not support other image types except binary
	End Method

	Method MatchMaxSize:TIcnsMedia(totalSize:Int, dataType:EDataType)

		Assert dataType = EDataType.argb Or dataType = EDataType.rgb, "dataType must be 'argb' or 'rgb'"

		Local ret:TIcnsMedia[]
		For Local media:TIcnsMedia = EachIn mediaTypes.Values()
			If media.IsType(dataType) And media.maxSize = totalSize Then
				ret :+ [media]
			End If
		Next

		Return BestOption(ret, dataType.ToString())
	End Method

	Method _OrderContains:Int(key:String)
		For Local existing:String = EachIn mediaOrder
			If existing = key Then Return True
		Next
		Return False
	End Method

	Method _BufferBytes:Byte[](buffer:TByteBuffer)
		Local copy:TByteBuffer = buffer.Duplicate()
		copy.Position(0)
		Local result:Byte[] = New Byte[copy.Remaining()]
		If result.Length Then copy.GetBytes(result, UInt(result.Length))
		Return result
	End Method

	Method _WriteHeader(output:Byte[], offset:Int, key:String, length:Int)
		If key.Length <> 4 Then Throw New TIcnsAttributeException("An ICNS element key must contain exactly four bytes.")
		For Local i:Int = 0 Until 4
			output[offset + i] = Byte(key[i] & $ff)
		Next
		output[offset + 4] = Byte((length Shr 24) & $ff)
		output[offset + 5] = Byte((length Shr 16) & $ff)
		output[offset + 6] = Byte((length Shr 8) & $ff)
		output[offset + 7] = Byte(length & $ff)
	End Method

	Method _DecodePixmap:TPixmap(key:String, throwUnsupported:Int = True)
		If Not media.ContainsKey(key) Then
			If throwUnsupported Then Throw New TIcnsKeyException("No ICNS element named '" + key + "'.")
			Return Null
		End If
		Local payload:TByteBuffer = media[key]
		Local dataType:EDataType = DetermineDataType(payload.Slice())
		If dataType = EDataType.png Then Return _LoadPng(payload)
		If Not mediaTypes.ContainsKey(key) Then
			If throwUnsupported Then Throw New TIcnsAttributeException("Unknown ICNS element type '" + key + "'.")
			Return Null
		End If
		Local info:TIcnsMedia = mediaTypes[key]
		If dataType = EDataType.argb Then Return _DecodePlanar(payload, info, 4, 4, Null)
		If info.IsType(EDataType.rgb) Then
			Local offset:Int
			If key = "it32" Then
				If payload.Limit() < 4 Then Return Null
				offset = 4
			End If
			Local mask:TByteBuffer
			Local maskKey:String = _MaskKey(key)
			If maskKey And media.ContainsKey(maskKey) Then mask = media[maskKey]
			Return _DecodePlanar(payload, info, 3, offset, mask)
		End If
		If throwUnsupported Then Throw New TIcnsAttributeException("ICNS element '" + key + "' cannot be decoded to a pixmap.")
		Return Null
	End Method

	Method _DecodePlanar:TPixmap(payload:TByteBuffer, info:TIcnsMedia, channels:Int, offset:Int, mask:TByteBuffer)
		Local pixels:Int = info.size.width * info.size.height
		Local unpacked:Byte[] = _Unpack(_BufferBytes(payload), offset, pixels * channels)
		If Not unpacked Then Return Null
		Local pixmap:TPixmap = CreatePixmap(info.size.width, info.size.height, PF_RGBA8888, 4)
		Local maskBytes:Byte[]
		If mask And mask.Limit() = pixels Then maskBytes = _BufferBytes(mask)
		For Local i:Int = 0 Until pixels
			Local a:Int = 255
			Local plane:Int
			If channels = 4 Then
				a = unpacked[i] & $ff
				plane = 1
			ElseIf maskBytes Then
				a = maskBytes[i] & $ff
			End If
			Local r:Int = unpacked[(plane + 0) * pixels + i] & $ff
			Local g:Int = unpacked[(plane + 1) * pixels + i] & $ff
			Local b:Int = unpacked[(plane + 2) * pixels + i] & $ff
			pixmap.WritePixel(i Mod info.size.width, i / info.size.width, (a Shl 24) | (r Shl 16) | (g Shl 8) | b)
		Next
		Return pixmap
	End Method

	Method _LoadPng:TPixmap(payload:TByteBuffer)
		Local bytes:Byte[] = _BufferBytes(payload)
		Local bank:TBank = CreateStaticBank(bytes, bytes.Length)
		Return LoadPixmapPNG(bank)
	End Method

	Method _Unpack:Byte[](source:Byte[], offset:Int, expected:Int)
		If offset < 0 Or offset > source.Length Then Return Null
		Local result:Byte[] = New Byte[expected]
		Local src:Int = offset
		Local dst:Int
		While src < source.Length And dst < expected
			Local control:Int = source[src] & $ff
			src :+ 1
			If control < $80 Then
				Local count:Int = control + 1
				If src + count > source.Length Or dst + count > expected Then Return Null
				MemCopy(Byte Ptr(result) + dst, Byte Ptr(source) + src, Size_T(count))
				src :+ count
				dst :+ count
			Else
				Local count:Int = control - $7d
				If src >= source.Length Or dst + count > expected Then Return Null
				Local value:Byte = source[src]
				src :+ 1
				For Local i:Int = 0 Until count
					result[dst] = value
					dst :+ 1
				Next
			End If
		Wend
		If dst <> expected Or src <> source.Length Then Return Null
		Return result
	End Method

	Method _MaskKey:String(key:String)
		Select key
			Case "is32"; Return "s8mk"
			Case "il32"; Return "l8mk"
			Case "ih32"; Return "h8mk"
			Case "it32"; Return "t8mk"
		End Select
		Return Null
	End Method

	Method GetSize:Int(data:TByteBuffer)
		Local count:Int = 0
		Local i:Int = 0
		Local _end:Int = data.Limit()

		While i < _end
			data.Position(i)
			Local n:Int = data.Get() & $FF

			If n < $80 Then
				If i + n + 1 >= _end Then Throw New TCannotDetermineTypeException("Truncated ICNS PackBits literal run.")
				count :+ n + 1
				i :+ n + 2
			Else
				If i + 1 >= _end Then Throw New TCannotDetermineTypeException("Truncated ICNS PackBits repeat run.")
				count :+ n - 125
				i :+ 2
			End If

		Wend

		Return count
	End Method
End Type

Rem
bbdoc: Loads the largest supported icon in an ICNS container as a pixmap.
End Rem
Function LoadPixmapICNS:TPixmap(url:Object)
	Local stream:TStream = ReadStream(url)
	If Not stream Then Return Null
	Try
		Local file:TIcnsFile = TIcnsFile.Load(stream, String(url))
		Local pixmap:TPixmap = file.ToPixmap()
		stream.Close()
		Return pixmap
	Catch ex:TBlitzException
		stream.Close()
		Return Null
	End Try
End Function

Type TPixmapLoaderICNS Extends TPixmapLoader
	Method LoadPixmap:TPixmap(stream:TStream) Override
		Try
			Return TIcnsFile.Load(stream, Null).ToPixmap()
		Catch ex:TBlitzException
			Return Null
		End Try
	End Method
End Type

Type TIcnsMedia

	Field key:String
	Field types:EDataType[]
	Field size:SSize
	Field channels:Int = -1
	Field bits:Int = -1
	Field availability:String
	Field compressable:Int
	Field retina:Int
	Field maxSize:Int = -1
	Field desc:String
	Field extCertain:Int

	Method New(key:String, types:EDataType[], size:SSize, channels:Int, bits:Int, availability:String, desc:String)
		Self.key = key
		Self.types = types
		Self.size = size

		If IsType(EDataType.argb) Or IsType(EDataType.rgb) Then
			Self.compressable = True
		Else
			Self.compressable = False
		End IF

		If desc.Contains("@2x") Then
			Self.retina = True
		Else
			Self.retina = False
		End If

		If IsType(EDataType.rgb) Then
			channels = 3
			bits = 8
		End If

		If IsType(EDataType.argb) Then
			channels = 4
			bits = 8
		End If

		Self.channels = channels
		Self.bits = bits
		If bits > 0 And channels > 0 Then
			Self.maxSize = (size.width * size.height * channels * bits) / 8
		End If
		Self.availability = availability
		Self.desc = desc

		Self.extCertain = True
		For Local _type:EDataType = EachIn types
			IF Not IsCertainType(_type) Then
				Self.extCertain = False
				Exit
			End If
		Next
	End Method

	Method New(key:String, types:EDataType[], size:Int, channels:Int, bits:Int, availability:String, desc:String)
		New(key, types, New SSize(size, size), channels, bits, availability, desc)
	End Method

	Method New(key:String, dataType:EDataType, size:Int, channels:Int, bits:Int, availability:String, desc:String)
		New(key, [dataType], new SSize(size, size), channels, bits, availability, desc)
	End Method

	Method New(key:String, dataType:EDataType, size:SSize, channels:Int, bits:Int, availability:String, desc:String)
		New(key, [dataType], size, channels, bits, availability, desc)
	End Method

	Method IsCertainType:Int(_type:EDataType)
		Return _type = EDataType.png Or _type = EDataType.argb Or _type = EDataType.plist Or _type = EDataType.jp2 Or _type = EDataType.icns
	End Method

	Method IsType:Int(_type:EDataType)
		For Local i:Int = 0 Until types.Length
			If types[i] = _type Then
				Return True
			End If
		Next

		Return False
	End Method

	Method IsType:Int(_type:String)
		For Local i:Int = 0 Until types.Length
			If types[i].ToString() = _type Then
				Return True
			End If
		Next

		Return False
	End Method

End Type

Struct SSize
	Field width:Int
	Field height:Int

	Method New(width:Int, height:Int)
		Self.width = width
		Self.height = height
	End Method
End Struct

Type TCannotDetermineTypeException Extends TRuntimeException
End Type

Type TIcnsParseException Extends TRuntimeException
End Type

Type TIcnsAttributeException Extends TRuntimeException
End Type

Type TIcnsKeyException Extends TRuntimeException
End Type

Enum EDataType
	none
	png
	argb
	rgb
	plist
	jp2
	icns
	bin
End Enum

TIcnsFile.Init()
New TPixmapLoaderICNS
