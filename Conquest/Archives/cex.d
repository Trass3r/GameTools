/**
 *	Conquest:Frontier Wars archive extractor
 *	Copyright (C) 2007-10 Trass3r
 */
module cex;

import std.stream, std.file;
import std.conv;
import std.stdio;

//! directory entry
struct Entry
{
	uint	NextOffset; // offset of next Entry in same hierarchy level
	uint	NameOffset; // offset of Entry's name in NameTable
	uint	flags;
	uint	uk4;
	uint	DataOffset; // file: offset in File Data, folder: offset of first entry in Table
	uint	TotalSize; // with zeros
	uint	size2;
	uint	size3;
	uint	uk9;
	uint	uk10;
	uint	uk11;
}

//! UTF handler
class UTFFile
{
private:
	string			filename;
	Header			header;
	Entry[]			table;
	char[]			nametable;
	std.stream.File	hIn;
	ubyte[]			buffer;

	void TraverseDir(uint offset)
	{
		uint i = offset/header.EntrySize;

		while(true)
		{
			string name = to!string(nametable.ptr + table[i].NameOffset);
			
			// Eintrag schreiben
			//printf("%.*s\n", name);
			
			if(table[i].flags & 0x10) // ist Ordner
			{
				mkdir(name);
				if (table[i].DataOffset != 0) // Ordner enthält Daten
				{
					chdir(name);
					TraverseDir(table[i].DataOffset);
				}
			}

			if(table[i].flags & 0x80) // ist Datei
			{
			debug if(!(table[i].flags & 0x08000000))
					break;
				auto hOut = new std.stream.File();
				try
				{
					hIn.seek(header.FileDataOffset + table[i].DataOffset, SeekPos.Set);
					hOut.open(name, FileMode.Out);
					if (buffer.length < table[i].size2)
					{
						debug printf("increasing buffer size to %d\n", table[i].size2);
						buffer.length = table[i].size2;
					}
					hIn.readExact(buffer.ptr, table[i].size2);
					debug printf("read the file..");
					hOut.writeExact(buffer.ptr, table[i].size2);
					debug printf("wrote the file\n");
				}
				catch(OpenException e)
				{
					printf("OpenException: %.*s\n", e.toString());
				}
				catch(ReadException e)
				{
					printf("ReadException: %.*s\n", e.toString());
				}
				catch(WriteException e)
				{
					printf("WriteException: %.*s\n", e.toString());
				}
				catch(Exception e)
				{
					printf("Exception: %.*s\n", e.toString());
				}
				finally
				{
					hOut.close();
				}

			}
			if(table[i].NextOffset == 0) // kein weiteres Element auf dieser Ebene
			{
				chdir("..");
				break;
			}
			i = table[i].NextOffset/header.EntrySize; // nächstes Element in selber Ebene durchlaufen
			debug printf("Ende der Schleife\n");
		}
	}

public:
	//!
	this(string filename)
	{
		this.filename = filename;
	}
	
	//!
	void extractAll()
	{
		hIn = new std.stream.File();
		try
		{
			hIn.open(filename, FileMode.In);
			hIn.readExact(&header, 56); // TODO schauen ob sichs in Vollversion ändert
			if (header.signature != "UTF ")
				throw new Exception("Keine UTF-Datei!");
			if (header.ver != 257)
				write("Warnung: Version stimmt nicht ueberein!\n");

			// Namenstabelle lesen
			hIn.seek(header.NameTableOffset, SeekPos.Set);
			nametable.length=header.NameTableSize;
			hIn.readExact(nametable.ptr, header.NameTableSize);
			
			// Tabelle lesen
			hIn.seek(header.TableOffset, SeekPos.Set);
			table.length = header.TableSize/header.EntrySize;
			hIn.readExact(table.ptr, header.TableSize);

			// root überspringen und entsprechenden Ordner erzeugen
			//TODO nimmt an, dass über Konsole übergeben wird und kein Drag n Drop
			mkdir(filename ~ "ext");
			chdir(filename ~ "ext");
			TraverseDir(header.EntrySize);
		}
		catch (Exception e)
		{
			writef("%.*s\n", e.toString());
		}
		finally
		{
			hIn.close();
		}
	}
}

//!
struct Header
{
	char[4]	signature;
	uint	ver; // = 257
	int		TableOffset;
	int		TableSize;
	int		konst0; // 0
	int		EntrySize; // 44
	int		NameTableOffset; // 56
	int		bignametablesize; // with the zeros
	int		NameTableSize; // in bytes
	int 	FileDataOffset;
	int		zero1;
	int		zero2;
	uint	uk5;
	int		konst29428513; // 29428513
}

int main(string[] args)
{
	write("Conquest UTF Extractor v1.0\nCopyright (c) 2007 Hoenir.\n\n");
	if (args.length < 2)
	{
		Usage();
		return -1;
	}
	UTFFile file = new UTFFile(args[1]);
//	if (args.length = 3) // -l ist da
//		file.list();
//	else
		file.extractAll();
	return 0;
}

//!
void Usage()
{
	write("Usage:\ncex filename\n");
}