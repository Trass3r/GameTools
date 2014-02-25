#include <stdint.h>

void dd_init();
// decompress buf to rgba out
void dd_texture(uint32_t* buf, uint8_t* out, uint32_t stride, uint16_t width, uint16_t height);

int main()
{
	dd_init();
	//dd_texture()
	return 0;
}