/**
 *	Enemy Territory decrypter
 *	Copyright (C) 2010 Trass3r
 */
module etd;

import std.stream;
import std.stdio;

//! decryption table
__gshared immutable ubyte[1024] feld = [0x73,0x35,0x9E,0xBB,0xF4,0xD7,0x9C,0xFF,
0x98,0xD4,0xCE,0x00,0xF8,0xE4,0x1B,0x25,0x25,0xC1,0x13,0x38,0x5A,0xD0,0x9A,0x55,
0x65,0x5B,0x41,0xFD,0xAE,0x73,0xA1,0xE6,0x29,0x24,0xB7,0x91,0xF9,0xE8,0x14,0xCC,
0x50,0x7B,0x2C,0x8F,0xF4,0xCF,0x70,0xBB,0xF6,0xFA,0xBC,0xD8,0x93,0x35,0x1B,0x76,
0x13,0x26,0x9E,0x37,0xF7,0x41,0x0C,0x06,0xF3,0xA1,0x89,0xAE,0xFA,0xAA,0x22,0x51,
0x2C,0x78,0x7F,0x84,0x41,0xB8,0xFB,0xE5,0xA0,0x24,0x02,0x6C,0x4D,0x7B,0xEA,0x7F,
0xA7,0x14,0x4F,0x70,0x68,0x80,0x7A,0x39,0xA1,0xDF,0xB6,0x67,0x57,0x3E,0xCB,0xE9,
0x3E,0x51,0xE5,0x21,0x41,0x96,0x96,0x58,0xAB,0x66,0xB2,0xF2,0x6E,0x3E,0x12,0xCE,
0x17,0x00,0x0C,0xCD,0xC1,0x68,0xD0,0xAA,0xBF,0xD7,0xE4,0x65,0xFC,0x2A,0x74,0x4C,
0x6F,0x55,0x6C,0x47,0x98,0xAC,0x8F,0xC1,0xA4,0x6A,0x8E,0xAD,0x7D,0x49,0xF7,0x5F,
0xAA,0x0C,0x18,0x22,0x1D,0x6F,0x84,0xB8,0x94,0x89,0x6A,0x9F,0x0E,0xDB,0xD8,0xB0,
0x0C,0x66,0x37,0xBF,0xA0,0x04,0x8C,0x83,0x98,0x23,0xC2,0x9F,0x10,0xA7,0x49,0xBF,
0x12,0x78,0x4A,0xEB,0xC9,0x80,0xAB,0x3A,0x0E,0x98,0x1B,0x2F,0x11,0x8E,0xB2,0xBC,
0x7A,0x01,0xCB,0xD6,0xE1,0x3B,0xBA,0xCD,0x76,0x3B,0xBF,0xC3,0x35,0x02,0x0E,0xCF,
0x34,0x71,0xD8,0x00,0x10,0x97,0x3B,0x50,0x24,0x88,0xE9,0x36,0xFD,0x7C,0xA4,0x68,
0x00,0xEC,0xC6,0xD3,0xC5,0x39,0xA5,0xAF,0x81,0x2E,0x9F,0xA9,0x1B,0xA2,0x92,0x3D,
0x5B,0xE8,0x13,0x93,0x44,0x61,0xD3,0x86,0xBB,0x8E,0x0E,0x52,0x16,0xF4,0xE5,0xC3,
0x2D,0xE2,0xA5,0x4A,0x0E,0xE7,0xF1,0x18,0x05,0xDB,0x72,0x9D,0xC1,0x3D,0x49,0xBA,
0x20,0x94,0x8E,0x9E,0x5F,0x71,0x19,0x34,0x85,0xEA,0xAD,0x1E,0xA1,0xCD,0x32,0xB8,
0x6D,0x69,0x92,0x78,0x1A,0xD6,0x9E,0xAC,0x08,0xF5,0xEA,0x66,0x06,0x62,0x9B,0x10,
0xF3,0x7E,0x11,0xA9,0x42,0x4A,0x6E,0x05,0x61,0x52,0x0F,0xD6,0x82,0x42,0x97,0xD0,
0x44,0xED,0x0F,0xBE,0x34,0xB0,0xF6,0x24,0x6C,0xD7,0x93,0x97,0x89,0xE0,0xAC,0xD9,
0xC8,0x89,0x69,0x44,0x21,0x3D,0xB1,0xDE,0x41,0xE3,0xCF,0xB5,0x43,0x31,0xCB,0x74,
0xD5,0x7E,0xE8,0x2C,0x01,0xA2,0xA1,0x51,0x09,0x50,0xE7,0x22,0xBF,0x3D,0xA5,0xAF,
0xF1,0xC1,0xDD,0xC7,0x40,0x60,0x74,0xDF,0xAB,0x2B,0x60,0x04,0x0E,0x30,0xAD,0xA0,
0x11,0x2E,0xA6,0xFB,0x8D,0x5F,0x40,0xE1,0x6C,0x5A,0xDC,0xA7,0xDF,0xE1,0x0A,0x52,
0x53,0x46,0x13,0x8F,0xBD,0xF9,0xA3,0x59,0x9A,0xB9,0xBA,0x36,0x29,0xD3,0xD1,0xEE,
0xC0,0x4E,0x6C,0x0D,0x3F,0x27,0xA9,0xEF,0x69,0x9A,0x3A,0x58,0x4B,0x3C,0x7E,0xC7,
0x62,0x5C,0x44,0xC0,0xAE,0x9B,0x1A,0xE6,0xFA,0x6D,0xF1,0xD2,0xDE,0xF4,0xC5,0xDE,
0x16,0xEA,0x7E,0x26,0xE5,0x24,0xA2,0x35,0xB2,0x6D,0x89,0xCE,0xBD,0x1A,0xBB,0x5D,
0xD9,0x95,0x26,0x5B,0xD5,0x60,0x43,0x59,0x5B,0xE7,0x40,0x68,0x05,0x02,0xA7,0x79,
0xF5,0x01,0xF3,0x83,0x15,0x33,0x18,0xB8,0xD5,0xFC,0x34,0x8E,0xAA,0x9D,0xCB,0xE5,
0xCD,0x53,0x0D,0xF5,0x24,0x92,0xD5,0x64,0xB5,0xAE,0xC5,0x03,0xC7,0xF4,0x24,0x46,
0x35,0xCD,0x3A,0xF8,0xCD,0x70,0xC8,0xC8,0xF4,0xE3,0x44,0x37,0xB6,0x66,0x19,0x45,
0xDC,0xF6,0x22,0x73,0x84,0x65,0x3F,0xAE,0xEF,0x27,0x8B,0xB2,0xB8,0xE5,0x8E,0x7D,
0x45,0xDB,0xAE,0x3F,0x03,0xE5,0xD5,0xF5,0x63,0x2A,0x88,0xF8,0x15,0x6D,0x00,0x32,
0xB7,0xD6,0x51,0x11,0xD8,0x1B,0xA7,0x43,0x6F,0x5F,0xD2,0x10,0x54,0x4E,0xF2,0xB5,
0xEA,0x9E,0x41,0xCB,0x36,0x10,0x38,0x9F,0x10,0xC5,0x2E,0x56,0x00,0xBD,0xC0,0xDB,
0xA8,0x03,0x3A,0xFB,0x02,0x09,0x92,0x71,0xE9,0x92,0xA4,0x39,0xE9,0x93,0xB5,0x21,
0x58,0xEA,0x1B,0xDA,0x53,0xC0,0xA8,0xBB,0x44,0x08,0xAD,0x06,0x12,0x57,0x48,0x4E,
0x1B,0x5E,0xB1,0x86,0x7D,0xD2,0x92,0x59,0xA3,0xE2,0xB5,0xB4,0x59,0xD4,0xA8,0x14,
0x7F,0x27,0x18,0xAA,0x4E,0x3B,0xD8,0x34,0xEC,0xDA,0x95,0x36,0x89,0x45,0xB8,0x7E,
0xA6,0xD3,0xD8,0x49,0x4B,0x08,0xA7,0x6E,0x4A,0x15,0xD5,0x52,0xC6,0xEC,0x9B,0xB0,
0x62,0x94,0x88,0x2B,0xCC,0x4C,0x37,0xAF,0x89,0x72,0x54,0xA0,0x4D,0x08,0xB3,0xB7,
0x91,0x71,0x00,0x27,0x21,0x04,0xAC,0x94,0xEB,0xC3,0x59,0xF6,0xED,0xB2,0x07,0x58,
0x06,0x80,0xD9,0x9F,0x23,0x7B,0x04,0xC6,0x2B,0xF7,0x3D,0xD8,0xD5,0xB8,0xFC,0x56,
0x16,0xA7,0xBE,0x56,0x46,0xC2,0x14,0x5B,0xCC,0xA1,0x31,0x33,0xF4,0x2E,0x12,0xA7,
0xA1,0x89,0x7F,0xF5,0x1A,0xEC,0x4B,0x21,0x9D,0x4F,0x7D,0xEB,0xEA,0x43,0xAC,0x82,
0x41,0x22,0x35,0x34,0x9F,0x03,0x97,0xE7,0x3A,0x5B,0xFB,0xFA,0x48,0xFF,0x74,0x25,
0xDA,0xF5,0x67,0xCA,0x71,0x80,0xA1,0xCF,0x01,0xF2,0x6A,0xA1,0xFE,0x80,0xCF,0xB0,
0x13,0xD9,0xB2,0x8D,0x45,0xF7,0x1F,0x76,0x9D,0x70,0x60,0x37,0x0C,0x11,0xDD,0xB9,
0xCA,0x59,0x02,0x70,0x47,0x91,0xC4,0xBC,0xD9,0x75,0x69,0x08,0x50,0x5F,0x4B,0xB9,
0x2C,0x2D,0x28,0x06,0xC8,0x87,0x6C,0xE8,0x6B,0x50,0xC1,0xE1,0x08,0x31,0xED,0xBF,
0x8B,0xA6,0x4B,0x32,0x1F,0x79,0x07,0x81,0x65,0x4E,0xF9,0xFA,0x6C,0x0E,0xF1,0x36,
0x26,0x90,0x90,0xF4,0x36,0x18,0xDF,0x9F,0x49,0x65,0x5B,0x2C,0x62,0x0B,0x16,0xE5,
0x07,0x8F,0xCF,0xF3,0x4D,0x35,0xB0,0x8A,0x24,0xA1,0x56,0xB9,0xFA,0x14,0x0C,0xE4,
0x90,0x37,0x6F,0xC8,0x9E,0xD0,0xA6,0x74,0xED,0x62,0x4E,0xBB,0xBF,0x19,0x38,0xA3,
0xF7,0x10,0x74,0x0D,0x34,0x7C,0x19,0xEC,0xC6,0xCD,0xBD,0x6E,0x08,0xCD,0x5E,0xAD,
0x8B,0xD2,0x4D,0x18,0x45,0x2B,0xE0,0xD2,0x91,0x10,0x29,0x9E,0xD6,0x91,0xB1,0x4F,
0xC7,0xBB,0xEC,0x4A,0x86,0xFD,0xB9,0x0D,0xDD,0xDD,0x7A,0x15,0x93,0x20,0x59,0xF2,
0xFA,0x67,0x23,0x14,0x37,0xD2,0xC3,0xAA,0x9A,0xE3,0xD2,0x18,0xC3,0xE6,0x7D,0xE6,
0xD7,0x66,0x96,0x2B,0x95,0xA8,0xF3,0xCD,0xB9,0x1F,0x95,0x91,0xA0,0x0B,0x8D,0x60,
0x89,0xB4,0x0D,0xE7,0x66,0xDE,0x59,0xAC,0xC1,0xCD,0x2E,0xB0,0x7A,0x64,0xAA,0x6D,
0x01,0x14,0x5F,0x13,0x5C,0x75,0x48,0x40,0x9E,0x84,0x72,0xF1,0xFC,0x09,0xE1,0xC3,
0x70,0xD0,0xD9,0x81,0x24,0x0E,0xBB,0xA8];

void Nutzung()
{
	write("Enemy Territory Decryption Tool v1.0\nCopyright 2007 Hoenir.\nUsage: etd <pk4 file>\n");
}

int main(string[] args)
{
	Nutzung();
	if (args.length != 2)
		return -1;
	uint res = 0;
	ubyte[1024] puffer = 0;
	auto eingabe = new std.stream.File;
	auto ausgabe = new std.stream.File;
	try
	{
		eingabe.open(args[1], FileMode.In);
		ausgabe.open(args[1] ~ ".mod", FileMode.Out);
		while (!eingabe.eof())
		{
			res = eingabe.read(puffer);
			for(int i=0; i<res; i++)
			{
				puffer[i] ^= feld[i];
			}
			ausgabe.writeExact(puffer.ptr, res);
		}
	}
	catch(Exception e)
	{
		printf("%.*s\n", e.toString());
	}
	finally
	{
		eingabe.close();
		ausgabe.close();
	}
	return 0;
}