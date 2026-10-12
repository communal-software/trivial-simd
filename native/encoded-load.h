#ifndef TS_ENCODED_LOAD_H
#define TS_ENCODED_LOAD_H
#include <stdint.h>
#include <string.h>

static float ts_encoded_bits_float(uint32_t bits) {
    float value;
    memcpy(&value, &bits, sizeof value);
    return value;
}

static float ts_bf16_to_f32_scalar(uint16_t h) {
    uint32_t b = (uint32_t)h << 16;
    return ts_encoded_bits_float((b & 0x7fffffffu) > 0x7f800000u ? b | 0x400000u : b);
}

static float ts_f16_to_f32_scalar(uint16_t h) {
    uint32_t sign = (uint32_t)(h & 0x8000u) << 16, mantissa = h & 0x3ffu;
    int exponent = (h >> 10) & 0x1f;
    if (exponent == 0x1f)
        return ts_encoded_bits_float(sign | 0x7f800000u | (mantissa << 13) | (mantissa ? 0x400000u : 0));
    if (exponent == 0) {
        if (mantissa == 0) return ts_encoded_bits_float(sign);
        for (exponent = 1; !(mantissa & 0x400u); --exponent) mantissa <<= 1;
        mantissa &= 0x3ffu;
    }
    return ts_encoded_bits_float(sign | ((uint32_t)(exponent + 112) << 23) | (mantissa << 13));
}

#if !defined(TS_SCALAR) && (defined(__SSE2__) || defined(_M_X64))
#include <emmintrin.h>
/* B holds one bf16 in the high half of each lane. */
static __m128 ts_bf16_to_f32_sse2(__m128i b) {
    __m128i nan = _mm_cmpgt_epi32(_mm_and_si128(b, _mm_set1_epi32(0x7fffffff)),
                                  _mm_set1_epi32(0x7f800000));
    return _mm_castsi128_ps(_mm_or_si128(b, _mm_and_si128(nan, _mm_set1_epi32(0x400000))));
}

/* Exact subtraction widens f16 subnormals without depending on DAZ or FTZ. */
static __m128 ts_f16_to_f32_sse2(__m128i h) {
    const __m128i exponent_mask = _mm_set1_epi32(0x7c00 << 13);
    const __m128i magic = _mm_set1_epi32(113 << 23);
    __m128i magnitude = _mm_slli_epi32(_mm_and_si128(h, _mm_set1_epi32(0x7fff)), 13);
    __m128i exponent = _mm_and_si128(magnitude, exponent_mask);
    __m128i special = _mm_cmpeq_epi32(exponent, exponent_mask);
    __m128i nan = _mm_cmpgt_epi32(magnitude, exponent_mask);
    __m128i subnormal = _mm_cmpeq_epi32(exponent, _mm_setzero_si128());
    __m128i bits = _mm_add_epi32(magnitude, _mm_set1_epi32(112 << 23));
    bits = _mm_add_epi32(bits, _mm_and_si128(special, _mm_set1_epi32(112 << 23)));
    bits = _mm_or_si128(bits, _mm_and_si128(nan, _mm_set1_epi32(0x400000)));
    __m128i scaled = _mm_or_si128(_mm_and_si128(subnormal, _mm_add_epi32(magnitude, magic)),
                                  _mm_andnot_si128(subnormal, magic));
    __m128i small = _mm_castps_si128(_mm_sub_ps(_mm_castsi128_ps(scaled),
                                                _mm_castsi128_ps(magic)));
    /* Equal operands subtract to -0 under downward rounding. */
    small = _mm_and_si128(small, _mm_set1_epi32(0x7fffffff));
    bits = _mm_or_si128(_mm_and_si128(subnormal, small), _mm_andnot_si128(subnormal, bits));
    __m128i sign = _mm_slli_epi32(_mm_and_si128(h, _mm_set1_epi32(0x8000)), 16);
    return _mm_castsi128_ps(_mm_or_si128(bits, sign));
}
#endif
#endif
