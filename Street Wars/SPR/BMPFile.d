import std.stream;

alias char[] string;

struct RGBQUAD {
	ubyte	b;
	ubyte	g;
	ubyte	r;
	ubyte	reserved;
}

struct BITMAP
{
	int		bmType;
	int		bmWidth;
	int		bmHeight;
	int		bmWidthBytes;
	ushort	bmPlanes;
	ushort	bmBitsPixel;
	void*	bmBits;
}

struct BITMAPCOREHEADER
{
        uint	bcSize;
        ushort	bcWidth;
        ushort	bcHeight;
        ushort	bcPlanes;
        ushort	bcBitCount;
}

struct BITMAPFILEHEADER
{
align(2):
	char[2]	bfType;
	uint	bfSize;
	ushort	bfReserved1;
	ushort	bfReserved2;
	uint	bfOffBits;
}

struct BITMAPINFOHEADER
{
	uint	biSize;
	int		biWidth;
	int		biHeight;
	ushort	biPlanes;
	ushort	biBitCount;
	uint	biCompression;
	uint	biSizeImage;
	int		biXPelsPerMeter;
	int		biYPelsPerMeter;
	uint	biClrUsed;
	uint	biClrImportant;
}

/// constants for the biCompression field
const int BI_RGB		= 0L;
const int BI_RLE8		= 1L;
const int BI_RLE4		= 2L;
const int BI_BITFIELDS	= 3L;
const int BI_JPEG		= 4L;
const int BI_PNG		= 5L;

uint Widthbytes(uint bits) { return (((bits) + 31) / 32 * 4); }
const int BmpHeaderSize = (BITMAPFILEHEADER.sizeof + BITMAPINFOHEADER.sizeof);
uint BmpBytesPerLine (uint width, uint bits) { return ((((width) * (bits) + 31) / 32) * 4); }
uint BmpPixelSize(uint width, uint height, uint bits) { return (((width * bits + 31) / 32) * 4) * height; }
class BMPFile
{
public:
	string m_errorText;
	size_t m_bytesRead;

	this()
	{
		m_errorText = "OK";
	}

	//	load a .BMP file - 1,4,8,24 bit
	//
	//	allocates and returns an RGB buffer containing the image.
	//	modifies width and height accordingly - NULL, 0, 0 on error
	ubyte[] LoadBMP(string fileName, 
							out uint width, 
							out uint height)
	{
		BITMAPFILEHEADER bmfh;
		BITMAPINFOHEADER bmih;

		ubyte[] outBuf;

		// init
		m_errorText="OK";
		m_bytesRead=0;

		File fp = new File();
		try
		{
			fp.open(fileName,FileMode.In);

			fp.readExact(&bmfh, BITMAPFILEHEADER.sizeof); m_bytesRead += BITMAPFILEHEADER.sizeof;
			fp.readExact(&bmih, BITMAPINFOHEADER.sizeof); m_bytesRead += BITMAPINFOHEADER.sizeof;

			if (bmfh.bfType != "BM") {
				m_errorText = "Not a valid BMP File";
				return null;
	        }

			if (bmih.biCompression != BI_RGB) {
		    	m_errorText = "This is a compressed file.";
		    	return null;
		    }

			if (bmih.biClrUsed == 0)
				bmih.biClrUsed = 1 << bmih.biBitCount;

			// read colormap
			RGBQUAD[] colormap;

			switch (bmih.biBitCount)
			{
			case 24:
				break;
				// read pallete 
			case 1:
			case 4:
			case 8:
				colormap.length = bmih.biClrUsed; // Speicher reservieren
				fp.readExact(colormap.ptr, bmih.biClrUsed * RGBQUAD.sizeof); m_bytesRead += bmih.biClrUsed * RGBQUAD.sizeof;
				break;
			}

			if (m_bytesRead > bmfh.bfOffBits) {
				m_errorText = "Corrupt palette";
				return null;
			}

			while (m_bytesRead < bmfh.bfOffBits) {
				char dummy;
				fp.read(dummy);
				m_bytesRead++;
			}

			int w = bmih.biWidth;
			int h = bmih.biHeight;

			// set the output params
			width=w;
			height=h;

			int row_size = w * 3;
			int bufsize = w * 3 * h;

			// alloc our buffer
			outBuf.length = bufsize;

			int rowOffset;
			// read rows in reverse order
			for (uint row=bmih.biHeight-1; row>=0; row--)
			{
				rowOffset=row*row_size;						      

				if (bmih.biBitCount==24)
				{
					for (int col=0; col<w; col++)
					{
						size_t offset = col * 3;
						ubyte[3] pixel;

						fp.readExact(pixel.ptr, 3);
							// we swap red and blue here
						outBuf[rowOffset + offset + 0]=pixel[2];		// r
						outBuf[rowOffset + offset + 1]=pixel[1];		// g
						outBuf[rowOffset + offset + 2]=pixel[0];		// b
					}
					m_bytesRead+=row_size;
					
					// read DWORD padding
					while ((m_bytesRead-bmfh.bfOffBits) & 3) {
						char dummy;
						fp.read(dummy);
						m_bytesRead++;
					}
					
				}
				else
				{	// 1, 4, or 8 bit image

					// pixels are packed as 1 , 4 or 8 bit vals. need to unpack them
					int bit_count = 0;
					uint mask = (1 << bmih.biBitCount) - 1;

					ubyte inbyte=0;

					for (int col=0;col<w;col++)
					{
						int pix=0;

						// if we need another byte
						if (bit_count <= 0) {
							bit_count = 8;
							fp.readExact(&inbyte, 1);
							m_bytesRead++;
						}

						// keep track of where we are in the bytes
						bit_count -= bmih.biBitCount;
						pix = ( inbyte >> bit_count) & mask;

						// lookup the color from the colormap - stuff it in our buffer
						// swap red and blue
						outBuf[rowOffset + col * 3 + 2] = colormap[pix].b;
						outBuf[rowOffset + col * 3 + 1] = colormap[pix].g;
						outBuf[rowOffset + col * 3 + 0] = colormap[pix].r;
					}

					// read DWORD padding
					while ((m_bytesRead-bmfh.bfOffBits) & 3) {
						char dummy;
						fp.read(dummy);
						m_bytesRead++;
					}
				}
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
		return outBuf;
	}

	//	write a 24-bit BMP file
	//
	//	image MUST be a packed buffer (not DWORD-aligned)
	//	image MUST be vertically flipped !
	//	image MUST be BGR, not RGB !
	//
	void SaveBMP(string fileName,		// output path
		ubyte[] buf,				// BGR buffer
		uint width,				// pixels
		uint height)
	{
	    long pixeloffset=54;
	    long compression=0;
	    long cmpsize=0;
	    long colors=0;
	    long impcol=0;

		m_errorText="OK";

		uint widthDW = Widthbytes(width * 24);

		long bmfsize=BITMAPFILEHEADER.sizeof + BITMAPINFOHEADER.sizeof +
	  							widthDW * height;	
		size_t byteswritten=0;

		BITMAPFILEHEADER bmfh;
		bmfh.bfType[0] = 'B';
		bmfh.bfType[1] = 'M';
	    bmfh.bfSize= bmfsize; 
	    bmfh.bfReserved1=0; 
	    bmfh.bfReserved2=0; 
	    bmfh.bfOffBits=pixeloffset; 

		File fp = new File();
		try
		{
			fp.open(fileName, FileMode.Out);

			fp.writeExact(&bmfh, BITMAPFILEHEADER.sizeof); byteswritten += BITMAPFILEHEADER.sizeof;

			BITMAPINFOHEADER bmih;
		  	bmih.biSize=40; 						// header size
			bmih.biWidth=width;
			bmih.biHeight=height;
			bmih.biPlanes=1;
			bmih.biBitCount=24;					// RGB encoded, 24 bit
			bmih.biCompression=BI_RGB;			// no compression
			bmih.biSizeImage=0;
			bmih.biXPelsPerMeter=0;
			bmih.biYPelsPerMeter=0;
			bmih.biClrUsed=0;
			bmih.biClrImportant=0;

			fp.writeExact(&bmih, BITMAPINFOHEADER.sizeof); byteswritten += BITMAPINFOHEADER.sizeof;

			int rowidx;
			int row_size = bmih.biWidth * 3;
			for (uint row=0; row<bmih.biHeight; row++) {
				rowidx=row*row_size;						      

				// write a row
				fp.writeExact(buf.ptr + rowidx, row_size);
				byteswritten+=row_size;	

				// pad to DWORD
				for (uint count=row_size; count<widthDW; count++) {
					char dummy=0;
					fp.write(dummy);
					byteswritten++;							  
				}
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
	}

	//	1,4,8 bit BMP stuff
	//
	//	if you have a color-mapped image and a color map...
	//
	//	the BMP saving code in SaveColorMappedBMP modified from Programming 
	//	for Graphics Files in C and C++, by John Levine.
	void SaveBMP(string fileName, 			// output path
		ubyte[] colormappedbuffer,	// one ubyte per pixel colomapped image
		uint width,
		uint height,
	 	int bitsperpixel,			// 1, 4, 8
		int colors,				// number of colors (number of RGBQUADs)
		RGBQUAD[] colormap)			// array of RGBQUADs 
	{
		int datasize, cmapsize, byteswritten;

		m_errorText="OK";

		if (bitsperpixel == 24) {
			// the routines could be combined, but i don't feel like it
			m_errorText="We don't do 24-bit files in here, sorry";
			return;
		} else
			cmapsize = colors * 4;

		datasize = BmpPixelSize(width, height, bitsperpixel);

		int filesize = BmpHeaderSize + cmapsize + datasize;

		int pixeloffset = BmpHeaderSize + cmapsize;

		int compression = BI_RGB; // no compression
		int xscale = 0;
		int yscale = 0;
		int impcolors = colors;

		File fp = new File();
		fp.open(fileName, FileMode.Out);
		try
		{
			BITMAPFILEHEADER bmfh;
			bmfh.bfType[0]='B';
			bmfh.bfType[1]='M';
		    bmfh.bfSize= filesize; 
		    bmfh.bfReserved1=0; 
		    bmfh.bfReserved2=0; 
		    bmfh.bfOffBits=pixeloffset; 

			fp.writeExact(&bmfh, BITMAPFILEHEADER.sizeof); byteswritten += BITMAPFILEHEADER.sizeof;

			BITMAPINFOHEADER bmih;
			bmih.biSize = BITMAPINFOHEADER.sizeof; 
			bmih.biWidth = width; 
			bmih.biHeight = height;
			bmih.biPlanes = 1; 
			bmih.biBitCount =bitsperpixel;
			bmih.biCompression = compression; 
			bmih.biSizeImage = datasize; 
			bmih.biXPelsPerMeter = xscale; 
			bmih.biYPelsPerMeter = yscale; 
			bmih.biClrUsed = colors;
			bmih.biClrImportant = impcolors;
			
			fp.writeExact(&bmih, BITMAPINFOHEADER.sizeof);

			if (cmapsize) {
				fp.writeExact(colormap.ptr, colormap.length * RGBQUAD.sizeof);
			}

			byteswritten = BmpHeaderSize + cmapsize;

			for (uint row=0; row < height; row++)
			{
				int pixbuf = 0;
				int nbits = 0;

				for (uint col=0; col < width; col++)
				{
					int offset = row * width + col;	// offset into our color-mapped RGB buffer
					ubyte pval = colormappedbuffer[offset];

					pixbuf = (pixbuf << bitsperpixel) | pval;

					nbits += bitsperpixel;

					if (nbits > 8) {
						m_errorText = "Error : nBits > 8????";
						return;
					}

					if (nbits == 8) {
						fp.write(cast(ubyte)pixbuf);
						pixbuf=0;
						nbits=0;
						byteswritten++;
					}
				}

				if (nbits > 0) {
					fp.write(cast(ubyte)pixbuf); // write partially filled byte
					byteswritten++;
				}

				// DWORD align
				while ((byteswritten -pixeloffset) & 3) {
					fp.write(cast(ubyte) 0);
					byteswritten++;
				}

			}

			if (byteswritten!=filesize) {
				m_errorText="byteswritten != filesize";
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
	}
}