/**
 *	Street Wars .FIL extractor
 *	Copyright (C) 2010 Trass3r
 */
module filextract;

import std.stream;
import std.stdio;

//!
align(1) struct Entry
{
	char[13] filename;
	uint	 offset;
}

//! FIL handler
class FILFile
{
private:
	string filename;
	Entry[] directory;

	void decrypt()
	{
		debug write("decrypting...\n");
		ubyte* buffer;
		uint header;
		auto hFile = new std.stream.File();
		try
		{
			hFile.open(filename, FileMode.In);
			hFile.readExact(&header, 4);
			header ^= 0x3BD7A59A;	// Anzahl der Verzeichniseinträge
			directory.length = header;
			header = (header /* + 1*/) * 17; // Größe eines Verzeichniseintrags
			hFile.readExact(directory.ptr, header);
			buffer = cast(ubyte *)directory.ptr;
			for(int i=0; i<header; i++)
			{
				buffer[i] = cast(ubyte)( ((buffer[i] - 0x27) ^ 0xA5) - 0x1B - i );
			}
		}
		catch (Exception e)
		{
			writeln(e.toString());
		}
		finally
		{
			hFile.close();
		}
	}

public:
	//!
	this(string filename)
	{
		this.filename = filename;
	}

	//!
	void extract()
	{
		decrypt();
		writef("extracting %i files...\n", directory.length-1);
/*		File hOut = new File();
		hOut.open("test.dat", FileMode.Out);
		hOut.writeExact(directory.ptr, directory.length*17);
		hOut.close();
*/
		byte[] buffer;
		auto hIn = new std.stream.File();
		auto hOut = new std.stream.File();
//		uint nextoffset;

		try
		{
			hIn.open(filename, FileMode.In);
			hIn.seek(directory[0].offset, SeekPos.Set);
			
			for(int i=0; i<directory.length-1; i++)
			{
//				hIn.seek(directory[i].offset, SeekPos.Set);
				uint size = directory[i+1].offset - directory[i].offset;
				writef("filename:\t%s\tsize:\t%i\n", directory[i].filename, size);
				debug writef("directory[%i].offset = %i\ndirectory[%i].offset=%i\n", i+1, directory[i+1].offset, i, directory[i].offset);

				buffer.length = size;
				hIn.readExact(buffer.ptr, size);
				try
				{
					hOut.open(cast(string) directory[i].filename, FileMode.Out);
					hOut.writeExact(buffer.ptr, size);
				}
				catch(Exception e)
				{
					writeln(e.toString());
				}
				finally {
					hOut.close();
				}
			}
		}
		catch (Exception e)
		{
			writeln(e.toString());
		}
		finally
		{
			hIn.close();
		}
	}
	
	//! list files in archive
	void list()
	{
		decrypt();
		writef("Archive contains %i files:\n", directory.length-1);
		for(int i=0; i<directory.length-1; i++)
		{
			uint size = directory[i+1].offset - directory[i].offset;
			writef("filename:\t%s\tsize:\t%i\n", directory[i].filename, size);
		}
	}
}

//! main function
int main(string[] args)
{
	write("Street Wars FIL Extractor v1.0\nCopyright (c) 2007 Trass3r.\n\n");
	if (args.length < 2)
	{
		Usage();
		return -1;
	}
	FILFile file = new FILFile(args[1]);
//	if (args.length = 3) // -l ist da
//		file.list();
//	else
		file.extract();
	return 0;
}

void Usage()
{
	write("Usage:\nfilextract filename\n");
}