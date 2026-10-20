#include <assert.h>
#include <float.h>
#include <fenv.h>
#include <math.h>
#include <stdlib.h>
#include "/tmp/encoded-format-specialization-2026-10-20/f16-only/before.c"

static double reference_weight(uint16_t bits, int f16) {
    if (!f16) {
        uint32_t wide = (uint32_t)bits << 16;
        float value;
        memcpy(&value, &wide, sizeof value);
        return value;
    }
    int exponent = (bits >> 10) & 31;
    double fraction = bits & 1023;
    double value = !exponent ? ldexp(fraction, -24) : exponent == 31
        ? (fraction ? NAN : INFINITY) : ldexp(1024 + fraction, exponent - 25);
    return bits & 32768 ? -value : value;
}

static void all_encodings(int f16) {
    uint16_t *weights = malloc(65536 * sizeof *weights);
    float *out = malloc(16384 * sizeof *out);
    float x[4] = {0.25f, 0.25f, 0.25f, 0.25f};
    assert(weights && out);
    for (unsigned i = 0; i < 65536; ++i) weights[i] = (uint16_t)i;
    assert(!ts_encoded_matmul(f16, 1, 16384, 4, weights, 4, x, 4, out, 16384));
    for (unsigned j = 0; j < 16384; ++j) {
        double expected = 0;
        for (unsigned e = 0; e < 4; ++e) expected += reference_weight(weights[j * 4 + e], f16) * 0.25;
        if (isnan(expected)) assert(isnan(out[j]));
        else if (isinf(expected) || fabs(expected) > FLT_MAX)
            assert(isinf(out[j]) && (signbit(out[j]) != 0) == (signbit(expected) != 0));
        else assert(fabs(out[j] - expected) <= 4 * FLT_EPSILON * fabs(expected));
    }
    free(out);
    free(weights);
}

static void shapes(int f16) {
    uint16_t weights[7 * 73];
    float x[9 * 71], out[9 * 11];
    for (unsigned i = 0; i < sizeof weights / sizeof *weights; ++i)
        weights[i] = f16 ? (uint16_t)(0x3000 + i % 2048) : (uint16_t)(0x3c00 + i % 512);
    for (unsigned i = 0; i < sizeof x / sizeof *x; ++i) x[i] = (float)((int)(i % 17) - 8) / 8;
    for (int64_t k = 0; k < 68; ++k) {
        for (unsigned i = 0; i < sizeof out / sizeof *out; ++i) out[i] = -7;
        assert(!ts_encoded_matmul(f16, 9, 7, k, weights, 73, x, 71, out, 11));
        for (int i = 0; i < 9; ++i) {
            for (int j = 0; j < 7; ++j) {
                double expected = 0, scale = 0;
                for (int e = 0; e < k; ++e) {
                    double term = x[i * 71 + e] * reference_weight(weights[j * 73 + e], f16);
                    expected += term;
                    scale += fabs(term);
                }
                assert(fabs(out[i * 11 + j] - expected) <= 8 * FLT_EPSILON * scale);
            }
            for (int j = 7; j < 11; ++j) assert(out[i * 11 + j] == -7);
        }
    }
}

static void single_row_shapes(int f16) {
    uint16_t weights[35 * 73 + 3];
    float x[73], out[40];
    for (unsigned i = 0; i < sizeof weights / sizeof *weights; ++i)
        weights[i] = f16 ? (uint16_t)(0x3000 + i % 2048) : (uint16_t)(0x3c00 + i % 512);
    for (unsigned i = 0; i < sizeof x / sizeof *x; ++i) x[i] = (float)((int)(i % 17) - 8) / 8;
    for (int64_t m = 0; m <= 35; ++m) {
        for (int64_t k = 0; k <= 69; ++k) {
            for (unsigned i = 0; i < sizeof out / sizeof *out; ++i) out[i] = -7;
            assert(!ts_encoded_matmul(f16, 1, m, k, weights + 3, 73, x + 2, 71, out + 1, m + 3));
            for (int j = 0; j < m; ++j) {
                double expected = 0, scale = 0;
                for (int e = 0; e < k; ++e) {
                    double term = x[2 + e] * reference_weight(weights[3 + j * 73 + e], f16);
                    expected += term;
                    scale += fabs(term);
                }
                assert(fabs(out[j + 1] - expected) <= 8 * FLT_EPSILON * scale);
            }
            assert(out[0] == -7);
            for (int j = (int)m + 1; j < 40; ++j) assert(out[j] == -7);
        }
    }
}

static void exceptional_tiles(int f16) {
    uint16_t weights[4];
    float x[8], out[2];
    for (int i = 0; i < 4; ++i) weights[i] = f16 ? 0x7c00 : 0x7f80;
    for (int i = 0; i < 8; ++i) x[i] = 1;
    feclearexcept(FE_ALL_EXCEPT);
    assert(!ts_encoded_matmul(f16, 2, 1, 4, weights, 4, x, 4, out, 1));
    assert(isinf(out[0]) && isinf(out[1]));
    assert(!fetestexcept(FE_INVALID));
    for (int i = 0; i < 4; ++i) weights[i] = f16 ? 0x3c00 : 0x3f80;
    for (int i = 0; i < 8; ++i) x[i] = INFINITY;
    feclearexcept(FE_ALL_EXCEPT);
    assert(!ts_encoded_matmul(f16, 1, 1, 4, weights, 4, x, 4, out, 1));
    assert(isinf(out[0]));
    assert(!fetestexcept(FE_INVALID));
}

int main(void) {
    for (int f16 = 0; f16 <= 1; ++f16) {
        all_encodings(f16);
        shapes(f16);
        single_row_shapes(f16);
        exceptional_tiles(f16);
    }
#if defined(__aarch64__) && !defined(TS_SCALAR)
    uint64_t fpcr;
    __asm__ volatile("mrs %0, fpcr" : "=r"(fpcr));
    uint64_t flush_half = fpcr | (1ull << 19);
    __asm__ volatile("msr fpcr, %0" :: "r"(flush_half) : "memory");
    all_encodings(1);
    __asm__ volatile("msr fpcr, %0" :: "r"(fpcr) : "memory");
#endif
    float out = -7;
    assert(ts_encoded_matmul(1, INT64_MAX, 1, 1, NULL, 1, NULL, 1, &out, 1));
    assert(ts_encoded_matmul(1, 1, 1, 8, NULL, 7, NULL, 8, &out, 1));
    assert(ts_encoded_matmul(1, 1, 1, 1, NULL, 1, NULL, 1, &out, 1));
    assert(out == -7);
    assert(!ts_encoded_matmul(1, 0, 1, 1, NULL, 1, NULL, 1, NULL, 1));
    assert(!ts_encoded_matmul(1, 1, 1, 0, NULL, 0, NULL, 0, &out, 1));
    assert(out == 0);
    return 0;
}
