#include <assert.h>
#include <math.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

static size_t allocations;
static void *strided_malloc(size_t n) { (void)n; ++allocations; return NULL; }
static void *strided_calloc(size_t n, size_t size) { (void)n; (void)size; ++allocations; return NULL; }
static void *strided_realloc(void *p, size_t n) { (void)p; (void)n; ++allocations; return NULL; }
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

int main(void) {
    TEST_INTEGER(2, uint8_t); TEST_INTEGER(3, uint8_t);
    TEST_INTEGER(4, uint16_t); TEST_INTEGER(5, uint16_t);
    TEST_INTEGER(6, uint32_t); TEST_INTEGER(7, uint32_t);
    TEST_INTEGER(8, uint64_t); TEST_INTEGER(9, uint64_t);
    float_operations(); transfers_and_masks(); complex_and_conversions();
    assert(allocations == 0);
    return 0;
}
