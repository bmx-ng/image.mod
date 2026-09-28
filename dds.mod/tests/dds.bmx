SuperStrict
Framework Image.DDS
Import BRL.StandardIO
Import "fixture.bmx"

Function Check(ok:Int,message:String)
	If Not ok Then Throw message
End Function

Type TForwardStream Extends TStream
	Field source:TStream
	Field closed:Int
	Method Read:Long(buffer:Byte Ptr,count:Long) Override
		Return source.Read(buffer,Min(count,3:Long))
	End Method
	Method Close() Override
		closed=True
	End Method
End Type

Try
	Check(HasTextureDataLoaders(),"Import registers loader")
	For Local format:Int=EachIn [PF_BC1_RGBA,PF_BC3_RGBA]
		For Local dx10:Int=0 Until 2
			Local bytes:Byte[]=DDSTestBytes(format,4,dx10)
			Local stream:TBankStream=DDSTestStream(bytes)
			Local data:TTextureData=LoadTextureData(stream)
			Check(data.Format()=format And data.LevelCount()=4 And data.CompleteMipChain(),"Format and mip chain")
			Check(data.Width()=8 And data.Level(2).Width()=2,"Mip dimensions")
			Check(stream.Pos()=bytes.Length,"Consumes exactly texture payload")
			stream.Seek(0)
			Check(stream.ReadByte()=Asc("D"),"Caller stream remains open")
			Local forward:TForwardStream=New TForwardStream
			forward.source=DDSTestStream(bytes)
			Check(LoadTextureDDS(forward).LevelCount()=4 And Not forward.closed,"Explicit loader supports short forward-only reads")
		Next
	Next
	Local singleBytes:Byte[]=DDSTestBytes(PF_BC1_RGBA,1)
	DDSTestPut(singleBytes,28,0)
	DDSTestPut(singleBytes,8,0)
	Check(LoadTextureData(DDSTestStream(singleBytes)).LevelCount()=1,"Legacy zero mip count and missing advisory flags")
	Local trailing:TBankStream=DDSTestStream(DDSTestBytes()+[Byte(123)])
	LoadTextureData(trailing)
	Check(trailing.ReadByte()=123,"Trailing stream data is preserved")
	Local partial:TTextureData=LoadTextureData(DDSTestStream(DDSTestBytes(PF_BC3_RGBA,2)))
	Check(partial.LevelCount()=2 And Not partial.CompleteMipChain(),"Partial chain retained")
	Local unknown:TBankStream=DDSTestStream(New Byte[10])
	unknown.Seek(3)
	Check(Not LoadTextureData(unknown) And unknown.Pos()=3,"Unknown stream position preserved")
	Local prefixed:TBankStream=DDSTestStream(New Byte[7]+DDSTestBytes())
	prefixed.Seek(7)
	Check(LoadTextureData(prefixed).LevelCount()=4,"Loading starts at caller's position")
	For Local invalid:Int=0 Until 14
		Local bytes:Byte[]=DDSTestBytes(PF_BC3_RGBA,4,True)
		Select invalid
			Case 0
				bytes=bytes[..60]
			Case 1
				bytes=bytes[..bytes.Length-1]
			Case 2
				DDSTestPut(bytes,4,123)
			Case 3
				DDSTestPut(bytes,76,31)
			Case 4
				DDSTestPut(bytes,16,0)
			Case 5
				DDSTestPut(bytes,16,$ffffffff:Long)
			Case 6
				DDSTestPut(bytes,28,5)
			Case 7
				DDSTestPut(bytes,112,$200)
			Case 8
				DDSTestPut(bytes,140,2)
			Case 9
				DDSTestPut(bytes,132,4)
			Case 10
				DDSTestPut(bytes,128,78) ' BC3 sRGB
			Case 11
				DDSTestPut(bytes,144,2) ' premultiplied
			Case 12
				DDSTestPut(bytes,84,$34545844) ' DXT4
			Case 13
				DDSTestPut(bytes,16,$40000000)
		End Select
		Local rejected:Int
		Try
			LoadTextureData(DDSTestStream(bytes))
		Catch error:Object
			rejected=True
		End Try
		Check(rejected,"Invalid/unsupported DDS rejected "+invalid)
	Next
	Print "DDS texture loader tests passed"
Catch error:Object
	Print "FAILED: "+error.ToString()
	EndWithCode(1)
End Try
