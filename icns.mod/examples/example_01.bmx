SuperStrict

Framework BRL.StandardIO
Import Image.ICNS

Local icon:TIcnsFile = New TIcnsFile

For Local size:Int = EachIn [16, 32, 128, 256, 512, 1024]
	icon.AddPixmap(CreateIcon(size))
Next

icon.Save("generated.icns", True)

Local loaded:TIcnsFile = TIcnsFile.Load("generated.icns")
Print "Wrote generated.icns with " + loaded.MediaKeys().Length + " elements:"
For Local key:String = EachIn loaded.MediaKeys()
	Print "  " + key
Next

Function CreateIcon:TPixmap(size:Int)
	Local pixmap:TPixmap = CreatePixmap(size, size, PF_RGBA8888, 4)
	For Local y:Int = 0 Until size
		For Local x:Int = 0 Until size
			Local red:Int = 32 + (x * 192 / size)
			Local green:Int = 32 + (y * 192 / size)
			Local blue:Int = 224 - ((x + y) * 96 / size)
			pixmap.WritePixel(x, y, $ff000000 | (red Shl 16) | (green Shl 8) | blue)
		Next
	Next
	Return pixmap
End Function
