/**
 *	Dungeon Keeper 2 decompression tool
 *	Copyright (C) 2010 Trass3r
 */
module compression;

//! the C decompression code
extern(C) void decomp(void* destination, void* source, int uk);

//! small D wrapper
ubyte[] decompress(ubyte[] source) //, out ubyte[] source)
{
    ubyte[] destination = new ubyte[source.length*4];
    decomp(destination.ptr, source.ptr, 0);
    return destination;
}
