#include <stdint.h>
#include <string.h>

// external buffers and data to be supplied with sizes
static uint32_t magic_input_table_6c10c0[64];
static uint8_t jump_table_7af4e0[256];
static uint32_t dc_control_table_7af0e0[224];

static float float_7af000;
static float float_7af004;
static float float_7af008;
static float float_7af00c;
static float float_7af010;
static float float_7af014;
static float float_7af018;

static uint32_t norm_7af038;
static float float_7af03c;
static float float_7af040;
static float float_7af044;
static double double_7af048;

uint32_t* bs;
uint32_t bs_index;
uint32_t bs_red = 0;
uint32_t bs_green = 0;
uint32_t bs_blue = 0;
uint32_t bs_alpha = 0;
uint32_t alpha_flag = 0;

int32_t magic_output_table[64]; // magic values computed from magic input

int32_t decompress2_chunk[256]; // buffers
int32_t decompress3_chunk[288];
int32_t decompress4_chunk[512];

uint32_t bs_read(uint32_t pos, int bits)
{
	uint32_t word_index = pos / 32;
	uint32_t shamt = pos & 0x1f;
	uint32_t w1 = bs[word_index] << shamt;
	uint32_t w2 = shamt ? bs[word_index + 1] >> (32 - shamt) : 0;
	w1 |= w2;
	w1 >>= (32 - bits);

	return w1;
}

uint32_t prepare_decompress(uint32_t value, uint32_t pos)
{
	int32_t xindex, index, control_word;
	uint8_t magic_index = 0x3f;

	decompress2_chunk[0] = value * magic_output_table[0];
	memset(&decompress2_chunk[1], 0, sizeof(decompress2_chunk) - sizeof(uint32_t));

loop:
	xindex = index = bs_read(pos, 17);
	if (index >= 0x8000)
	{
		uint32_t out_index;
		index >>= 13;
		control_word = dc_control_table_7af0e0[60 + index];
	are_we_done:
		if ((control_word & 0xff00) == 0x4100)
			goto done;
		if ((control_word & 0xff00) > 0x4100)
		{
			uint16_t unk14;
			// read next control
			pos += control_word >> 16;
			unk14 = bs_read(pos, 14);
			pos += 14;
			magic_index -= (unk14 & 0xff00) >> 8;
			unk14 &= 0xff;
			if (unk14)
			{
				if (unk14 != 0x80)
				{
					if (unk14 > 0x80)
						unk14 -= 0x100;
					magic_index--;
				}
				else
				{
					unk14 = bs_read(pos, 8);
					pos += 8;
					unk14 -= 0x100;
				}
			}
			else
			{
				unk14 = bs_read(pos, 8);
				pos += 8;
			}
			control_word = unk14;
		}
		else
		{
			int bit_to_test;
			uint32_t rem = control_word >> 16;
			uint32_t xoramt = 0;

			magic_index -= (control_word & 0xff00) >> 8;
			bit_to_test = 16 - rem;
			if (xindex & (1 << bit_to_test))
				xoramt = ~0;
			control_word &= 0xff;
			control_word ^= xoramt;
			pos++;
			control_word -= xoramt;
			pos += rem;
		}
		out_index = dc_control_table_7af0e0[magic_index + 1];
		decompress2_chunk[out_index] = ((int16_t)control_word) * magic_output_table[out_index];
		goto loop;
	}
	else if (index >= 0x800)
	{
		index >>= 9;
		control_word = dc_control_table_7af0e0[72 + index];
		goto are_we_done;
	}
	else if (index >= 0x400)
	{
		index >>= 7;
		control_word = dc_control_table_7af0e0[128 + index];
		goto are_we_done;
	}
	else if (index >= 0x200)
	{
		index >>= 5;
		control_word = dc_control_table_7af0e0[128 + index];
		goto are_we_done;
	}
	else if (index >= 0x100)
	{
		index >>= 4;
		control_word = dc_control_table_7af0e0[144 + index];
		goto are_we_done;
	}
	else if (index >= 0x80)
	{
		index >>= 3;
		control_word = dc_control_table_7af0e0[160 + index];
		goto are_we_done;
	}
	else if (index >= 0x40)
	{
		index >>= 2;
		control_word = dc_control_table_7af0e0[176 + index];
		goto are_we_done;
	}
	else if (index >= 0x20)
	{
		index >>= 1;
		control_word = dc_control_table_7af0e0[192 + index];
		goto are_we_done;
	}
done:
	return pos + (control_word >> 16);
}

void decompress_func1(int32_t* in, int32_t* out)
{
	int32_t b, a, c, d, i, p, s;
	
	if (!(in[1] | in[2] | in[3] | in[4] | in[6] | in[7]))
	{
		a = in[0];
		out[0] = a;
		out[9] = a;
		out[18] = a;
		out[27] = a;
		out[36] = a;
		out[45] = a;
		out[54] = a;
		out[63] = a;
		return;
	}

	b = in[5] - in[3];
	c = in[1] - in[7];
	i = in[3] + in[5];
	a = in[7] + in[1];
	double xf = b;
	double xg = c;
	p = i + a;
	a -= i;

	double rxs = xg + xf;
	double rxf = xf * float_7af03c + float_7af044 * rxs;
	double rxg = xg * float_7af040 - float_7af044 * rxs;
	int32_t ra = rxf + (rxf > 0 ? 0.5f : -0.5f);
	int32_t rb = rxg + (rxg > 0 ? 0.5f : -0.5f);

	int32_t sa = a;
	int64_t rx = sa;
	rx *= norm_7af038;
	a = rx;
	d = rx >> 32;

	b = in[6];
	d += d;
	a = in[2];

	c = ra;
	i = rb;
	c += d;
	d += i;
	i += p;
	const uint32_t sc = c;
	const uint32_t sd = d;
	const uint32_t si = i;
	c = in[0];
	d = in[4];
	s = b + a;
	a -= b;
	b = d + c;
	c -= d;

	sa = a;
	rx = sa;
	rx *= norm_7af038;
	a = rx;
	d = rx >> 32;

	d += d;
	out[18] = (c - d) + sc;
	out[45] = (c - d) - sc;
	out[27] = (b - (s + d)) + ra;
	out[36] = (b - (s + d)) - ra;
	out[0] = (s + d) + b + si;
	out[9] = sd + d + c;
	out[54] = d + c - sd;
	out[63] = (s + d) + b - si;
}

void decompress_func2(int32_t* in, int32_t* out)
{
	int32_t b, a, c, d, i, p, s;
	
	b = in[5] - in[3];
	c = in[1] - in[7];
	i = in[3] + in[5];
	a = in[7] + in[1];
	double xf = b;
	double xg = c;
	p = i + a;
	a -= i;

	double rxs = xg + xf;
	double rxf = xf * float_7af03c + float_7af044 * rxs;
	double rxg = xg * float_7af040 - float_7af044 * rxs;
	int32_t ra = rxf + (rxf > 0 ? 0.5f : -0.5f);
	int32_t rb = rxg + (rxg > 0 ? 0.5f : -0.5f);

	int32_t sa = a;
	int64_t rx = sa;
	rx *= norm_7af038;
	a = rx;
	d = rx >> 32;

	b = in[6];
	d += d;
	a = in[2];

	c = ra;
	i = rb;
	c += d;
	d += i;
	i += p;
	const uint32_t sc = c;
	const uint32_t sd = d;
	const uint32_t si = i;
	c = in[0];
	d = in[4];
	s = b + a;
	a -= b;
	b = d + c;
	c -= d;

	sa = a;
	rx = sa;
	rx *= norm_7af038;
	a = rx;
	d = rx >> 32;

	d += d;
	p = sc;
	s += d;
	a = d + c;
	c -= d;
	d = s + b;
	b -= s;
	s = c + p;
	c -= p;
	p = ra;
	out[2] = s;
	s = sd;
	out[5] = c;
	c = b + p;
	b -= p;
	p = si;
	out[3] = c;
	out[4] = b;
	b = s + a;
	a -= s;
	c = d + p;
	d -= p;
	out[0] = c;
	out[1] = b;
	out[6] = a;
	out[7] = d;
}

int clamp(int n, int min, int max)
{
	if (n < min)
		return min;
	if (n > max)
		return max;
	return n;
}

void decompress()
{
	uint32_t bs_pos = bs_index;
 
	// red
	int32_t value = 0;
	uint8_t jt_index = bs_read(bs_pos, 8);

	uint8_t jt_value = jump_table_7af4e0[jt_index];
	bs_pos += jt_value & 0xf;
	jt_value >>= 4;
	if (jt_value)
	{
		// value is signed
		value = bs_read(bs_pos, jt_value);
		if ((value & (1 << (jt_value - 1))) == 0)
			value -= (1 << jt_value) - 1;

		bs_pos += jt_value;
	}

	bs_red += value;
	uint8_t blanket_fill = bs_read(bs_pos, 2);
	if (blanket_fill == 2)
	{
		bs_pos += 2;
		for (int j = 0; j < 8; j++)
			for (int i = 0; i < 8; i++)
				decompress4_chunk[j * 64 + i] = bs_red << 16;
		bs_index = bs_pos;
	}
	else
	{
		bs_index = prepare_decompress(bs_red, bs_pos);
		for (int i = 0; i < 8; i++)
			decompress_func1(&decompress2_chunk[i * 8], &decompress3_chunk[i]);
		for (int i = 0; i < 8; i++)
			decompress_func2(&decompress3_chunk[i * 9], &decompress4_chunk[i * 64]);
	}

	bs_pos = bs_index;

	// green
	value = 0;
	jt_index = bs_read(bs_pos, 8);

	jt_value = jump_table_7af4e0[jt_index];
	bs_pos += jt_value & 0xf;
	jt_value >>= 4;
	if (jt_value)
	{
		// value is signed
		value = bs_read(bs_pos, jt_value);
		if ((value & (1 << (jt_value - 1))) == 0)
			value -= (1 << jt_value) - 1;

		bs_pos += jt_value;
	}

	bs_green += value;
	blanket_fill = bs_read(bs_pos, 2);
	if (blanket_fill == 2)
	{
		bs_pos += 2;
		for (int j = 0; j < 8; j++)
			for (int i = 0; i < 8; i++)
				decompress4_chunk[j * 64 + i + 9] = bs_green << 16;
		bs_index = bs_pos;
	}
	else
	{
		bs_index = prepare_decompress(bs_green, bs_pos);
		for (int i = 0; i < 8; i++)
			decompress_func1(&decompress2_chunk[i * 8], &decompress3_chunk[i]);
		for (int i = 0; i < 8; i++)
			decompress_func2(&decompress3_chunk[i * 9], &decompress4_chunk[i * 64 + 9]);
	}

	bs_pos = bs_index;

	// blue
	value = 0;
	jt_index = bs_read(bs_pos, 8);

	jt_value = jump_table_7af4e0[jt_index];
	bs_pos += jt_value & 0xf;
	jt_value >>= 4;
	if (jt_value)
	{
		// value is signed
		value = bs_read(bs_pos, jt_value);
		if ((value & (1 << (jt_value - 1))) == 0)
			value -= (1 << jt_value) - 1;

		bs_pos += jt_value;
	}

	bs_blue += value;
	blanket_fill = bs_read(bs_pos, 2);
	if (blanket_fill == 2)
	{
		bs_pos += 2;
		for (int j = 0; j < 8; j++)
			for (int i = 0; i < 8; i++)
				decompress4_chunk[j * 64 + i + 18] = bs_blue << 16;
		bs_index = bs_pos;
	}
	else
	{
		bs_index = prepare_decompress(bs_blue, bs_pos);
		for (int i = 0; i < 8; i++)
			decompress_func1(&decompress2_chunk[i * 8], &decompress3_chunk[i]);
		for (int i = 0; i < 8; i++)
			decompress_func2(&decompress3_chunk[i * 9], &decompress4_chunk[i * 64 + 18]);
	}

	bs_pos = bs_index;

	// alpha
	if (!alpha_flag)
		return;
	value = 0;
	jt_index = bs_read(bs_pos, 8);

	jt_value = jump_table_7af4e0[jt_index];
	bs_pos += jt_value & 0xf;
	jt_value >>= 4;
	if (jt_value)
	{
		// value is signed
		value = bs_read(bs_pos, jt_value);
		if ((value & (1 << (jt_value - 1))) == 0)
			value -= (1 << jt_value) - 1;

		bs_pos += jt_value;
	}

	bs_alpha += value;
	blanket_fill = bs_read(bs_pos, 2);
	if (blanket_fill == 2)
	{
		bs_pos += 2;
		for (int j = 0; j < 8; j++)
			for (int i = 0; i < 8; i++)
				decompress4_chunk[j * 64 + i + 27] = bs_alpha << 16;
		bs_index = bs_pos;
	}
	else
	{
		bs_index = prepare_decompress(bs_alpha, bs_pos);
		for (int i = 0; i < 8; i++)
			decompress_func1(&decompress2_chunk[i * 8], &decompress3_chunk[i]);
		for (int i = 0; i < 8; i++)
			decompress_func2(&decompress3_chunk[i * 9],
			                 &decompress4_chunk[i * 64 + 27]);
	}
}

void initialize_dd(void* buf)
{
	bs = (uint32_t*)buf;
	bs_index = 0;
	bs_red = 0;
	bs_blue = 0;
	bs_green = 0;
	bs_alpha = 0;
}

void decompress_block(uint8_t* out, uint16_t stride)
{
	int32_t* inp;
	uint32_t xr, xg, xb;
	int32_t ir, ig, ib;

	decompress();

	inp = (int32_t*)decompress4_chunk;
	for (int j = 0; j < 8; j++)
	{
		for (int i = 0; i < 8; i++)
		{
			uint32_t value;
			float r = inp[i + 0];
			float g = inp[i + 18];
			float b = inp[i + 9];
			int32_t a = inp[i + 27];
			double d;
			d = float_7af014 * (g - float_7af004) + float_7af008 * (r - float_7af000) + double_7af048;
			xr = d + (d > 0 ? 0.5f : -0.5f);
			ir = xr;
			d = float_7af018 * (b - float_7af004) + float_7af008 * (r - float_7af000) + double_7af048;
			xg = d + (d > 0 ? 0.5f : -0.5f);
			ig = xg;
			d = float_7af010 * (b - float_7af004) + float_7af00c * (g - float_7af004) + float_7af008 * (r - float_7af000) + double_7af048;
			xb = d + (d > 0 ? 0.5f : -0.5f);
			ib = xb;

			value = clamp(ir >> 16, 0, 255);
			value |= clamp(ig >> 16, 0, 255) << 16;
			value |= clamp(ib >> 16, 0, 255) << 8;
			if (alpha_flag)
				value |= clamp(a >> 16, 0, 255) << 24;
			else
				value |= 0xff000000;
			memcpy(&out[i * 4], &value, sizeof(value));
		}
		out += stride;
		inp += 64;
	}
}

// must be called prior to calling dd_texture
void dd_init()
{
	int32_t d, a;

	for (int i = 0; i < 64; i++)
	{
		d = (magic_input_table_6c10c0[i] & 0xfffe0000) >> 3;
		a = (magic_input_table_6c10c0[i] & 0x0001ffff) << 3;

		magic_output_table[i] = d + a;
	}
}

void dd_texture(uint32_t* buf, uint8_t* out, uint32_t stride, uint16_t width, uint16_t height)
{
	uint8_t* outp = out;

	initialize_dd(&buf[1]);
	uint8_t flag = (uint8_t)buf[0];
	alpha_flag = flag >> 7;

	for (uint16_t y = 0; y < height; y += 8)
		for (uint16_t x = 0; x < width; x += 8)
			decompress_block(&outp[y * stride + x * 4], stride);
}