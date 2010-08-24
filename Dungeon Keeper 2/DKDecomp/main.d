/**
 *	Dungeon Keeper 2 decompression tool
 *	Copyright (C) 2010 Trass3r
 */
module main;

import compression;
import std.file;

int main(string[] args)
{
    ubyte[] buffer = cast(ubyte[]) read("test.kmf");
    ubyte[] outbuf = decompress(buffer);
    write("test.kmf.dec", outbuf);
    return 0;
}
