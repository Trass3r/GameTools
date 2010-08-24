/**
 *	tool to decrypt cn.ini
 *	Copyright (C) 2010 Trass3r
 */
module cnini;

import std.stream;
import std.stdio;

//!
void decrypt(string filename)
{
	ubyte[104096] buffer;
	uint header;
	uint tmp;
	auto hFile = new std.stream.File();
	auto hOut = new std.stream.File();
	try
	{
		hFile.open(filename, FileMode.In);
		uint len = hFile.read(buffer);
		ubyte last=0;
		for(int i=0; i<len; i++)
		{
//			tmp = buffer[i];
//			tmp = (tmp-27) & 0xFF
			buffer[i] = cast(ubyte)( ((buffer[i] + i + 0x2D) ^ 0x96) + 0x5B - last );
			last = buffer[i];
		}
		hOut.open(filename ~ ".dec", FileMode.Out);
		hOut.writeExact(buffer.ptr, len);
	}
	catch (Exception e)
	{
		writeln(e.toString());
	}
	finally
	{
		hFile.close();
		hOut.close();
	}
}

//!
int main(string[] args)
{
	if (args.length != 2)
	{
		write("Fehler");
		return -1;
	}
	
	decrypt(args[1]);
	return 0;
}