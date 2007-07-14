import SPRFile, BMPFile;
alias char[] string;

int main(string args[])
{
	SPRFile spr = new SPRFile();
	BMPFile bmp = new BMPFile();
	
	spr.ExtractSPR(args[1]);

/*	
	int width, height;
	ubyte[] buffer;
	RGBQUAD[] palette;
	palette = cast(RGBQUAD[]) spr.LoadSPR(cast(string)"HOUSES01.SPR", buffer, width, height);
	bmp.SaveBMP("HOUSES01.SPR.bmp", buffer, width, height, 8, 256, palette);
*/
	return 0;
}