SuperStrict

Framework BRL.StandardIO
Import BRL.MaxUnit
Import BRL.Bank
Import BRL.BankStream
Import Image.ICNS
Import Image.PNG

New TTestSuite.Run()

Type TIcnsFileTest Extends TTest

	Field fixtures:TPath = New TPath("fixtures")

	Method TestCompatibilityFixtures() { test }
		Local image:TIcnsFile = TIcnsFile.Load(fixtures.Join("rgb.icns"))
		AssertEquals("rgb.icns", image.filename)
		AssertEquals(8, image.MediaKeys().Length)
		For Local expected:String = EachIn ["ICN#", "il32", "l8mk", "ics#", "is32", "s8mk", "it32", "t8mk"]
			AssertTrue(image.HasMedia(expected), "Missing fixture element " + expected)
		Next

		image = TIcnsFile.Load(fixtures.Join("selected.icns"))
		AssertEquals(10, image.MediaKeys().Length)
		For Local expected:String = EachIn ["info", "ic12", "icsb", "sb24", "ic04", "SB24", "ic05", "icsB", "ic11", "slct"]
			AssertTrue(image.HasMedia(expected), "Missing fixture element " + expected)
		Next
	End Method

	Method TestRejectsInvalidContainers() { test }
		AssertParseFailure(LoadByteArray(fixtures.Join("rgb.icns.argb").ToString()))
		AssertParseFailure(LoadByteArray(fixtures.Join("rgb.icns.png").ToString()))
		AssertParseFailure([Byte(Asc("i")), Byte(Asc("c")), Byte(Asc("n")), Byte(Asc("s"))])

		Local badSize:Byte[] = LoadByteArray(fixtures.Join("selected.icns").ToString())
		badSize[7] :- 1
		AssertParseFailure(badSize)

		Local badElement:Byte[] = [Byte(Asc("i")), Byte(Asc("c")), Byte(Asc("n")), Byte(Asc("s")), Byte(0), Byte(0), Byte(0), Byte(16), ..
			Byte(Asc("i")), Byte(Asc("c")), Byte(Asc("0")), Byte(Asc("7")), Byte(0), Byte(0), Byte(0), Byte(7)]
		AssertParseFailure(badElement)
	End Method

	Method TestMediaManagementAndExplicitKey() { test }
		Local image:TIcnsFile = New TIcnsFile
		Local payload:Byte[] = [Byte(Asc("i")), Byte(Asc("c")), Byte(Asc("n")), Byte(Asc("s")), Byte(1), Byte(2), Byte(3), Byte(4)]
		image.AddMedia(payload, "name")
		AssertEquals(8, image.GetMedia("name").Length, "Explicit non-ICNS keys must not lose their first eight bytes")
		AssertTrue(image.HasMedia("name"))
		AssertTrue(image.RemoveMedia("name"))
		AssertFalse(image.RemoveMedia("name"))
	End Method

	Method TestNestedIcnsHeaderRemoval() { test }
		Local nestedBytes:Byte[] = LoadByteArray(fixtures.Join("selected.icns").ToString())
		Local image:TIcnsFile = New TIcnsFile
		image.AddMedia(nestedBytes, Null, "selected.icns")
		AssertTrue(image.HasMedia("slct"))
		AssertEquals(nestedBytes.Length - 8, image.GetMedia("slct").Length)

		Local roundTrip:TIcnsFile = TIcnsFile.Load(image.ToByteArray(), "nested.icns")
		AssertEquals(nestedBytes.Length - 8, roundTrip.GetMedia("slct").Length)
	End Method

	Method TestNativeContainerRoundTripAndToc() { test }
		Local source:TIcnsFile = New TIcnsFile
		Local png:Byte[] = LoadByteArray(fixtures.Join("rgb.icns.png").ToString())
		source.AddMedia(png, "icp4")
		source.AddMedia([Byte(1), Byte(2), Byte(3)], "name")

		Local encoded:Byte[] = source.ToByteArray(True)
		Local loaded:TIcnsFile = TIcnsFile.Load(encoded, "memory.icns")
		AssertEquals(3, loaded.MediaKeys().Length)
		AssertEquals("TOC ", loaded.MediaKeys()[0])
		AssertEquals(png.Length, loaded.GetMedia("icp4").Length)
		AssertEquals(3, loaded.GetMedia("name").Length)
	End Method

	Method TestStreamInputAndOutputRemainOpen() { test }
		Local png:Byte[] = LoadByteArray(fixtures.Join("rgb.icns.png").ToString())
		Local inputBank:TBank = CreateBank(png.Length)
		MemCopy(inputBank.Buf(), png, Size_T(png.Length))
		Local input:TBankStream = CreateBankStream(inputBank)
		Local image:TIcnsFile = New TIcnsFile
		image.AddMedia(input, "icon.png")
		AssertEquals(Long(png.Length), input.Pos())
		AssertEquals(Long(0), input.Seek(0))

		Local outputBank:TBank = CreateBank()
		Local output:TBankStream = CreateBankStream(outputBank)
		image.Save(output, True)
		AssertTrue(output.Pos() > 8)
		AssertEquals(Long(0), output.Seek(0))
	End Method

	Method TestPngTypeGuessing() { test }
		Local image:TIcnsFile = New TIcnsFile
		Local png:Byte[] = LoadByteArray(fixtures.Join("rgb.icns.png").ToString())
		image.AddMedia(png, Null, "icon.png")
		AssertTrue(image.HasMedia("icp4"))

		Local retina:TIcnsFile = New TIcnsFile
		Local selected:TIcnsFile = TIcnsFile.Load(fixtures.Join("selected.icns"))
		retina.AddMedia(selected.GetMedia("ic11"), Null, "icon@2x.png")
		AssertTrue(retina.HasMedia("ic11"))
	End Method

	Method TestJpeg2000TypeGuessing() { test }
		Local image:TIcnsFile = New TIcnsFile
		image.AddMedia(LoadByteArray(fixtures.Join("18x18.j2k").ToString()), Null, "icon.j2k")
		image.AddMedia(LoadByteArray(fixtures.Join("256x256.jp2").ToString()), Null, "icon.jp2")
		AssertTrue(image.HasMedia("icsb"))
		AssertTrue(image.HasMedia("ic08"))
	End Method

	Method TestPixmapRoundTrip() { test }
		Local original:TPixmap = CreatePixmap(32, 32, PF_RGBA8888, 4)
		For Local y:Int = 0 Until original.height
			For Local x:Int = 0 Until original.width
				Local alpha:Int = (x * 7 + y * 3) & $ff
				original.WritePixel(x, y, (alpha Shl 24) | (x Shl 16) | (y Shl 8) | ((x + y) & $ff))
			Next
		Next

		Local image:TIcnsFile = New TIcnsFile
		image.AddPixmap(original)
		AssertTrue(image.HasMedia("icp5"))
		Local loaded:TIcnsFile = TIcnsFile.Load(image.ToByteArray(), "generated.icns")
		Local decoded:TPixmap = loaded.ToPixmap("icp5")
		AssertPixmapEquals(original, decoded)
	End Method

	Method TestLegacyRgbAndMaskDecode() { test }
		Local image:TIcnsFile = TIcnsFile.Load(fixtures.Join("rgb.icns"))
		Local decoded:TPixmap = image.ToPixmap("is32")
		Local expectedRgb:TPixmap = LoadPixmapPNG(fixtures.Join("rgb.icns.png").ToString())
		Local mask:Byte[] = image.GetMedia("s8mk")
		AssertNotNull(decoded)
		AssertEquals(16, decoded.width)
		For Local y:Int = 0 Until 16
			For Local x:Int = 0 Until 16
				Local index:Int = y * 16 + x
				AssertEquals(expectedRgb.ReadPixel(x, y) & $ffffff, decoded.ReadPixel(x, y) & $ffffff)
				AssertEquals(mask[index] & $ff, (decoded.ReadPixel(x, y) Shr 24) & $ff)
			Next
		Next
	End Method

	Method TestCompatibilityRgbPayloadInModernKey() { test }
		Local image:TIcnsFile = TIcnsFile.Load(fixtures.Join("icp4rgb.icns"))
		Local small:TPixmap = image.ToPixmap("icp4")
		Local large:TPixmap = image.ToPixmap("icp5")
		AssertNotNull(small)
		AssertNotNull(large)
		AssertEquals(16, small.width)
		AssertEquals(32, large.width)
	End Method

	Method TestArgbDecode() { test }
		Local image:TIcnsFile = New TIcnsFile
		image.AddMedia(LoadByteArray(fixtures.Join("rgb.icns.argb").ToString()), Null, "icon.argb")
		Local decoded:TPixmap = image.ToPixmap("ic04")
		Local expected:TPixmap = LoadPixmapPNG(fixtures.Join("rgb.icns.png").ToString())
		AssertPixmapEquals(expected, decoded)
	End Method

	Method TestLargestSupportedPixmapSelection() { test }
		Local image:TIcnsFile = TIcnsFile.Load(fixtures.Join("selected.icns"))
		Local pixmap:TPixmap = image.ToPixmap()
		AssertNotNull(pixmap)
		AssertEquals(64, pixmap.width)
		AssertEquals(64, pixmap.height)
	End Method

	Method TestRegisteredPixmapLoader() { test }
		Local path:String = fixtures.Join("selected.icns").ToString()
		Local direct:TPixmap = LoadPixmapICNS(path)
		Local registered:TPixmap = LoadPixmap(path)
		AssertNotNull(direct)
		AssertNotNull(registered)
		AssertEquals(64, direct.width)
		AssertEquals(64, registered.width)
	End Method

	Method TestReferencePngAndArgbMatrix() { test }
		Local names:String[] = [..
			"1024-ic10-png.icns", "128-ic07-png.icns", "16-ic04-png.icns", "16-icp4-png.icns", ..
			"18-icsb-png.icns", "24-sb24-png.icns", "256-ic08-png.icns", "256-ic13-png.icns", ..
			"32-ic05-png.icns", "32-ic11-png.icns", "32-icp5-png.icns", "36-icsB-png.icns", ..
			"48-SB24-png.icns", "48-icp6-png.icns", "512-ic09-png.icns", "512-ic14-png.icns", ..
			"64-ic12-png.icns", "16-ic04-argb.icns", "18-icsb-argb.icns", "32-ic05-argb.icns"]
		Local keys:String[] = [..
			"ic10", "ic07", "ic04", "icp4", "icsb", "sb24", "ic08", "ic13", "ic05", "ic11", ..
			"icp5", "icsB", "SB24", "icp6", "ic09", "ic14", "ic12", "ic04", "icsb", "ic05"]
		Local sizes:Int[] = [1024, 128, 16, 16, 18, 24, 256, 256, 32, 32, 32, 36, 48, 48, 512, 512, 64, 16, 18, 32]

		For Local i:Int = 0 Until names.Length
			CheckSingleReference(names[i], keys[i], sizes[i], True)
		Next
	End Method

	Method TestReferenceJpeg2000PreservationMatrix() { test }
		Local names:String[] = [..
			"1024-ic10-jp2.icns", "128-ic07-jp2.icns", "16-ic04-jp2.icns", "16-icp4-jp2.icns", ..
			"18-icsb-jp2.icns", "24-sb24-jp2.icns", "256-ic08-jp2.icns", "256-ic13-jp2.icns", ..
			"32-ic05-jp2.icns", "32-ic11-jp2.icns", "32-icp5-jp2.icns", "36-icsB-jp2.icns", ..
			"48-SB24-jp2.icns", "48-icp6-jp2.icns", "512-ic09-jp2.icns", "512-ic14-jp2.icns", ..
			"64-ic12-jp2.icns"]
		Local keys:String[] = [..
			"ic10", "ic07", "ic04", "icp4", "icsb", "sb24", "ic08", "ic13", "ic05", "ic11", ..
			"icp5", "icsB", "SB24", "icp6", "ic09", "ic14", "ic12"]
		Local sizes:Int[] = [1024, 128, 16, 16, 18, 24, 256, 256, 32, 32, 32, 36, 48, 48, 512, 512, 64]

		For Local i:Int = 0 Until names.Length
			CheckSingleReference(names[i], keys[i], sizes[i], False)
		Next
	End Method

	Method TestReferenceLegacy48RgbAndMask() { test }
		Local path:TPath = fixtures.Join("reference").Join("48-ih32-rgb.icns")
		Local image:TIcnsFile = TIcnsFile.Load(path)
		AssertEquals(2, image.MediaKeys().Length)
		AssertTrue(image.HasMedia("ih32"))
		AssertTrue(image.HasMedia("h8mk"))
		Local pixmap:TPixmap = image.ToPixmap("ih32")
		AssertNotNull(pixmap)
		AssertEquals(48, pixmap.width)
		AssertEquals(48, pixmap.height)
		For Local y:Int = 0 Until pixmap.height
			For Local x:Int = 0 Until pixmap.width
				AssertEquals(255, (pixmap.ReadPixel(x, y) Shr 24) & $ff)
			Next
		Next
		Local roundTrip:TIcnsFile = TIcnsFile.Load(image.ToByteArray(), "round-trip.icns")
		AssertBytesEqual(image.GetMedia("ih32"), roundTrip.GetMedia("ih32"))
		AssertBytesEqual(image.GetMedia("h8mk"), roundTrip.GetMedia("h8mk"))
	End Method

	Method TestOpaqueClassicAndUnknownElementPreservation() { test }
		Local keys:String[] = ["ICON", "icm#", "icm4", "icm8", "ics4", "ics8", "icl4", "icl8", "ich#", "ich4", "ich8", "icnV", "name", "zzzz"]
		Local lengths:Int[] = [128, 48, 96, 192, 128, 256, 512, 1024, 576, 1152, 2304, 4, 7, 13]
		Local image:TIcnsFile = New TIcnsFile
		For Local i:Int = 0 Until keys.Length
			image.AddMedia(MakeBytes(lengths[i], i + 1), keys[i])
		Next

		Local roundTrip:TIcnsFile = TIcnsFile.Load(image.ToByteArray(True), "opaque.icns")
		AssertTrue(roundTrip.HasMedia("TOC "))
		For Local i:Int = 0 Until keys.Length
			AssertBytesEqual(image.GetMedia(keys[i]), roundTrip.GetMedia(keys[i]), keys[i])
		Next
	End Method

	Method TestNestedTemplateAndDarkElementPreservation() { test }
		Local nested:Byte[] = LoadByteArray(fixtures.Join("selected.icns").ToString())
		Local darkKey:String = Chr($fd) + Chr($d9) + Chr($2f) + Chr($a8)
		Local image:TIcnsFile = New TIcnsFile
		image.AddMedia(nested, "sbtp")
		image.AddMedia(nested, darkKey)
		Local roundTrip:TIcnsFile = TIcnsFile.Load(image.ToByteArray(), "nested-types.icns")
		AssertEquals(nested.Length - 8, roundTrip.GetMedia("sbtp").Length)
		AssertEquals(nested.Length - 8, roundTrip.GetMedia(darkKey).Length)
	End Method

	Method CheckSingleReference(name:String, key:String, size:Int, decodable:Int)
		Local path:TPath = fixtures.Join("reference").Join(name)
		Local image:TIcnsFile = TIcnsFile.Load(path)
		AssertEquals(1, image.MediaKeys().Length, name)
		AssertTrue(image.HasMedia(key), name)
		Local payload:Byte[] = image.GetMedia(key)
		AssertTrue(payload.Length > 8, name)

		If decodable Then
			Local pixmap:TPixmap = image.ToPixmap(key)
			AssertNotNull(pixmap, name)
			AssertEquals(size, pixmap.width, name)
			AssertEquals(size, pixmap.height, name)
		Else
			AssertNull(image.ToPixmap(), name)
		End If

		Local roundTrip:TIcnsFile = TIcnsFile.Load(image.ToByteArray(), "round-trip.icns")
		AssertBytesEqual(payload, roundTrip.GetMedia(key), name)
	End Method

	Method AssertBytesEqual(expected:Byte[], actual:Byte[], message:String = Null)
		AssertNotNull(actual, message)
		AssertEquals(expected.Length, actual.Length, message)
		For Local i:Int = 0 Until expected.Length
			If expected[i] <> actual[i] Then RuntimeError(message + " byte mismatch at " + i)
		Next
	End Method

	Method MakeBytes:Byte[](length:Int, seed:Int)
		Local data:Byte[] = New Byte[length]
		For Local i:Int = 0 Until length
			data[i] = Byte((i * 31 + seed) & $ff)
		Next
		Return data
	End Method

	Method AssertParseFailure(data:Byte[])
		Try
			TIcnsFile.Load(data, "invalid.icns")
			AssertFalse(True, "Expected TIcnsParseException")
		Catch ex:TIcnsParseException
			' expected
		End Try
	End Method

	Method AssertPixmapEquals(expected:TPixmap, actual:TPixmap)
		AssertNotNull(actual)
		AssertEquals(expected.width, actual.width)
		AssertEquals(expected.height, actual.height)
		For Local y:Int = 0 Until expected.height
			For Local x:Int = 0 Until expected.width
				Local expectedPixel:Int = expected.ReadPixel(x, y)
				Local actualPixel:Int = actual.ReadPixel(x, y)
				If expectedPixel <> actualPixel Then
					RuntimeError("Pixel mismatch at " + x + "," + y + ": expected " + expectedPixel + ", got " + actualPixel)
				End If
			Next
		Next
	End Method

End Type
