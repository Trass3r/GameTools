/**
 *	extractor for Commandos 2 .PAK files
 *	Copyright (C) 2007-10 Trass3r
 */
module commex;

import	std.stream,
		std.file,
		std.stdio;

//! directory entry
struct Entry
{
	char[36]	name;
	uint		flags;
	uint		size;
	uint		offset;
}

//! PAK handler
class PAKFile
{
private:
	string filename;
//	Entry[] dictionary;

public:
	this(string filename)
	{
		this.filename = filename;
	}
	
	void extractAll()
	{
		auto hIn = new std.stream.File();
		auto hOut = new std.stream.File();
		Entry entry;
		int i=0;
		ubyte[] buffer;
		try
		{
			hIn.open(filename, FileMode.In);
			stdout.write("extracting..\n");
			do
			{
				hIn.readExact(&entry, 48);
				if (entry.flags == 1)
				{
					i++;
					if (!exists(entry.name))
						mkdir(entry.name);
					chdir(entry.name);
				}
				else if (entry.flags == 255)
				{
					i--;
					chdir("..");
				}
				else if (entry.flags == 0)
				{
					size_t tmp = cast(size_t) hIn.position;
					hIn.seek(entry.offset, SeekPos.Set);
					if (buffer.length < entry.size)
					{
						debug writef("increasing buffer size to %d..\n", entry.size);
						buffer.length = entry.size;
					}
					//printf("%s\n", entry.name);
					hIn.readExact(buffer.ptr, entry.size);
					hOut.open(cast(string) entry.name, FileMode.Out);
					hOut.writeExact(buffer.ptr, entry.size);
					//zurückspringen
					hIn.seek(tmp, SeekPos.Set);
				}
				else
				{
					writef("WARNING: unknown directory entry with name: %s!\n", entry.name);
				}
			} while (i>0);

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
}

int main(string[] args)
{
	write("Commandos PAK Extractor v1.0\nCopyright (c) 2007-10 Trass3r.\n\n");
	if (args.length < 2)
	{
		Usage();
		return -1;
	}
	PAKFile file = new PAKFile(args[1]);
//	if (args.length = 3) // -l ist da
//		file.list();
//	else
		file.extractAll();
	return 0;
}

void Usage()
{
	write("Usage:\nCommEx filename\n");
}