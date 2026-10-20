#include <stddef.h>
#include "encoded-load.h"

#if !defined(TS_SCALAR) && (defined(__aarch64__) || defined(_M_ARM64))
#include <arm_neon.h>
typedef float32x4_t packed;
static packed load_x(const float *p) { return vld1q_f32(p); }
static packed zero(void) { return vdupq_n_f32(0); }
static packed add_product(packed sum, packed x, packed w) { return vfmaq_f32(sum, x, w); }
static float total(packed p) { return vaddvq_f32(p); }
static packed load_weight(const uint16_t *p, int f16) {
    uint16x4_t half = vld1_u16(p);
#if defined(__aarch64__)
    if (f16 == 2) {
        uint16x4_t nan = vcgt_u16(vand_u16(half, vdup_n_u16(0x7fff)), vdup_n_u16(0x7c00));
        half = vorr_u16(half, vand_u16(nan, vdup_n_u16(0x200)));
        return vcvt_f32_f16(vreinterpret_f16_u16(half));
    }
#endif
    uint32x4_t h = vmovl_u16(half);
    if (!f16) {
        uint32x4_t bits = vshlq_n_u32(h, 16);
        uint32x4_t nan = vcgtq_u32(vandq_u32(bits, vdupq_n_u32(0x7fffffff)), vdupq_n_u32(0x7f800000));
        return vreinterpretq_f32_u32(vorrq_u32(bits, vandq_u32(nan, vdupq_n_u32(0x400000))));
    }
    uint32x4_t magnitude = vshlq_n_u32(vandq_u32(h, vdupq_n_u32(0x7fff)), 13);
    uint32x4_t exponent = vandq_u32(magnitude, vdupq_n_u32(0x7c00 << 13));
    uint32x4_t special = vceqq_u32(exponent, vdupq_n_u32(0x7c00 << 13));
    uint32x4_t subnormal = vceqq_u32(exponent, vdupq_n_u32(0));
    uint32x4_t bits = vaddq_u32(magnitude, vdupq_n_u32(112 << 23));
    bits = vaddq_u32(bits, vandq_u32(special, vdupq_n_u32(112 << 23)));
    bits = vorrq_u32(bits, vandq_u32(vcgtq_u32(magnitude, vdupq_n_u32(0x7c00 << 13)), vdupq_n_u32(0x400000)));
    uint32x4_t magic = vdupq_n_u32(113 << 23);
    packed small = vsubq_f32(vreinterpretq_f32_u32(vbslq_u32(subnormal, vaddq_u32(magnitude, magic), magic)),
                            vreinterpretq_f32_u32(magic));
    bits = vbslq_u32(subnormal, vandq_u32(vreinterpretq_u32_f32(small), vdupq_n_u32(0x7fffffff)), bits);
    return vreinterpretq_f32_u32(vorrq_u32(bits, vshlq_n_u32(vandq_u32(h, vdupq_n_u32(0x8000)), 16)));
}
#define TS_ENCODED_PACKED
#elif !defined(TS_SCALAR) && (defined(__SSE2__) || defined(_M_X64))
typedef __m128 packed;
static packed load_x(const float *p) { return _mm_loadu_ps(p); }
static packed zero(void) { return _mm_setzero_ps(); }
static packed add_product(packed sum, packed x, packed w) { return _mm_add_ps(sum, _mm_mul_ps(x, w)); }
static float total(packed p) {
    p = _mm_add_ps(p, _mm_movehl_ps(p, p));
    return _mm_cvtss_f32(_mm_add_ss(p, _mm_shuffle_ps(p, p, 1)));
}
static packed load_weight(const uint16_t *p, int f16) {
    __m128i h = _mm_loadl_epi64((const __m128i *)p);
    return f16 ? ts_f16_to_f32_sse2(_mm_unpacklo_epi16(h, _mm_setzero_si128()))
               : ts_bf16_to_f32_sse2(_mm_unpacklo_epi16(_mm_setzero_si128(), h));
}
#define TS_ENCODED_PACKED
#endif

static int valid_span(int64_t rows, int64_t columns, int64_t stride, int64_t size) {
    if (!rows || !columns) return 1;
    int64_t limit = INT64_MAX / size;
    if ((uint64_t)limit > SIZE_MAX / (uint64_t)size) limit = (int64_t)(SIZE_MAX / (uint64_t)size);
    return columns <= limit && (!stride || rows - 1 <= (limit - columns) / stride);
}

#ifdef TS_ENCODED_PACKED
/* TODO: weight rereads cap large batches; use cache-blocked panels (#74). */
#define DEFINE_ENCODED_TILE(name, ROWS, COLS) \
static void name(int f16, int64_t n, int64_t m, int64_t k, \
                 const uint16_t *weights, int64_t ws, const float *x, int64_t xs, float *out, int64_t os) { \
    for (int64_t j0 = 0; j0 < m; j0 += COLS) { \
        int64_t columns = m - j0 < COLS ? m - j0 : COLS; \
        for (int64_t i0 = 0; i0 < n; i0 += ROWS) { \
            int64_t rows = n - i0 < ROWS ? n - i0 : ROWS; \
            packed sums[ROWS][COLS]; \
            for (int t = 0; t < ROWS; ++t) \
                for (int c = 0; c < COLS; ++c) sums[t][c] = zero(); \
            int64_t e = 0; \
            for (; e + 4 <= k; e += 4) { \
                packed w[COLS]; \
                if (rows == ROWS && columns == COLS) { \
                    for (int c = 0; c < COLS; ++c) w[c] = load_weight(weights + (j0 + c) * ws + e, f16); \
                    for (int t = 0; t < ROWS; ++t) { \
                        packed activation = load_x(x + (i0 + t) * xs + e); \
                        for (int c = 0; c < COLS; ++c) sums[t][c] = add_product(sums[t][c], activation, w[c]); \
                    } \
                } else { \
                    for (int c = 0; c < columns; ++c) w[c] = load_weight(weights + (j0 + c) * ws + e, f16); \
                    for (int t = 0; t < rows; ++t) { \
                        packed activation = load_x(x + (i0 + t) * xs + e); \
                        for (int c = 0; c < columns; ++c) sums[t][c] = add_product(sums[t][c], activation, w[c]); \
                    } \
                } \
            } \
            float tails[ROWS][COLS] = {{0}}; \
            for (; e < k; ++e) { \
                for (int c = 0; c < columns; ++c) { \
                    uint16_t bits = weights[(j0 + c) * ws + e]; \
                    float w = f16 ? ts_f16_to_f32_scalar(bits) : ts_bf16_to_f32_scalar(bits); \
                    for (int t = 0; t < rows; ++t) tails[t][c] += x[(i0 + t) * xs + e] * w; \
                } \
            } \
            for (int t = 0; t < rows; ++t) \
                for (int c = 0; c < columns; ++c) out[(i0 + t) * os + j0 + c] = total(sums[t][c]) + tails[t][c]; \
        } \
    } \
}
#if defined(__aarch64__) || defined(_M_ARM64)
DEFINE_ENCODED_TILE(encoded_tile1, 1, 8)
DEFINE_ENCODED_TILE(encoded_tile_batch, 6, 4)
#else
DEFINE_ENCODED_TILE(encoded_tile1, 1, 4)
DEFINE_ENCODED_TILE(encoded_tile_batch, 4, 2)
#endif
#endif

int ts_encoded_matmul(int f16, int64_t n, int64_t m, int64_t k,
                      const uint16_t *weights, int64_t weights_stride,
                      const float *x, int64_t x_stride, float *out, int64_t out_stride) {
    if ((f16 != 0 && f16 != 1) || n < 0 || m < 0 || k < 0 ||
        weights_stride < k || x_stride < k || out_stride < m) return 1;
    if (!valid_span(m, k, weights_stride, 2) || !valid_span(n, k, x_stride, 4) ||
        !valid_span(n, m, out_stride, 4)) return 1;
    if (!n || !m) return 0;
    if (!out || (k && (!weights || !x))) return 1;
#if defined(TS_ENCODED_PACKED) && defined(__aarch64__)
    if (f16) {
        uint64_t fpcr;
        __asm__ volatile("mrs %0, fpcr" : "=r"(fpcr));
        if (!(fpcr & ((1ull << 19) | (1ull << 26)))) f16 = 2;
    }
#endif
#ifdef TS_ENCODED_PACKED
    (n == 1 ? encoded_tile1 : encoded_tile_batch)(f16, n, m, k, weights, weights_stride, x, x_stride, out, out_stride);
#else
    for (int64_t j = 0; j < m; ++j) {
        for (int64_t i = 0; i < n; ++i) {
            float sum = 0;
            for (int64_t e = 0; e < k; ++e) {
                uint16_t bits = weights[j * weights_stride + e];
                float w = f16 ? ts_f16_to_f32_scalar(bits) : ts_bf16_to_f32_scalar(bits);
                sum += x[i * x_stride + e] * w;
            }
            out[i * out_stride + j] = sum;
        }
    }
#endif
    return 0;
}
