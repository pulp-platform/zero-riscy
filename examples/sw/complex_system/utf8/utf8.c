#include "rvintrin.h"
#include <assert.h>
#include <string.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include "complex_system_common.h"

//static inline long rdinstret() { int32_t rd; asm volatile ("csrr %0" : "=r"(rd) : : x0 ); return rd; }

#define NUM 1234

uint32_t din[NUM];

uint8_t dout_utf8_encode_reference[8*NUM];
uint8_t dout_utf8_encode_bitmanip[8*NUM];

long len_utf8_encode_reference;
long len_utf8_encode_bitmanip;

uint32_t dout_utf8_decode_reference[NUM];
uint32_t dout_utf8_decode_bitmanip[NUM];

long len_utf8_decode_reference;
long len_utf8_decode_bitmanip;

long utf8_encode_reference(const uint32_t *in, uint8_t *out, long len)
{
	long k = 0;

	for (int i = 0; i < len; i++)
	{
		uint32_t v = in[i];

		if (v <= 0x7f) {
			out[k++] = v;
			continue;
		}

		if (v <= 0x7ff) {
			out[k++] = 0xc0 | ((v >> 6) & 0x1f);
			out[k++] = 0x80 | ((v >> 0) & 0x3f);
			continue;
		}

		if (v <= 0xffff) {
			out[k++] = 0xe0 | ((v >> 12) & 0x0f);
			out[k++] = 0x80 | ((v >>  6) & 0x3f);
			out[k++] = 0x80 | ((v >>  0) & 0x3f);
			continue;
		}

		if (v <= 0x10ffff) {
			out[k++] = 0xf0 | ((v >> 18) & 0x07);
			out[k++] = 0x80 | ((v >> 12) & 0x3f);
			out[k++] = 0x80 | ((v >>  6) & 0x3f);
			out[k++] = 0x80 | ((v >>  0) & 0x3f);
			continue;
		}

		//assert(0);
	}

	return k;
}

// branch-free UTF-8 encoder using bitmanip instructions and misaligned store
long utf8_encode_bitmanip(const uint32_t *in, uint8_t *out, long len)
{
	uint32_t *p = (void*)out;

	static const uint8_t lz_bytes[33] = {
		0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 4, 4, 4, 4, 4,
		3, 3, 3, 3, 3, 2, 2, 2,
		2, 1, 1, 1, 1, 1, 1, 1, 1
	};

	static const uint32_t ctrlbits[5] = {
		0x00000000,
		0x00000000,
		0x000080c0,
		0x008080e0,
		0x808080f0
	};

	for (int i = 0; i < len; i++) {
		uint32_t v = in[i];
		int bytes = lz_bytes[_rv32_clz(v)];
		v = _rv32_bdep(v, 0x3f3f3f3f | (bytes-2));
		v = _rv32_rev8(v) >> (32 - (bytes << 3));
		*p = v | ctrlbits[bytes];
		p = (void*)p + bytes;
	}

	return (void*)p - (void*)out;
}

long utf8_decode_reference(const uint8_t *in, uint32_t *out, long len)
{
	long k = 0;

	for (int i = 0; i < len; i++)
	{
		uint64_t v = in[i];

		if ((v & 0x80) == 0x00) {
			out[k++] = v;
			continue;
		}

		if ((v & 0xe0) == 0xc0) {
			v  = (v       & 0x1f) << 6;
			v |= (in[++i] & 0x3f) << 0;
			out[k++] = v;
			continue;
		}

		if ((v & 0xf0) == 0xe0) {
			v  = (v       & 0x0f) << 12;
			v |= (in[++i] & 0x3f) << 6;
			v |= (in[++i] & 0x3f) << 0;
			out[k++] = v;
			continue;
		}

		v  = (v       & 0x07) << 18;
		v |= (in[++i] & 0x3f) << 12;
		v |= (in[++i] & 0x3f) << 6;
		v |= (in[++i] & 0x3f) << 0;
		out[k++] = v;
	}

	return k;
}

// branch-free UTF-8 decoder using bitmanip instructions and misaligned load
long utf8_decode_bitmanip(const uint8_t *in, uint32_t *out, long len)
{
	uint32_t *p = out;
	uint32_t mask = 0x3f3f3f3f;

	for (int i = 0; i < len;) {
		uint32_t v = *(uint32_t*)(in+i);
		int bytes = _rv32_max(1, _rv32_clz(~(v << 24)));
		//if (__builtin_expect(bytes > 4, 0)) abort();
		v = _rv32_rev8(v) << bytes;
		v = v >> ((bytes-8*bytes) & 31);
		v = _rv32_bext(v, mask | (bytes-2));
		*(p++) = v;
		i += bytes;
	}

	return p - out;
}

#define TEST(_name, _iter, _code)                                 \
  do {                                                            \
    puts("testing ");                                             \
    puts(#_name);                                                 \
    puts("\n");                                                 \
    _code                                                         \
  } while (0)
    //puthex(icnt);        				          \
    //long icnt = rdinstret();                                      \
    //icnt = rdinstret() - icnt;                                    \
    //p += sprintf(p, "%-25s %5ld instructions  (%2.1f inst / word) \n", #_name, icnt, (float)icnt / _iter);

uint64_t xs64()
{
	static uint64_t x = 123456789;
	x ^= x << 13;
	x ^= x >> 7;
	x ^= x << 17;
	return x;
}

int main()
{
	//char buffer[16*1024];

	long expected_len_utf8_encode = 0;

	for (int i = 0; i < NUM; i++)
	{
		uint32_t v;

		do {
			v = xs64();
			v >>= xs64() & 31;
		} while (v > 0x10ffff);

		if (v <= 0x7f)
			expected_len_utf8_encode += 1;
		else if (v <= 0x7ff)
			expected_len_utf8_encode += 2;
		else if (v <= 0xffff)
			expected_len_utf8_encode += 3;
		else
			expected_len_utf8_encode += 4;

		// printf("U+%06x%c", v, i % 8 == 7 || i == NUM-1 ? '\n' : ' ');
		din[i] = v;
	}

	TEST(utf8_encode_reference, NUM, {
		len_utf8_encode_reference = utf8_encode_reference(din, dout_utf8_encode_reference, NUM);
	});

	//assert(len_utf8_encode_reference == expected_len_utf8_encode);

	TEST(utf8_encode_bitmanip, NUM, {
		len_utf8_encode_bitmanip = utf8_encode_bitmanip(din, dout_utf8_encode_bitmanip, NUM);
	});

	//p += sprintf(p, "\n");

#if 0
	{
		int cursor = 0;

		for (int i = 0; i < NUM; i++)
		{
			uint32_t v = din[i];

			if (v <= 0x7f) {
				printf("U+%06x | %02x          | %02x\n", v,
						dout_utf8_encode_reference[cursor], dout_utf8_encode_bitmanip[cursor]);
				assert(dout_utf8_encode_reference[cursor] == dout_utf8_encode_bitmanip[cursor]);
				cursor += 1;
				continue;
			}

			if (v <= 0x7ff) {
				printf("U+%06x | %02x %02x       | %02x %02x\n", v,
						dout_utf8_encode_reference[cursor], dout_utf8_encode_reference[cursor+1],
						dout_utf8_encode_bitmanip[cursor], dout_utf8_encode_bitmanip[cursor+1]);
				assert(dout_utf8_encode_reference[cursor] == dout_utf8_encode_bitmanip[cursor]);
				assert(dout_utf8_encode_reference[cursor+1] == dout_utf8_encode_bitmanip[cursor+1]);
				cursor += 2;
				continue;
			}

			if (v <= 0xffff) {
				printf("U+%06x | %02x %02x %02x    | %02x %02x %02x\n", v,
						dout_utf8_encode_reference[cursor], dout_utf8_encode_reference[cursor+1], dout_utf8_encode_reference[cursor+2],
						dout_utf8_encode_bitmanip[cursor], dout_utf8_encode_bitmanip[cursor+1], dout_utf8_encode_bitmanip[cursor+2]);
				assert(dout_utf8_encode_reference[cursor] == dout_utf8_encode_bitmanip[cursor]);
				assert(dout_utf8_encode_reference[cursor+1] == dout_utf8_encode_bitmanip[cursor+1]);
				assert(dout_utf8_encode_reference[cursor+2] == dout_utf8_encode_bitmanip[cursor+2]);
				cursor += 3;
				continue;
			}

			printf("U+%06x | %02x %02x %02x %02x | %02x %02x %02x %02x\n", v,
					dout_utf8_encode_reference[cursor], dout_utf8_encode_reference[cursor+1],
					dout_utf8_encode_reference[cursor+2], dout_utf8_encode_reference[cursor+3],
					dout_utf8_encode_bitmanip[cursor], dout_utf8_encode_bitmanip[cursor+1],
					dout_utf8_encode_bitmanip[cursor+2], dout_utf8_encode_bitmanip[cursor+3]);
			assert(dout_utf8_encode_reference[cursor] == dout_utf8_encode_bitmanip[cursor]);
			assert(dout_utf8_encode_reference[cursor+1] == dout_utf8_encode_bitmanip[cursor+1]);
			assert(dout_utf8_encode_reference[cursor+2] == dout_utf8_encode_bitmanip[cursor+2]);
			assert(dout_utf8_encode_reference[cursor+3] == dout_utf8_encode_bitmanip[cursor+3]);
			cursor += 4;
		}
	}
#endif

	//assert(len_utf8_encode_reference == len_utf8_encode_bitmanip);
	//assert(!memcmp(dout_utf8_encode_reference, dout_utf8_encode_bitmanip, sizeof(len_utf8_encode_bitmanip)));

	TEST(utf8_decode_reference, NUM, {
		len_utf8_decode_reference = utf8_decode_reference(dout_utf8_encode_reference,
				dout_utf8_decode_reference, len_utf8_encode_reference);
	});

	//assert(len_utf8_decode_reference == NUM);
	//assert(!memcmp(din, dout_utf8_decode_reference, sizeof(din)));

	TEST(utf8_decode_bitmanip, NUM, {
		len_utf8_decode_bitmanip = utf8_decode_bitmanip(dout_utf8_encode_bitmanip,
				dout_utf8_decode_bitmanip, len_utf8_encode_bitmanip);
	});

#if 0
	{
		int cursor = 0;

		for (int i = 0; i < NUM; i++)
		{
			uint32_t v = din[i];

			if (v <= 0x7f) {
				printf("U+%06x U+%06x | %02x\n", v, dout_utf8_decode_bitmanip[i],
						dout_utf8_encode_reference[cursor]);
				assert(dout_utf8_decode_reference[i] == dout_utf8_decode_bitmanip[i]);
				cursor += 1;
				continue;
			}

			if (v <= 0x7ff) {
				printf("U+%06x U+%06x | %02x %02x\n", v, dout_utf8_decode_bitmanip[i],
						dout_utf8_encode_reference[cursor], dout_utf8_encode_reference[cursor+1]);
				assert(dout_utf8_decode_reference[i] == dout_utf8_decode_bitmanip[i]);
				cursor += 2;
				continue;
			}

			if (v <= 0xffff) {
				printf("U+%06x U+%06x | %02x %02x %02x\n", v, dout_utf8_decode_bitmanip[i],
						dout_utf8_encode_reference[cursor], dout_utf8_encode_reference[cursor+1], dout_utf8_encode_reference[cursor+2]);
				assert(dout_utf8_decode_reference[i] == dout_utf8_decode_bitmanip[i]);
				cursor += 3;
				continue;
			}

			printf("U+%06x U+%06x | %02x %02x %02x %02x\n", v, dout_utf8_decode_bitmanip[i],
					dout_utf8_encode_reference[cursor], dout_utf8_encode_reference[cursor+1],
					dout_utf8_encode_reference[cursor+2], dout_utf8_encode_reference[cursor+3]);
			assert(dout_utf8_decode_reference[i] == dout_utf8_decode_bitmanip[i]);
			cursor += 4;
		}
	}
#endif

	//assert(len_utf8_decode_reference == len_utf8_decode_bitmanip);
	//assert(!memcmp(dout_utf8_decode_reference, dout_utf8_decode_bitmanip, sizeof(din)));

	//puts("\n%s\n");
	puts("done...");

	return 0;
}
