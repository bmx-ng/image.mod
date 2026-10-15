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
