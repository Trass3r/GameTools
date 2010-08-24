/**
 *	Dungeon Keeper 2 decompression tool
 *	Copyright (C) 2010 Trass3r
 */

#define NULL    ((void *)0)
#define true 1

typedef unsigned int uint;
typedef unsigned char byte;

//! the DK2 decompression function
uint decomp(void* destination, const void* source, int uk)
{
	byte* src=(byte *) source;
	byte* dest=(byte *) destination;

	if(src == NULL)
		return 0;

	uint i=0,j=0;
	if (src[i++] & 1)
		i+=3;
	i++; // skip second byte
	uint decsize = (src[i]<<16) + (src[i+1]<<8) + src[i+2]; // size of decompressed data?
	i+=3; // das eax zeug wird nicht benutzt

	byte flag; // the flag byte read at the beginning of each iteration of the main loop - ESP+10

	uint counter; // counter for all loops
	while(true)
	{
		flag = src[i++];
		if (!(flag & 0x80))
		{
			byte tmp = src[i++];
			counter=flag&3; // mod 4
			while(counter--) // copy literally
			{
				dest[j]=src[i++];
				j++;
			}
			uint k=j; // get the destbuf position
			k -= ((uint)flag&0x60)<<3;
			k -= tmp;
			k--;

			counter=((((uint)flag)>>2)&7)+2;
			do
			{
				dest[j]=dest[k++];
				j++;
			} while(counter--); // correct decrement
		}
		else if (!(flag & 0x40))
		{
			byte tmp = src[i++];
			byte tmp2 = src[i++];
			counter=((uint)tmp)>>6;
			while(counter--) // copy literally
			{
				dest[j]=src[i++];
				j++;
			}
			uint k=j;
			k -= ((uint)tmp&0x3F)<<8;
			k -= tmp2;
			k--;
			counter=(flag&0x3F)+3;
			do
			{
				dest[j]=dest[k++];
				j++;
			} while(counter--); // correct postfix decrement
		}
		else if (!(flag & 0x20))
		{
			byte localtemp=src[i++];
			byte tmp2=src[i++];
			byte tmp3=src[i++];
			counter=flag&3;
			while(counter--) // copy literally
			{
				dest[j]=src[i++];
				j++;
			}
			uint k=j;
			k -= ((uint)flag&0x10)<<12;
			k -= localtemp<<8;
			k -= tmp2;
			k--;
			counter=tmp3+(((uint)flag&0x0C)<<6)+4;
			do
			{
				dest[j]=dest[k++];
				j++;
			} while(counter--); // correct
		}
		else
		{
			counter = (flag & 0x1F)*4 + 4;
			if(counter > 0x70)
				break;
			while(counter--) // copy literally
			{
				dest[j]=src[i++];
				j++;
			}
		}
	} // of while(true)

    // copy the last bytes
	counter=flag&3;
	while(counter--)
	{
		dest[j]=src[i++];
		j++;
	}
	return decsize;
}