/*
 *  Copyright (C) 2019  Claire Wolf <claire@symbioticeda.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

#ifdef __CPROVER__
#define RVINTRIN_NOBUILTINS
#endif

#define RVINTRIN_EMULATE
#include "rvintrin.h"
#include "common.h"

#define ASSERT_RV32_1(_name) assert(_rv32_ ## _name(a) == int32_t(rv32b::_name(a)));
#define ASSERT_RV32_2(_name) assert(_rv32_ ## _name(a, b) == int32_t(rv32b::_name(a, b)));

#define ASSERT_RV64_1(_name) assert(_rv64_ ## _name(a) == int64_t(rv64b::_name(a)));
#define ASSERT_RV64_2(_name) assert(_rv64_ ## _name(a, b) == int64_t(rv64b::_name(a, b)));

#define ASSERT_RV_1(_name) assert(_rv_ ## _name(a) == long(rv64b::_name(a)));
#define ASSERT_RV_2(_name) assert(_rv_ ## _name(a, b) == long(rv64b::_name(a, b)));

extern "C" void check_rv32_basic(int32_t a, int32_t b)
{
	ASSERT_RV32_1(clz);
	ASSERT_RV32_1(ctz);
	ASSERT_RV32_1(pcnt);
	ASSERT_RV32_2(pack);
	ASSERT_RV32_2(bfp);
	ASSERT_RV32_2(min);
	ASSERT_RV32_2(minu);
	ASSERT_RV32_2(max);
	ASSERT_RV32_2(maxu);

	ASSERT_RV32_1(rev);
	ASSERT_RV32_1(rev_b);
	ASSERT_RV32_1(rev8);
	ASSERT_RV32_1(orc_p);
}

extern "C" void check_rv64_basic(int64_t a, int64_t b)
{
	ASSERT_RV64_1(clz);
	ASSERT_RV64_1(ctz);
	ASSERT_RV64_1(pcnt);
	ASSERT_RV64_2(pack);
	ASSERT_RV64_2(bfp);
	ASSERT_RV64_2(min);
	ASSERT_RV64_2(minu);
	ASSERT_RV64_2(max);
	ASSERT_RV64_2(maxu);

	ASSERT_RV64_1(rev);
	ASSERT_RV64_1(rev_b);
	ASSERT_RV64_1(rev8);
	ASSERT_RV64_1(orc_p);
	ASSERT_RV64_1(zip);
	ASSERT_RV64_1(zip8);
	ASSERT_RV64_1(unzip4);
}

extern "C" void check_rv32_single(int32_t a, int32_t b)
{
	ASSERT_RV32_2(sbset);
	ASSERT_RV32_2(sbclr);
	ASSERT_RV32_2(sbinv);
	ASSERT_RV32_2(sbext);
}

extern "C" void check_rv64_single(int64_t a, int64_t b)
{
	ASSERT_RV64_2(sbset);
	ASSERT_RV64_2(sbclr);
	ASSERT_RV64_2(sbinv);
	ASSERT_RV64_2(sbext);
}

extern "C" void check_rv32_shift(int32_t a, int32_t b)
{
	ASSERT_RV32_2(sll);
	ASSERT_RV32_2(srl);
	ASSERT_RV32_2(sra);
	ASSERT_RV32_2(slo);
	ASSERT_RV32_2(sro);
	ASSERT_RV32_2(rol);
	ASSERT_RV32_2(ror);
	ASSERT_RV32_2(grev);
	ASSERT_RV32_2(gorc);
	ASSERT_RV32_2(shfl);
	ASSERT_RV32_2(unshfl);
}

extern "C" void check_rv64_shift(int64_t a, int64_t b)
{
	ASSERT_RV64_2(sll);
	ASSERT_RV64_2(srl);
	ASSERT_RV64_2(sra);
	ASSERT_RV64_2(slo);
	ASSERT_RV64_2(sro);
	ASSERT_RV64_2(rol);
	ASSERT_RV64_2(ror);
	ASSERT_RV64_2(grev);
	ASSERT_RV64_2(gorc);
	ASSERT_RV64_2(shfl);
	ASSERT_RV64_2(unshfl);
}

extern "C" void check_rv32_funnel(int64_t a, int64_t b, int64_t c)
{
	assert(_rv32_fsl(a, b, c) == int32_t(rv32b::fsl(a, c, b)));
	assert(_rv32_fsr(a, b, c) == int32_t(rv32b::fsr(a, c, b)));
}

extern "C" void check_rv64_funnel(int64_t a, int64_t b, int64_t c)
{
	assert(_rv64_fsl(a, b, c) == int64_t(rv64b::fsl(a, c, b)));
	assert(_rv64_fsr(a, b, c) == int64_t(rv64b::fsr(a, c, b)));
}

extern "C" void check_rv_ternary(long a, long b, long c)
{
	assert(_rv_cmov(a, b, c) == int64_t(rv64b::cmov(b, a, c)));
	assert(_rv_cmix(a, b, c) == int64_t(rv64b::cmix(b, a, c)));
}

extern "C" void check_rv64_bitmat(int64_t a, int64_t b)
{
	ASSERT_RV64_2(bmatxor);
	ASSERT_RV64_2(bmator);
	ASSERT_RV64_1(bmatflip);
}

int main()
{
	printf("testing rv32 basics..\n");
	for (int i = 0; i < 100000; i++) {
		int32_t a = xorshift32();
		ASSERT_RV32_1(clz);
		ASSERT_RV32_1(ctz);
		ASSERT_RV32_1(pcnt);
	}

	printf("testing rv64 basics..\n");
	for (int i = 0; i < 100000; i++) {
		int64_t a = xorshift64();
		ASSERT_RV64_1(clz);
		ASSERT_RV64_1(ctz);
		ASSERT_RV64_1(pcnt);
	}

	printf("testing rv32 bext/bdep..\n");
	for (int i = 0; i < 100000; i++) {
		int32_t a = xorshift32();
		int32_t b = xorshift32();
		ASSERT_RV32_2(bext);
		ASSERT_RV32_2(bdep);
	}

	printf("testing rv64 bext/bdep..\n");
	for (int i = 0; i < 100000; i++) {
		int64_t a = xorshift64();
		int64_t b = xorshift64();
		ASSERT_RV64_2(bext);
		ASSERT_RV64_2(bdep);
	}

	printf("testing rv32 clmul[h[x]]..\n");
	for (int i = 0; i < 100000; i++) {
		int32_t a = xorshift32();
		int32_t b = xorshift32();
		ASSERT_RV32_2(clmul);
		ASSERT_RV32_2(clmulh);
		ASSERT_RV32_2(clmulr);
	}

	printf("testing rv64 clmul[h[x]]..\n");
	for (int i = 0; i < 100000; i++) {
		int64_t a = xorshift64();
		int64_t b = xorshift64();
		ASSERT_RV64_2(clmul);
		ASSERT_RV64_2(clmulh);
		ASSERT_RV64_2(clmulr);
	}

	printf("testing crc32/crc32c..\n");
	for (int i = 0; i < 100000; i++) {
		int64_t a = xorshift64();
		ASSERT_RV_1(crc32_b);
		ASSERT_RV_1(crc32_h);
		ASSERT_RV_1(crc32_w);
		ASSERT_RV_1(crc32_d);
		ASSERT_RV_1(crc32c_b);
		ASSERT_RV_1(crc32c_h);
		ASSERT_RV_1(crc32c_w);
		ASSERT_RV_1(crc32c_d);
	}

	return 0;
}
