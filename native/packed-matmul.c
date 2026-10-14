#include <stdint.h>
#include <math.h>
#if defined(__ARM_NEON) && !defined(TS_SCALAR)
#include <arm_neon.h>
#endif

static int geometry(int type, int *elements, int *bytes) {
    switch (type) {
    case 2: *elements = 32; *bytes = 18; return 0;
    case 12: *elements = 256; *bytes = 144; return 0;
    case 14: *elements = 256; *bytes = 210; return 0;
    default: return 1;
    }
}

static int half_finite(const uint8_t *p) { return (p[1] & 124) != 124; }

static float half_value(const uint8_t *p) {
    unsigned bits = p[0] | (unsigned)p[1] << 8;
    unsigned exponent = (bits >> 10) & 31, fraction = bits & 1023;
    float magnitude = exponent ? ldexpf((float)(1024 + fraction), (int)exponent - 25)
                               : ldexpf((float)fraction, -24);
    return bits & 32768 ? -magnitude : magnitude;
}

static void unpack(int type, const uint8_t *b, float *w) {
    if (type == 2) {
        float d = half_value(b);
        for (int j = 0; j < 16; ++j) {
            w[j] = d * ((int)(b[2+j] & 15) - 8);
            w[j+16] = d * ((int)(b[2+j] >> 4) - 8);
        }
    } else if (type == 12) {
        float d = half_value(b), dm = half_value(b+2);
        const uint8_t *s = b+4, *q = b+16;
        for (int j = 0; j < 8; ++j) {
            int scale = j < 4 ? s[j] & 63 : (s[j+4] & 15) | ((s[j-4] >> 6) << 4);
            int min = j < 4 ? s[j+4] & 63 : (s[j+4] >> 4) | ((s[j] >> 6) << 4);
            float ds = d * scale, ms = dm * min;
            for (int l = 0; l < 32; ++l)
                w[j*32+l] = ds * ((q[(j/2)*32+l] >> ((j%2)*4)) & 15) - ms;
        }
    } else {
        float d = half_value(b+208);
        for (int n = 0; n < 2; ++n) {
            const uint8_t *ql = b+n*64, *qh = b+128+n*32;
            const int8_t *s = (const int8_t *)(b+192+n*8);
            for (int group = 0; group < 4; ++group)
                for (int l = 0; l < 32; ++l) {
                    int low = (ql[(group%2)*32+l] >> ((group/2)*4)) & 15;
                    int high = (qh[l] >> (group*2)) & 3;
                    w[n*128+group*32+l] = (d * s[group*2+l/16]) * ((low | (high<<4)) - 32);
                }
        }
    }
}

int ts_packed_matmul(int type, int64_t n, int64_t m, int64_t k, const uint8_t *blocks,
                     const float *x, int64_t xs, float *out, int64_t os) {
    int elements, bytes;
    if (geometry(type, &elements, &bytes) || n < 0 || m < 0 || k < 0 ||
        k % elements || xs < k || os < m) return 1;
    if ((xs && n && n-1 > (INT64_MAX-k)/xs) ||
        (os && n && n-1 > (INT64_MAX-m)/os)) return 1;
    if (!n || !m) return 0;
    int64_t count = k / elements;
    if (m && count > INT64_MAX / m / bytes) return 1;
    for (int64_t b = 0; b < m*count; ++b) {
        const uint8_t *p = blocks+b*bytes;
        if (!half_finite(p+(type == 14 ? 208 : 0)) ||
            (type == 12 && !half_finite(p+2))) return 2;
    }
    for (int64_t j = 0; j < m; ++j) {
        for (int64_t i = 0; i < n; i += 4) {
            int tile = n-i < 4 ? (int)(n-i) : 4;
#if defined(__ARM_NEON) && !defined(TS_SCALAR)
            float32x4_t sums[4];
            for (int t = 0; t < tile; ++t) sums[t] = vdupq_n_f32(0);
#else
            float sums[4] = {0, 0, 0, 0};
#endif
            for (int64_t b = 0; b < count; ++b) {
                float weights[256];
                unpack(type, blocks+(j*count+b)*bytes, weights);
                for (int t = 0; t < tile; ++t) {
                    const float *row = x+(i+t)*xs+b*elements;
#if defined(__ARM_NEON) && !defined(TS_SCALAR)
                    for (int e = 0; e < elements; e += 4)
                        sums[t] = vfmaq_f32(sums[t], vld1q_f32(row+e), vld1q_f32(weights+e));
#else
                    for (int e = 0; e < elements; ++e) sums[t] += row[e]*weights[e];
#endif
                }
            }
            for (int t = 0; t < tile; ++t)
#if defined(__ARM_NEON) && !defined(TS_SCALAR)
                out[(i+t)*os+j] = vaddvq_f32(sums[t]);
#else
                out[(i+t)*os+j] = sums[t];
#endif
        }
    }
    return 0;
}
