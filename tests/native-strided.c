#include <assert.h>
#include <stdio.h>
#include <math.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#if defined(__unix__) || defined(__APPLE__)
#include <sys/mman.h>
#include <unistd.h>
#endif

static size_t allocations;
static void *strided_malloc(size_t n) { (void)n; ++allocations; return NULL; }
static void *strided_calloc(size_t n, size_t size) { (void)n; (void)size; ++allocations; return NULL; }
static void *strided_realloc(void *p, size_t n) { (void)p; (void)n; ++allocations; return NULL; }
#define TS_STRIDED_MEMORY_TEST
#ifdef TS_FORCE_STRIDED_SPECIALIZATIONS
static int strided_specialized = 1;
#else
static int strided_specialized;
#endif
#define malloc strided_malloc
#define calloc strided_calloc
#define realloc strided_realloc
#include "../native/trivial_simd.c"
#undef malloc
#undef calloc
#undef realloc

#define TEST_INTEGER(code, type) do { \
    type a[128], b[128], out[128]; \
    for (size_t i = 0; i < 128; ++i) { \
        a[i] = (type)(UINT64_C(0xfedcba9876543211) * (i + 1)); \
        b[i] = (type)(UINT64_C(0x12345678abcdef01) * (i + 3)); out[i] = 7; \
    } \
    int64_t strides[] = {3, -2, 2, 0}; void *p[] = {out, a + 80, b + 1, NULL}; \
    for (size_t n = 0; n <= 33; ++n) { \
        assert(ts_strided_execute(TS_ND_MULTIPLY, code, code, 0, 0, 0, n, strides, p) == 0); \
        for (size_t i = 0; i < n; ++i) assert(out[3 * i] == (type)((uint64_t)a[80 - 2 * i] * b[1 + 2 * i])); \
    } \
    uint64_t index; double wide; type result; \
    assert(ts_strided_reduce(TS_STRIDED_SUM, code, 33, a + 80, NULL, -2, 1, 0, &result, &wide, &index) == 0); \
    type expected = 0; for (size_t i = 0; i < 33; ++i) expected = (type)((uint64_t)expected + a[80 - 2 * i]); \
    assert(result == expected); \
    assert(ts_strided_reduce(TS_STRIDED_PROD, code, 33, a + 80, NULL, -2, 1, 0, &result, &wide, &index) == 0); \
    expected = 1; for (size_t i = 0; i < 33; ++i) expected = (type)((uint64_t)expected * a[80 - 2 * i]); \
    assert(result == expected); \
} while (0)

static void float_operations(void) {
    float a[128], b[128], out[128], scalar = 3;
    for (size_t i = 0; i < 128; ++i) { a[i] = (float)i; b[i] = 2; out[i] = -7; }
    int64_t strides[] = {3, -2, 2, 0}; void *p[] = {out, a + 80, b, NULL};
    for (size_t n = 0; n <= 33; ++n) {
        assert(ts_strided_execute(TS_ND_ADD, 0, 0, 0, 0, 0, n, strides, p) == 0);
        for (size_t i = 0; i < n; ++i) assert(out[3 * i] == a[80 - 2 * i] + b[2 * i]);
        for (size_t i = 0; i < 128; ++i) if (i % 3) assert(out[i] == -7);
    }
    p[1] = &scalar; strides[1] = 0;
    assert(ts_strided_execute(TS_STRIDED_SCALE, 0, 0, 0, 0, 0, 33, strides, p) == 0);
    for (size_t i = 0; i < 33; ++i) assert(out[3 * i] == 3 * (a[80 - 2 * i] + 2));
    assert(ts_strided_execute(TS_STRIDED_AXPY, 0, 0, 0, 0, 0, 33, strides, p) == 0);
    for (size_t i = 0; i < 33; ++i) assert(out[3 * i] == 3 * (a[80 - 2 * i] + 2) + 6);
    p[1] = a + 80; strides[1] = -2;
    float result; double wide; uint64_t index;
    assert(ts_strided_reduce(TS_STRIDED_SUM, 0, 33, a + 80, NULL, -2, 1, 0, &result, &wide, &index) == 0);
    assert(result == 1584);
    assert(ts_strided_reduce(TS_STRIDED_DOT, 0, 33, a + 80, b, -2, 2, 1, &result, &wide, &index) == 0);
    assert(wide == 3168);
    assert(ts_strided_reduce(TS_STRIDED_ARGMIN, 0, 33, a + 80, NULL, -2, 1, 0, &result, &wide, &index) == 0);
    assert(index == 32);
    float zeros[] = {-0.0f, 7, 0.0f, 7, -0.0f};
    assert(ts_strided_reduce(TS_STRIDED_ARGMIN, 0, 3, zeros, NULL, 2, 1, 0, &result, &wide, &index) == 0);
    assert(index == 0 && signbit(result));
    double norm_input[] = {1e200, 1, -1e200};
    assert(ts_strided_reduce(TS_STRIDED_NRM2, 1, 2, norm_input, NULL, 2, 1, 0, &wide, &wide, &index) == 0);
    assert(fabs(wide / 1e200 - sqrt(2.0)) < 1e-15);
}

static void transfers_and_masks(void) {
    uint8_t a[128], b[128], result; uint64_t index; double wide;
    memset(a, 255, sizeof a); memset(b, 7, sizeof b);
    int64_t steps[] = {2, -3, 0, 0}; void *p[] = {b, a + 99, NULL, NULL};
    assert(ts_strided_execute(TS_STRIDED_SWAP, 3, 3, 0, 0, 0, 33, steps, p) == 0);
    for (size_t i = 0; i < 33; ++i) { assert(b[2 * i] == 255); assert(a[99 - 3 * i] == 7); }
    assert(ts_strided_reduce(TS_STRIDED_COUNT, 3, 33, a + 99, NULL, -3, 1, 0, &result, &wide, &index) == 0);
    assert(index == 33);
    assert(ts_strided_reduce(TS_STRIDED_ALL, 3, 0, NULL, NULL, 2, 1, 0, &result, &wide, &index) == 0);
    assert(index == 1);
    assert(ts_strided_mask_reduce(1, a + 99, 33, -3) == 1);
    assert(ts_strided_mask_reduce(2, a + 99, 33, -3) == 1);
    a[99 - 3 * 19] = 0;
    assert(ts_strided_mask_reduce(2, a + 99, 33, -3) == 0);
    assert(ts_strided_mask_reduce(0, a + 99, 33, -3) == 32);
    assert(ts_strided_mask_reduce(3, NULL, 0, 1) == UINT64_MAX);
    assert(ts_strided_mask_reduce(0, NULL, 1, 1) == UINT64_MAX);
    assert(ts_strided_mask_reduce(0, a, 1, 0) == UINT64_MAX);
    assert(ts_strided_execute(TS_ND_ADD, 3, 3, 0, 0, 0, 33, steps, p) == -1);
    assert(ts_strided_execute(TS_STRIDED_COPY, 14, 3, 0, 0, 0, 33, steps, p) == -1);
    steps[0] = 0;
    assert(ts_strided_execute(TS_STRIDED_COPY, 3, 3, 0, 0, 0, 33, steps, p) == -1);
    assert(ts_strided_execute(TS_STRIDED_COPY, 3, 3, 0, 0, 0, 0, steps, p) == 0);
}

static void complex_and_conversions(void) {
    float a[128], b[128], out[128];
    for (size_t i = 0; i < 64; ++i) { a[2*i] = 1; a[2*i+1] = 2; b[2*i] = 3; b[2*i+1] = -1; }
    int64_t steps[] = {2, -2, 2, 0}; void *p[] = {out, a + 80, b, NULL};
    assert(ts_strided_execute(TS_ND_MULTIPLY, 10, 10, 0, 0, 0, 17, steps, p) == 0);
    for (size_t i = 0; i < 17; ++i) { assert(out[4*i] == 5); assert(out[4*i+1] == 5); }
    float result[2]; double wide[2]; uint64_t index;
    assert(ts_strided_reduce(TS_STRIDED_DOTC, 10, 17, a + 80, b, -2, 2, 1, result, wide, &index) == 0);
    assert(wide[0] == 17 && wide[1] == -119);
    double doubles[128] = {0}; p[0] = doubles; p[1] = a; steps[1] = 2;
    assert(ts_strided_execute(TS_ND_CONVERT, 0, 1, 0, 0, 0, 17, steps, p) == 0);
    for (size_t i = 0; i < 17; ++i) assert(doubles[2*i] == 1);
}


#define CHECK_FLOAT_LAYOUT(suffix, type, code, fused) do { \
    type a[256], b[256], c[256], out[256]; \
    int64_t layouts[] = {-2, -1, 0, 1, 2, 3}; \
    for (size_t n = 0; n <= 33; ++n) \
    for (size_t d = 0; d < 6; ++d) { \
        if (!layouts[d]) continue; \
        for (size_t left = 0; left < 6; ++left) \
        for (size_t right = 0; right < 6; ++right) { \
            for (size_t j = 0; j < 256; ++j) { \
                a[j] = (type)(j % 13 - 6.0); b[j] = (type)(1 + j % 7); \
                c[j] = (type)(j % 5 - 2.0); out[j] = -99; \
            } \
            int64_t steps[] = {layouts[d], layouts[left], layouts[right], -1}; \
            void *p[] = {out + 100, a + 100, b + 100, c + 100}; \
            unsigned operations[] = {TS_ND_ADD, TS_ND_SUBTRACT, TS_ND_MULTIPLY, TS_ND_DIVIDE, \
                TS_ND_NEGATE, TS_ND_ABS, TS_ND_MIN, TS_ND_MAX, TS_STRIDED_SCALE, TS_STRIDED_AXPY, TS_STRIDED_FMA}; \
            for (size_t op = 0; op < sizeof operations / sizeof operations[0]; ++op) { \
                for (size_t j = 0; j < 256; ++j) out[j] = -99; \
                assert(ts_strided_execute(operations[op], code, code, 0, 0, 0, n, steps, p) == 0); \
                for (size_t j = 0; j < 256; ++j) { \
                    int64_t delta = (int64_t)j - 100, logical = delta / steps[0]; \
                    if (delta % steps[0] || logical < 0 || (size_t)logical >= n) { assert(out[j] == -99); continue; } \
                    type x = a[100 + logical * steps[1]], y = b[100 + logical * steps[2]], expected; \
                    switch (operations[op]) { \
                    case TS_ND_ADD: expected = x + y; break; \
                    case TS_ND_SUBTRACT: expected = x - y; break; \
                    case TS_ND_MULTIPLY: expected = x * y; break; \
                    case TS_ND_DIVIDE: expected = x / y; break; \
                    case TS_ND_NEGATE: expected = -x; break; \
                    case TS_ND_ABS: expected = (type)fabs(x); break; \
                    case TS_ND_MIN: expected = x <= y ? x : y; break; \
                    case TS_ND_MAX: expected = x >= y ? x : y; break; \
                    case TS_STRIDED_SCALE: expected = -99 * x; break; \
                    case TS_STRIDED_AXPY: expected = x * y - 99; break; \
                    default: expected = fused(x, y, c[100 - logical]); break; \
                    } \
                    if (out[j] != expected) fprintf(stderr, "code=%u n=%zu op=%u d=%lld l=%lld r=%lld j=%zu actual=%.17g expected=%.17g\n", code, n, operations[op], (long long)steps[0], (long long)steps[1], (long long)steps[2], j, (double)out[j], (double)expected); \
                    assert(out[j] == expected); \
                    if (expected == 0) assert(signbit(out[j]) == signbit(expected)); \
                } \
            } \
        } \
    } \
} while (0)

#define CHECK_MEMORY_BITS(suffix, type, width, store) do { \
    type values[40], general[width], specialized[width]; \
    unsigned char *bits = (unsigned char *)values; \
    for (size_t j = 0; j < sizeof values; ++j) bits[j] = (unsigned char)(j * 73 + 19); \
    const int64_t steps[] = {-2, -1, 0, 1, 2, 3}; \
    for (size_t j = 0; j < 6; ++j) \
    for (size_t remaining = width; remaining <= width + 1; ++remaining) \
    for (size_t processed = 0; processed <= width; processed += width) { \
        store(general, ts_strided_load_##suffix(values + 16, steps[j], remaining, processed, 0, 1)); \
        store(specialized, ts_strided_load_##suffix(values + 16, steps[j], remaining, processed, 1, 1)); \
        assert(memcmp(general, specialized, sizeof general) == 0); \
        type a[40], b[40]; memset(a, 19, sizeof a); memcpy(b, a, sizeof a); \
        ts_strided_store_##suffix(a + 16, steps[j], TS_##suffix##_LOAD(values), 0); \
        ts_strided_store_##suffix(b + 16, steps[j], TS_##suffix##_LOAD(values), 1); \
        assert(memcmp(a, b, sizeof a) == 0); \
    } \
} while (0)
#define TS_f32_LOAD TS_F32_LOAD
#define TS_f64_LOAD TS_F64_LOAD

static void specialized_layouts(void) {
    CHECK_FLOAT_LAYOUT(f32, float, 0, fmaf);
    CHECK_FLOAT_LAYOUT(f64, double, 1, fma);
    CHECK_MEMORY_BITS(f32, float, TS_F32_WIDTH, TS_F32_STORE);
    CHECK_MEMORY_BITS(f64, double, TS_F64_WIDTH, TS_F64_STORE);
}
#undef TS_f32_LOAD
#undef TS_f64_LOAD

static void exact_reducers(void) {
    float a[600], b[600]; double da[600], db[600];
    for (size_t i = 0; i < 600; ++i) {
        a[i] = (i % 3 == 0 ? 1e15f : i % 3 == 1 ? -1e15f : 0.125f);
        b[i] = i % 2 ? 1.5f : -0.5f;
        da[i] = a[i]; db[i] = b[i];
    }
    int saved = strided_specialized;
    const int64_t steps[] = {-2, -1, 1, 2, 3};
    for (unsigned type = 0; type < 2; ++type)
    for (unsigned op = TS_STRIDED_SUM; op <= TS_STRIDED_DOT; ++op)
    for (int wide = 0; wide <= (type == 0); ++wide)
    for (size_t n = 0; n <= 257; ++n)
    for (size_t left = 0; left < 5; ++left)
    for (size_t right = 0; right < 5; ++right) {
        if (steps[left] == 3 || steps[right] == 3) { if (n > 100) continue; }
        size_t ai = steps[left] < 0 ? (n ? n - 1 : 0) * (size_t)-steps[left] + 1 : 1;
        size_t bi = steps[right] < 0 ? (n ? n - 1 : 0) * (size_t)-steps[right] + 1 : 1;
        const void *x = type ? (void *)(da + ai) : (void *)(a + ai);
        const void *y = type ? (void *)(db + bi) : (void *)(b + bi);
        unsigned char general[8] = {0}, candidate[8] = {0};
        double gw = 0, cw = 0; uint64_t gi = 0, ci = 0;
        strided_specialized = 0;
        assert(ts_strided_reduce(op, type, n, x, y, steps[left], steps[right], wide, general, &gw, &gi) == 0);
        strided_specialized = 1;
        assert(ts_strided_reduce(op, type, n, x, y, steps[left], steps[right], wide, candidate, &cw, &ci) == 0);
        assert(memcmp(general, candidate, sizeof general) == 0);
        assert(memcmp(&gw, &cw, sizeof gw) == 0);
    }
    strided_specialized = saved;
}

static void guarded_spans(void) {
#if defined(__unix__) || defined(__APPLE__)
    size_t page = (size_t)sysconf(_SC_PAGESIZE);
    unsigned char *allocation = mmap(NULL, 3 * page, PROT_NONE, MAP_PRIVATE | MAP_ANON, -1, 0);
    assert(allocation != MAP_FAILED);
    unsigned char *storage = allocation + page;
    assert(mprotect(storage, page, PROT_READ | PROT_WRITE) == 0);
    for (unsigned type = 0; type < 2; ++type) {
        size_t bytes = type ? sizeof(double) : sizeof(float);
        for (size_t n = 1; n <= 17; ++n)
        for (int64_t step = -2; step <= 2; ++step) {
            if (!step) continue;
            size_t span = ((n - 1) * (size_t)llabs(step) + 1) * bytes;
            for (unsigned end = 0; end < 2; ++end) {
                unsigned char *first = end ? storage + page - span : storage;
                for (size_t j = 0; j < span / bytes; ++j) {
                    if (type) ((double *)first)[j] = 1; else ((float *)first)[j] = 1;
                }
                void *start = step < 0 ? first + span - bytes : first;
                int64_t steps[] = {step, step, 0, 1};
                double scalar = 2;
                float single_scalar = 2;
                void *p[] = {start, start, type ? (void *)&scalar : (void *)&single_scalar, NULL};
                assert(ts_strided_execute(TS_ND_ADD, type, type, 0, 0, 0, n, steps, p) == 0);
                /* A distinct output exercises bounded packed input loads. */
                double output[40], wide;
                uint64_t index;
                p[0] = output; steps[0] = 1;
                assert(ts_strided_execute(TS_ND_ADD, type, type, 0, 0, 0, n, steps, p) == 0);
                assert(ts_strided_reduce(TS_STRIDED_SUM, type, n, start, NULL, step, 1, 0, output, &wide, &index) == 0);
                assert(ts_strided_reduce(TS_STRIDED_DOT, type, n, start, start, step, step, 0, output, &wide, &index) == 0);
                if (!type) assert(ts_strided_reduce(TS_STRIDED_SUM, type, n, start, NULL, step, 1, 1, output, &wide, &index) == 0);
            }
        }
    }
    assert(munmap(allocation, 3 * page) == 0);
#endif
}

int main(void) {
    TEST_INTEGER(2, uint8_t); TEST_INTEGER(3, uint8_t);
    TEST_INTEGER(4, uint16_t); TEST_INTEGER(5, uint16_t);
    TEST_INTEGER(6, uint32_t); TEST_INTEGER(7, uint32_t);
    TEST_INTEGER(8, uint64_t); TEST_INTEGER(9, uint64_t);
    float_operations(); transfers_and_masks(); complex_and_conversions();
    specialized_layouts(); exact_reducers(); guarded_spans();
    assert(allocations == 0);
    return 0;
}
