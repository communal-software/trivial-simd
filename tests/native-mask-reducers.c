#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

static size_t allocations, releases;
static int fail_allocation;
static void *checked_malloc(size_t n) { ++allocations; return fail_allocation ? NULL : malloc(n); }
static void checked_free(void *p) { if (p) ++releases; free(p); }
#define malloc checked_malloc
#define free checked_free
#include "../native/trivial_simd.c"
#undef malloc
#undef free

static const uint8_t divide_selection[] = {
    TS_OP_LAZY, 0, 0, 0,
    TS_OP_BRANCH, 8, 0, 0,
    TS_OP_DIVIDE, 0, 9, 10,
    TS_OP_SPILL, 0, 2, 0,
    TS_OP_ELSE, 0, 0, 0,
    TS_OP_COPY, TS_KERNEL_OUTPUT, 11, 0,
    TS_OP_ELSE, 1, 0, 0,
    TS_OP_RELOAD, TS_KERNEL_OUTPUT, 2, 0,
    TS_OP_END, 0, 0, 0
};

#define CHECK_REDUCERS(suffix, type, integral) \
static void check_##suffix(void) { \
    type flag[601], a[601], b[601], other[601]; \
    const type *inputs[] = {flag, a, b, other}; \
    for (size_t j = 0; j < 601; ++j) { flag[j] = j % 2 == 0; a[j] = 4; b[j] = flag[j] ? 2 : 0; other[j] = 7; } \
    for (size_t n = 0; n <= 601; n += n < 18 ? 1 : n < 255 ? 237 : n < 258 ? 1 : 343) { \
        type value; double wide; size_t index; \
        for (unsigned reducer = 1; reducer <= TS_REDUCE_SUM; ++reducer) { \
            if (integral && reducer >= TS_REDUCE_SUMSQ && reducer <= TS_REDUCE_SCALED_SUMSQ) continue; \
            if (reducer == TS_REDUCE_PROD && n > 10) continue; \
            size_t before = allocations; \
            int status = ts_kernel_reduction_##suffix(divide_selection, sizeof divide_selection, NULL, inputs, \
                            4, n, 3, reducer, 7, &value, &wide, &index); \
            assert(status == 0 && allocations == before + (n != 0) && allocations == releases); \
            if (reducer == TS_REDUCE_ARGMIN) assert(index == 0 && value == (n ? 2 : 0)); \
            if (reducer == TS_REDUCE_ARGMAX) assert(index == (n > 1 ? 1 : 0) && value == (n > 1 ? 7 : n ? 2 : 0)); \
            if (reducer == TS_REDUCE_ASUM || reducer == TS_REDUCE_SUM) \
                assert(value == (type)(2 * ((n + 1) / 2) + 7 * (n / 2))); \
            if (reducer == TS_REDUCE_PROD) { \
                type expected = 1; \
                for (size_t j = 0; j < n; ++j) expected = integral ? \
                    (type)((uint64_t)expected * (j % 2 ? 7 : 2)) : (type)(expected * (j % 2 ? 7 : 2)); \
                assert(value == expected); \
            } \
            if (reducer == TS_REDUCE_SUMSQ) assert(wide == 4 * ((n + 1) / 2) + 49 * (n / 2)); \
            if (reducer == TS_REDUCE_MAXABS) assert(wide == (n > 1 ? 7 : n ? 2 : 0)); \
            if (reducer == TS_REDUCE_SCALED_SUMSQ) \
                assert(fabs(wide - (4.0 / 49 * ((n + 1) / 2) + n / 2)) < 1e-10); \
        } \
    } \
    type value = 99; double wide; size_t index; \
    b[0] = 0; size_t before = allocations; \
    assert(ts_kernel_reduction_##suffix(divide_selection, sizeof divide_selection, NULL, inputs, 4, 601, \
               3, TS_REDUCE_SUM, 0, &value, &wide, &index) == -5); \
    assert(allocations == before + 1 && allocations == releases); \
    value = 99; fail_allocation = 1; before = allocations; \
    assert(ts_kernel_reduction_##suffix(divide_selection, sizeof divide_selection, NULL, inputs, 4, 601, \
               3, TS_REDUCE_SUM, 0, &value, &wide, &index) == -1); \
    assert(value == 99 && allocations == before + 1 && releases == before); \
    --allocations; fail_allocation = 0; \
    before = allocations; \
    assert(ts_kernel_reduction_##suffix(divide_selection, sizeof divide_selection, NULL, inputs, 4, 601, \
               SIZE_MAX, TS_REDUCE_SUM, 0, &value, &wide, &index) == -1); \
    assert(allocations == before); \
    uint8_t invalid[sizeof divide_selection]; memcpy(invalid, divide_selection, sizeof invalid); \
    invalid[sizeof invalid - 2] = 1; \
    assert(ts_kernel_reduction_##suffix(invalid, sizeof invalid, NULL, inputs, 4, 601, \
               3, TS_REDUCE_SUM, 0, &value, &wide, &index) == -4); \
    assert(allocations == releases); \
}
CHECK_REDUCERS(f32, float, 0)
CHECK_REDUCERS(f64, double, 0)
CHECK_REDUCERS(s8, uint8_t, 1)
CHECK_REDUCERS(u8, uint8_t, 1)
CHECK_REDUCERS(s16, uint16_t, 1)
CHECK_REDUCERS(u16, uint16_t, 1)
CHECK_REDUCERS(s32, uint32_t, 1)
CHECK_REDUCERS(u32, uint32_t, 1)
CHECK_REDUCERS(s64, uint64_t, 1)
CHECK_REDUCERS(u64, uint64_t, 1)

static void check_environment(void) {
    fenv_t original;
    assert(fegetenv(&original) == 0);
    float flag[] = {0, 1, 0, 1}, a[] = {4, 4, 4, 4}, b[] = {0, 2, 0, 2}, other[] = {-0.0f, 7, -0.0f, 7};
    const float *inputs[] = {flag, a, b, other};
    float value; double wide; size_t index;
    for (size_t n = 1; n <= 4; ++n) {
        assert(fesetround(FE_DOWNWARD) == 0);
        feclearexcept(FE_ALL_EXCEPT);
        feraiseexcept(FE_INEXACT);
        int flags = fetestexcept(FE_ALL_EXCEPT);
        assert(ts_kernel_reduction_f32(divide_selection, sizeof divide_selection, NULL, inputs, 4, n, 3,
                                      TS_REDUCE_ARGMIN, 0, &value, &wide, &index) == 0);
        assert(index == 0 && value == 0 && signbit(value));
        assert(fegetround() == FE_DOWNWARD && fetestexcept(FE_ALL_EXCEPT) == flags);
    }
    b[1] = 0;
    assert(ts_kernel_reduction_f32(divide_selection, sizeof divide_selection, NULL, inputs, 4, 4, 3,
                                  TS_REDUCE_SUM, 0, &value, &wide, &index) == -5);
    assert(fegetround() == FE_DOWNWARD && fetestexcept(FE_ALL_EXCEPT) == FE_INEXACT);
    assert(fesetenv(&original) == 0);
}

static void check_nested_inactive_nan(void) {
    const uint8_t code[] = {
        TS_OP_LAZY, 0, 0, 0, TS_OP_COPY, 0, 9, 0,
        TS_OP_BRANCH, 8, 0, 0, TS_OP_GT, 0, 10, 11,
        TS_OP_BRANCH, 0, 2, 0, TS_OP_CONSTANT, 1, 0, 0,
        TS_OP_SPILL, 1, 4, 0, TS_OP_ELSE, 0, 2, 0,
        TS_OP_CONSTANT, 1, 1, 0, TS_OP_ELSE, 1, 2, 0,
        TS_OP_RELOAD, 1, 4, 0, TS_OP_END, 0, 2, 0,
        TS_OP_SPILL, 1, 5, 0, TS_OP_ELSE, 0, 0, 0,
        TS_OP_CONSTANT, TS_KERNEL_OUTPUT, 2, 0, TS_OP_ELSE, 1, 0, 0,
        TS_OP_RELOAD, TS_KERNEL_OUTPUT, 5, 0, TS_OP_END, 0, 0, 0
    };
    float flags[] = {1, 0, 1, 0}, condition[] = {1, 1, 0, 0}, zeros[] = {0, 0, 0, 0};
    float nan[4], constants[] = {1, 2, 3};
    uint32_t bits = UINT32_C(0x7f800123);
    for (size_t j = 0; j < 4; ++j) memcpy(nan + j, &bits, sizeof bits);
    const float *inputs[] = {flags, nan, condition, zeros};
    float value; double wide; size_t index;
    assert(ts_kernel_reduction_f32(code, sizeof code, constants, inputs, 4, 4, 6,
                                  TS_REDUCE_SUM, 0, &value, &wide, &index) == 0);
    assert(value == 9);
}


#define CHECK_SELECTION_ENTRY_POINTS(suffix, type, integral) \
static void check_selection_##suffix(void) { \
    type flag[601], a[601], b[601], other[601], out[603], scratch[3 * TS_KERNEL_BLOCK + 2]; \
    const type *inputs[] = {flag, a, b, other}; \
    for (size_t i = 0; i < 601; ++i) { flag[i] = i % 2 == 0; a[i] = 4; b[i] = flag[i] ? 2 : 0; other[i] = 7; } \
    const size_t lengths[] = {0, 1, 3, 255, 256, 257, 601}; \
    for (size_t k = 0; k < sizeof lengths / sizeof *lengths; ++k) { \
        size_t n = lengths[k]; \
        out[0] = out[n + 1] = 99; \
        scratch[0] = scratch[3 * TS_KERNEL_BLOCK + 1] = 99; \
        assert(ts_kernel_##suffix(divide_selection, sizeof divide_selection, NULL, inputs, out + 1, n, 3) == 0); \
        for (size_t i = 0; i < n; ++i) assert(out[i + 1] == (i % 2 ? 7 : 2)); \
        assert(out[0] == 99 && out[n + 1] == 99 && allocations == releases); \
        assert(ts_kernel_with_scratch_##suffix(divide_selection, sizeof divide_selection, NULL, inputs, \
                                               out + 1, n, 3, scratch + 1, 3) == 0); \
        for (size_t i = 0; i < n; ++i) assert(out[i + 1] == (i % 2 ? 7 : 2)); \
        assert(scratch[0] == 99 && scratch[3 * TS_KERNEL_BLOCK + 1] == 99); \
        type sum = 99; \
        assert(ts_kernel_sum_##suffix(divide_selection, sizeof divide_selection, NULL, inputs, &sum, n, 3) == 0); \
        assert(sum == (type)(2 * ((n + 1) / 2) + 7 * (n / 2)) && allocations == releases); \
    } \
    b[0] = 0; \
    assert(ts_kernel_with_scratch_##suffix(divide_selection, sizeof divide_selection, NULL, inputs, \
                                           out, 601, SIZE_MAX, scratch, SIZE_MAX) == -1); \
    assert(ts_kernel_##suffix(divide_selection, sizeof divide_selection, NULL, inputs, out, 601, 3) == (integral ? -3 : -5)); \
    assert(allocations == releases); \
    fail_allocation = 1; \
    size_t before = allocations; \
    out[0] = 99; \
    assert(ts_kernel_##suffix(divide_selection, sizeof divide_selection, NULL, inputs, out, 601, 3) == -1); \
    assert(out[0] == 99 && allocations == before + 1 && releases == before); \
    --allocations; fail_allocation = 0; \
}
CHECK_SELECTION_ENTRY_POINTS(f32, float, 0)
CHECK_SELECTION_ENTRY_POINTS(f64, double, 0)
CHECK_SELECTION_ENTRY_POINTS(s8, uint8_t, 1)
CHECK_SELECTION_ENTRY_POINTS(u8, uint8_t, 1)
CHECK_SELECTION_ENTRY_POINTS(s16, uint16_t, 1)
CHECK_SELECTION_ENTRY_POINTS(u16, uint16_t, 1)
CHECK_SELECTION_ENTRY_POINTS(s32, uint32_t, 1)
CHECK_SELECTION_ENTRY_POINTS(u32, uint32_t, 1)
CHECK_SELECTION_ENTRY_POINTS(s64, uint64_t, 1)
CHECK_SELECTION_ENTRY_POINTS(u64, uint64_t, 1)

#define CHECK_SELECTION_BATCHES(suffix, type, precision) \
static void check_selection_batches_##suffix(void) { \
    type flag[601], a[601], b[601], other[601], out[601], scratch[3 * TS_KERNEL_BLOCK]; \
    const type *inputs[] = {flag, a, b, other}; \
    ts_kernel_input descriptors[4]; \
    const int64_t strides[] = {0, 0, 0, 0}; \
    for (size_t i = 0; i < 601; ++i) { flag[i] = i % 2 == 0; a[i] = 4; b[i] = flag[i] ? 2 : 0; other[i] = 7; } \
    for (size_t j = 0; j < 4; ++j) descriptors[j] = (ts_kernel_input){inputs[j], 601, 0, precision, 1, 0, 0}; \
    type sum, rows[2]; \
    assert(ts_kernel_sum_with_scratch_##suffix(divide_selection, sizeof divide_selection, NULL, inputs, &sum, 601, 3, scratch, 3) == 0); \
    assert(sum == 2702); \
    assert(ts_kernel_sum_rows_##suffix(divide_selection, sizeof divide_selection, NULL, inputs, 4, strides, rows, 2, 601, 3) == 0); \
    assert(rows[0] == 2702 && rows[1] == 2702); \
    double wide; size_t index; \
    assert(ts_kernel_inputs_##suffix(divide_selection, sizeof divide_selection, NULL, descriptors, 4, out, 1, 601, 3, TS_INPUT_OUTPUT, 0, &wide, &index) == 0); \
    for (size_t i = 0; i < 601; ++i) assert(out[i] == (i % 2 ? 7 : 2)); \
    assert(ts_kernel_inputs_##suffix(divide_selection, sizeof divide_selection, NULL, descriptors, 4, rows, 2, 601, 3, TS_INPUT_SUM, 0, &wide, &index) == 0); \
    assert(rows[0] == 2702 && rows[1] == 2702 && allocations == releases); \
}
CHECK_SELECTION_BATCHES(f32, float, 0)
CHECK_SELECTION_BATCHES(f64, double, 1)

int main(void) {
    if (!ts_kernel_predication()) { puts("native predication unavailable; scalar fallback required"); return 0; }
    check_selection_f32(); check_selection_f64(); check_selection_s8(); check_selection_u8();
    check_selection_s16(); check_selection_u16(); check_selection_s32(); check_selection_u32();
    check_selection_s64(); check_selection_u64();
    check_selection_batches_f32(); check_selection_batches_f64();
    check_f32(); check_f64(); check_s8(); check_u8(); check_s16(); check_u16();
    check_s32(); check_u32(); check_s64(); check_u64(); check_environment(); check_nested_inactive_nan();
    puts("native mask reducers passed");
    return 0;
}
