#if !defined(TS_SCALAR) && (defined(__aarch64__) || defined(_M_ARM64))
#define TS_STRIDED_REVERSE_f32(v) vextq_f32(vrev64q_f32(v), vrev64q_f32(v), 2)
#define TS_STRIDED_REVERSE_f64(v) vextq_f64(v, v, 1)
#define TS_STRIDED_DEINTERLEAVE_f32(p) vld2q_f32(p).val[0]
#define TS_STRIDED_DEINTERLEAVE_f64(p) vld2q_f64(p).val[0]
#elif !defined(TS_SCALAR) && (defined(__x86_64__) || defined(_M_X64))
#define TS_STRIDED_REVERSE_f32(v) _mm_shuffle_ps(v, v, _MM_SHUFFLE(0, 1, 2, 3))
#define TS_STRIDED_REVERSE_f64(v) _mm_shuffle_pd(v, v, 1)
#define TS_STRIDED_DEINTERLEAVE_f32(p) _mm_shuffle_ps(_mm_loadu_ps(p), _mm_loadu_ps((p) + 4), _MM_SHUFFLE(2, 0, 2, 0))
#define TS_STRIDED_DEINTERLEAVE_f64(p) _mm_unpacklo_pd(_mm_loadu_pd(p), _mm_loadu_pd((p) + 2))
#else
#define TS_STRIDED_REVERSE_f32(v) (v)
#define TS_STRIDED_REVERSE_f64(v) (v)
#define TS_STRIDED_DEINTERLEAVE_f32(p) (*(p))
#define TS_STRIDED_DEINTERLEAVE_f64(p) (*(p))
#endif

static int ts_strided_memory_disjoint(const void *input, int64_t step, const void *output,
                                      int64_t output_step, size_t bytes, size_t n) {
    if (!input || (step != 2 && step != -2)) return 1;
    uintptr_t a = (uintptr_t)input, b = (uintptr_t)output;
    uintptr_t last_a = a + (uintptr_t)((int64_t)(n - 1) * step * (int64_t)bytes);
    uintptr_t last_b = b + (uintptr_t)((int64_t)(n - 1) * output_step * (int64_t)bytes);
    uintptr_t low_a = a < last_a ? a : last_a, high_a = a > last_a ? a : last_a;
    uintptr_t low_b = b < last_b ? b : last_b, high_b = b > last_b ? b : last_b;
    return high_a + bytes <= low_b || high_b + bytes <= low_a;
}

static unsigned ts_strided_memory_key(unsigned op, unsigned type, const int64_t *steps) {
    unsigned layout = 0;
    for (size_t i = 0; i < 4; ++i) {
        if (steps[i] < -2 || steps[i] > 2) return UINT32_MAX;
        layout = layout * 5 + (unsigned)(steps[i] + 2);
    }
    return (op * 2 + type) * 625 + layout;
}

static int ts_strided_memory_enabled(unsigned op, unsigned type, size_t n, const int64_t *steps) {
    if (type > 1) return 0;
#if defined(TS_SCALAR) || defined(TS_DISABLE_STRIDED_SPECIALIZATIONS)
    (void)op; (void)type; (void)n; (void)steps; return 0;
#elif defined(TS_STRIDED_MEMORY_TEST)
    (void)op; (void)type; (void)n; (void)steps; return strided_specialized;
#elif defined(TS_FORCE_STRIDED_SPECIALIZATIONS)
    (void)op; (void)type; (void)n; (void)steps; return 1;
#else
    struct gate { unsigned key; size_t count; };
    static const struct gate gates[] = {
#include "strided-memory-gates.h"
    };
    if (n < TS_STRIDED_MEMORY_MIN_COUNT) return 0;
    unsigned key = ts_strided_memory_key(op, type, steps);
    if (key == UINT32_MAX) return 0;
    size_t low = 0, high = sizeof gates / sizeof gates[0];
    while (low < high) {
        size_t middle = low + (high - low) / 2;
        if (gates[middle].key < key) low = middle + 1;
        else high = middle;
    }
    return low < sizeof gates / sizeof gates[0] && gates[low].key == key && n >= gates[low].count;
#endif
}

#define TS_STRIDED_MEMORY(suffix, type, width, vector, load, store, splat) \
static vector ts_strided_load_##suffix(const type *p, int64_t step, size_t remaining, \
                                       size_t processed, int specialized, int interleaved_safe) { \
    if (step == 1) return load(p); \
    if (!step) return splat(*p); \
    if (specialized && step == -1) return TS_STRIDED_REVERSE_##suffix(load(p - (width - 1))); \
    /* Deinterleaving reads one gap beyond the selected lanes. */ \
    if (specialized && interleaved_safe && step == 2 && remaining > width) \
        return TS_STRIDED_DEINTERLEAVE_##suffix(p); \
    if (specialized && interleaved_safe && step == -2 && processed) \
        return TS_STRIDED_REVERSE_##suffix(TS_STRIDED_DEINTERLEAVE_##suffix(p - 2 * (width - 1))); \
    type values[width]; \
    for (size_t j = 0; j < width; ++j) values[j] = p[(int64_t)j * step]; \
    return load(values); \
} \
static void ts_strided_store_##suffix(type *p, int64_t step, vector value, int specialized) { \
    if (step == 1) { store(p, value); return; } \
    if (specialized && step == -1) { store(p - (width - 1), TS_STRIDED_REVERSE_##suffix(value)); return; } \
    type values[width]; store(values, value); \
    for (size_t j = 0; j < width; ++j) p[(int64_t)j * step] = values[j]; \
}
TS_STRIDED_MEMORY(f32, float, TS_F32_WIDTH, TS_F32_VECTOR, TS_F32_LOAD, TS_F32_STORE, TS_F32_SPLAT)
TS_STRIDED_MEMORY(f64, double, TS_F64_WIDTH, TS_F64_VECTOR, TS_F64_LOAD, TS_F64_STORE, TS_F64_SPLAT)
#undef TS_STRIDED_MEMORY
#undef TS_STRIDED_REVERSE_f32
#undef TS_STRIDED_REVERSE_f64
#undef TS_STRIDED_DEINTERLEAVE_f32
#undef TS_STRIDED_DEINTERLEAVE_f64
