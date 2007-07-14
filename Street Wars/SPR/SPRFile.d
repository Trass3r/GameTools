
import std.stream, std.string;
import BMPFile;
alias char[] string;

struct RGBTRIPLE {
	ubyte	r;
	ubyte	g;
	ubyte	b;
}
/*
struct Header {
	uint	NumSprites;
	uint	offsets[NumSprites];
}
*/
struct SpriteHeader {
	ushort	uk1;
	ushort	uk2;
	ushort	width;
	ushort	height;
//	ubyte	data[width*height];
}

class SPRFile
{
private:
//	string	filename;
public:
/*
	this(string filename)
	{
		this.filename = filename;
	}
*/
	ubyte[] LoadSprite(string fileName, string paletteName, out ubyte[] buffer, out int width, out int height)
	{
		ubyte[] outbuf;

		File fp = new File();
		File fcol = new File();
		try
		{
			fp.open(fileName, FileMode.In);
			SpriteHeader sh;

			fp.readExact(&sh, SpriteHeader.sizeof);
			width=sh.width;
			height=sh.height;
			buffer.length = sh.width*sh.height;
			fp.readExact(buffer.ptr, sh.width*sh.height);

			fcol.open(paletteName, FileMode.In);
			outbuf.length = 256*4;
			for(int j=255; j>=0; j--)
			{
				fcol.readExact(outbuf.ptr + j*4, 3);
				outbuf[j*4+3] = 0;
			}
			return outbuf;
		}
		catch (Exception e)
		{
			printf("%.*s\n", e.toString());
		}
		finally
		{
			fcol.close();
			fp.close();
		}
		return null;
	} // LoadSrite
	
	void ExtractSPR(string fileName)
	{
		ubyte[] buffer;
		uint NumSprites;

		File fp = new File();
		File fOut = new File();
		try
		{
			fp.open(fileName, FileMode.In);
			fp.read(NumSprites);
			size_t offset,tmp;
			SpriteHeader sh;

			// Alle Sprites extrahieren
			for (uint i=0; i<NumSprites; i++)
			{
				fp.read(offset);
				if (offset != 0)
				{
					debug printf("offset: %d\n", offset);
					tmp = fp.position;
					fp.seek(offset, SeekPos.Set);
					fp.readExact(&sh, SpriteHeader.sizeof);
					buffer.length = sh.width*sh.height;
					fp.readExact(buffer.ptr, sh.width*sh.height);
					try
					{
						fOut.open(fileName ~ std.string.toString(i) ~ ".spr", FileMode.Out);
						fOut.writeExact(&sh, SpriteHeader.sizeof);
						fOut.writeExact(buffer.ptr, sh.width*sh.height);
					}
					catch (Exception e)
					{
						printf("%.*s\n", e.toString());
					}
					finally
					{
						fOut.close();
					}
					fp.seek(tmp, SeekPos.Set);
				}
			}

			// palette
			fp.read(offset);
			fp.seek(offset, SeekPos.Set);
			debug printf("palette offset: %d\n", offset);
			if (offset != 0)
			{
				buffer.length = 256*4;
				for(uint i=0; i<256; i++)
				{
					fp.readExact(buffer.ptr + i*4, 3);
					buffer[i*4+3] = 0;
				}
				try
				{
					fOut.open(fileName ~ ".col", FileMode.Out);
					fOut.writeExact(buffer.ptr, 256*4);
				}
				catch (Exception e)
				{
					printf("%.*s\n", e.toString());
				}
				finally
				{
					fOut.close();
				}
			}
			debug for (uint i=0; i<NumSprites; i++)
			{
				//import BMPFile;
				int width, height;
				ubyte tmp2;
				RGBQUAD[] palette = cast(RGBQUAD[]) LoadSprite(fileName ~ std.string.toString(i) ~ ".spr", "MICE.COL", buffer, width, height);
				for(uint n=0; n<palette.length; n++)
				{
					tmp2 = palette[n].b;
					palette[n].b = palette[n].r;
//					palette[n].g = palette[n].b;
					palette[n].r = tmp2;
				}
				BMPFile bmp = new BMPFile();
				bmp.SaveBMP(fileName ~ std.string.toString(i) ~ ".bmp", buffer, width, height, 8, 256, palette);
			}
		}
		catch (Exception e)
		{
			printf("%.*s\n", e.toString());
		}
		finally
		{
			fp.close();
		}
	} // ExtractSPR
}