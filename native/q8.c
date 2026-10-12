#include <math.h>
#include <stdint.h>
#include <string.h>

#if defined(__ARM_NEON)
#include <arm_neon.h>
#endif

#define Q8_0_BLOCK_ELEMENTS 32
#define Q8_0_BLOCK_BYTES 34

static float q8_0_scale(const uint8_t *block) {
    uint16_t bits = (uint16_t)(block[0] | (uint16_t)block[1] << 8);
    unsigned exponent = (bits >> 10) & 31, fraction = bits & 1023;
    if (!exponent) return (bits & 32768 ? -1.0f : 1.0f) * ldexpf((float)fraction, -24);
    uint32_t wide = ((uint32_t)(bits & 32768) << 16) |
                    ((exponent == 31 ? 255u : exponent + 112u) << 23) | (fraction << 13);
    float scale;
    memcpy(&scale, &wide, sizeof(scale));
    return scale;
}

#if defined(__ARM_NEON)

/* Widens each weight block once per tile of ROW_TILE activation rows. */
#define DEFINE_Q8_0_NEON_MATMUL(name, ROW_TILE)                                              \
static void name(int64_t n, int64_t m, int64_t block_count, const uint8_t *blocks,          \
                 const float *x, int64_t x_stride, float *out, int64_t out_stride) {        \
    for (int64_t j = 0; j < m; ++j) {                                                        \
        const uint8_t *row = blocks + j * block_count * Q8_0_BLOCK_BYTES;                    \
        for (int64_t i0 = 0; i0 < n; i0 += ROW_TILE) {                                       \
            const int64_t tile = n - i0 < ROW_TILE ? n - i0 : ROW_TILE;                      \
            float32x4_t sum[ROW_TILE][2];                                                    \
            for (int64_t t = 0; t < ROW_TILE; ++t) sum[t][0] = sum[t][1] = vdupq_n_f32(0);   \
            for (int64_t b = 0; b < block_count; ++b) {                                      \
                const uint8_t *block = row + b * Q8_0_BLOCK_BYTES;                           \
                const float32x4_t scale = vdupq_n_f32(q8_0_scale(block));                    \
                float32x4_t w[8];                                                            \
                for (int p = 0; p < 2; ++p) {                                                \
                    int8x16_t q = vld1q_s8((const int8_t *)(block + 2 + p * 16));            \
                    int16x8_t lo = vmovl_s8(vget_low_s8(q)), hi = vmovl_s8(vget_high_s8(q)); \
                    w[p * 4 + 0] = vmulq_f32(vcvtq_f32_s32(vmovl_s16(vget_low_s16(lo))), scale);  \
                    w[p * 4 + 1] = vmulq_f32(vcvtq_f32_s32(vmovl_s16(vget_high_s16(lo))), scale); \
                    w[p * 4 + 2] = vmulq_f32(vcvtq_f32_s32(vmovl_s16(vget_low_s16(hi))), scale);  \
                    w[p * 4 + 3] = vmulq_f32(vcvtq_f32_s32(vmovl_s16(vget_high_s16(hi))), scale); \
                }                                                                            \
                for (int64_t t = 0; t < tile; ++t) {                                         \
                    const float *xs = x + (i0 + t) * x_stride + b * Q8_0_BLOCK_ELEMENTS;     \
                    for (int v = 0; v < 8; v += 2) {                                         \
                        sum[t][0] = vfmaq_f32(sum[t][0], vld1q_f32(xs + v * 4), w[v]);       \
                        sum[t][1] = vfmaq_f32(sum[t][1], vld1q_f32(xs + v * 4 + 4), w[v + 1]); \
                    }                                                                        \
                }                                                                            \
            }                                                                                \
            for (int64_t t = 0; t < tile; ++t)                                               \
                out[(i0 + t) * out_stride + j] = vaddvq_f32(vaddq_f32(sum[t][0], sum[t][1])); \
        }                                                                                    \
    }                                                                                        \
}

DEFINE_Q8_0_NEON_MATMUL(q8_0_matmul_tile4, 4)
DEFINE_Q8_0_NEON_MATMUL(q8_0_matmul_tile8, 8)

int ts_q8_0_matmul(int64_t n, int64_t m, int64_t k, const void *blocks,
                   const float *x, int64_t x_stride, float *out, int64_t out_stride) {
    if (n < 0 || m < 0 || k < 0 || k % Q8_0_BLOCK_ELEMENTS) return 1;
    /* Eight rows reuse more but cost more registers, which slows a single row. */
    (n <= 4 ? q8_0_matmul_tile4 : q8_0_matmul_tile8)(
        n, m, k / Q8_0_BLOCK_ELEMENTS, (const uint8_t *)blocks, x, x_stride, out, out_stride);
    return 0;
}

#else

int ts_q8_0_matmul(int64_t n, int64_t m, int64_t k, const void *blocks,
                   const float *x, int64_t x_stride, float *out, int64_t out_stride) {
    if (n < 0 || m < 0 || k < 0 || k % Q8_0_BLOCK_ELEMENTS) return 1;
    const int64_t block_count = k / Q8_0_BLOCK_ELEMENTS;
    for (int64_t j = 0; j < m; ++j) {
        const uint8_t *row = (const uint8_t *)blocks + j * block_count * Q8_0_BLOCK_BYTES;
        for (int64_t i = 0; i < n; ++i) {
            float sum = 0;
            for (int64_t b = 0; b < block_count; ++b) {
                const uint8_t *block = row + b * Q8_0_BLOCK_BYTES;
                const float scale = q8_0_scale(block);
                const float *xs = x + i * x_stride + b * Q8_0_BLOCK_ELEMENTS;
                float partial = 0;
                for (int e = 0; e < Q8_0_BLOCK_ELEMENTS; ++e)
                    partial += xs[e] * (float)(int8_t)block[2 + e];
                sum += partial * scale;
            }
            out[i * out_stride + j] = sum;
        }
    }
    return 0;
}

#endif
