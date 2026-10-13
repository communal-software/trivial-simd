/* The Lisp caller validates spans and snapshots shifted input aliases. */
enum {
    TS_STRIDED_SCALE = 14, TS_STRIDED_AXPY, TS_STRIDED_FMA,
    TS_STRIDED_COPY, TS_STRIDED_FILL, TS_STRIDED_SWAP
};
enum {
    TS_STRIDED_SUM, TS_STRIDED_DOT, TS_STRIDED_DOTC, TS_STRIDED_ASUM,
    TS_STRIDED_PROD, TS_STRIDED_ARGMIN, TS_STRIDED_ARGMAX, TS_STRIDED_IAMAX,
    TS_STRIDED_NRM2, TS_STRIDED_COUNT, TS_STRIDED_ANY, TS_STRIDED_ALL
};
#define TS_STRIDED_TILE 16
static const size_t ts_strided_sizes[] = {4, 8, 1, 1, 2, 2, 4, 4, 8, 8, 8, 16, 2, 2};

#define TS_STRIDED_TRANSFER(size) \
    case size: \
        for (size_t i = 0; i < n; ++i) \
            memcpy((char *)out + (int64_t)i * destination_step * size, \
                   (const char *)input + (int64_t)i * input_step * size, size); \
        break;
static void ts_strided_transfer(void *out, const void *input, int64_t destination_step,
                                 int64_t input_step, size_t bytes, size_t n) {
    if (destination_step == 1 && input_step == 1) { memcpy(out, input, n * bytes); return; }
    switch (bytes) {
        TS_STRIDED_TRANSFER(1) TS_STRIDED_TRANSFER(2) TS_STRIDED_TRANSFER(4)
        TS_STRIDED_TRANSFER(8) TS_STRIDED_TRANSFER(16)
    }
}
#undef TS_STRIDED_TRANSFER
static void ts_strided_load(void *out, const void *input, int64_t step, size_t bytes, size_t n) {
    ts_strided_transfer(out, input, 1, step, bytes, n);
}
static void ts_strided_store(void *out, const void *input, int64_t step, size_t bytes, size_t n) {
    ts_strided_transfer(out, input, step, 1, bytes, n);
}

#define TS_STRIDED_INTEGER_BINARY(suffix, type) \
static int ts_strided_binary_##suffix(unsigned op, type *out, const type *a, const type *b, \
                                       type av, type bv, size_t n) { \
    if (a && b) return ts_binary_##suffix(op, out, a, b, n); \
    return ts_bulk_binary_##suffix(op, out, a, b, av, bv, n); \
}
TS_STRIDED_INTEGER_BINARY(s8, uint8_t) TS_STRIDED_INTEGER_BINARY(u8, uint8_t)
TS_STRIDED_INTEGER_BINARY(s16, uint16_t) TS_STRIDED_INTEGER_BINARY(u16, uint16_t)
TS_STRIDED_INTEGER_BINARY(s32, uint32_t) TS_STRIDED_INTEGER_BINARY(u32, uint32_t)
TS_STRIDED_INTEGER_BINARY(s64, uint64_t) TS_STRIDED_INTEGER_BINARY(u64, uint64_t)
#undef TS_STRIDED_INTEGER_BINARY

#define TS_STRIDED_INTEGER_EXTENDED(suffix, type, binary) \
static int ts_strided_extended_##suffix(unsigned op, void *const *p, size_t n) { \
    type zero[TS_STRIDED_TILE] = {0}, temporary[TS_STRIDED_TILE]; \
    uint8_t mask[TS_STRIDED_TILE]; \
    if (op == TS_ND_NEGATE || op == TS_ND_ABS) { \
        binary(TS_OP_SUBTRACT, (void *)temporary, (const void *)zero, p[1], 0, 0, n); \
        if (op == TS_ND_NEGATE) { memcpy(p[0], (void *)temporary, n * sizeof(type)); return 0; } \
        ts_extended_compare_##suffix(2, mask, p[1], (const void *)zero, 0, 0, n); \
        return ts_extended_select_##suffix(p[0], mask, (void *)temporary, p[1], 0, 0, n); \
    } \
    if (op == TS_ND_MIN || op == TS_ND_MAX) { \
        ts_extended_compare_##suffix(op == TS_ND_MIN ? 2 : 4, mask, p[2], p[1], 0, 0, n); \
        return ts_extended_select_##suffix(p[0], mask, p[2], p[1], 0, 0, n); \
    } \
    ts_extended_compare_##suffix(4, mask, p[2], p[3], 0, 0, n); \
    for (size_t i = 0; i < n; ++i) if (mask[i]) return -2; \
    ts_extended_compare_##suffix(2, mask, p[1], p[2], 0, 0, n); \
    ts_extended_select_##suffix((void *)temporary, mask, p[2], p[1], 0, 0, n); \
    ts_extended_compare_##suffix(4, mask, (void *)temporary, p[3], 0, 0, n); \
    return ts_extended_select_##suffix(p[0], mask, p[3], (void *)temporary, 0, 0, n); \
}
static int ts_strided_extended_f32(unsigned op, void *const *p, size_t n) {
    const int64_t steps[] = {1, 1, 1, 1}; return ts_nd_row_f32(op, p, steps, n, 0);
}
static int ts_strided_extended_f64(unsigned op, void *const *p, size_t n) {
    const int64_t steps[] = {1, 1, 1, 1}; return ts_nd_row_f64(op, p, steps, n, 0);
}
#define TS_STRIDED_ROW(suffix, type, binary) \
static int ts_strided_row_##suffix(unsigned op, void *const *p, size_t n, unsigned cmp) { \
    const int64_t steps[] = {1, 1, 1, 1}; \
    if (op == TS_ND_NEGATE || op == TS_ND_ABS || op == TS_ND_MIN || op == TS_ND_MAX || op == TS_ND_CLAMP) \
        return ts_strided_extended_##suffix(op, p, n); \
    if (op <= TS_ND_SELECT) return ts_nd_row_##suffix(op, p, steps, n, cmp); \
    if (op == TS_STRIDED_SCALE) return binary(TS_OP_MULTIPLY, p[0], p[0], p[1], 0, 0, n); \
    if (op == TS_STRIDED_AXPY) { type products[TS_STRIDED_TILE]; \
        binary(TS_OP_MULTIPLY, products, p[1], p[2], 0, 0, n); \
        return binary(TS_OP_ADD, p[0], products, p[0], 0, 0, n); } \
    return -1; \
}
static int ts_strided_binary_f32(unsigned op, float *out, const float *a, const float *b,
                                  float av, float bv, size_t n) {
    ts_bulk_binary_f32(op - TS_OP_ADD, out, a, b, av, bv, n); return 0;
}
static int ts_strided_binary_f64(unsigned op, double *out, const double *a, const double *b,
                                  double av, double bv, size_t n) {
    ts_bulk_binary_f64(op - TS_OP_ADD, out, a, b, av, bv, n); return 0;
}
TS_STRIDED_ROW(f32, float, ts_strided_binary_f32)
TS_STRIDED_ROW(f64, double, ts_strided_binary_f64)
TS_STRIDED_INTEGER_EXTENDED(s8, uint8_t, ts_strided_binary_s8)
TS_STRIDED_ROW(s8, uint8_t, ts_strided_binary_s8)
TS_STRIDED_INTEGER_EXTENDED(u8, uint8_t, ts_strided_binary_u8)
TS_STRIDED_ROW(u8, uint8_t, ts_strided_binary_u8)
TS_STRIDED_INTEGER_EXTENDED(s16, uint16_t, ts_strided_binary_s16)
TS_STRIDED_ROW(s16, uint16_t, ts_strided_binary_s16)
TS_STRIDED_INTEGER_EXTENDED(u16, uint16_t, ts_strided_binary_u16)
TS_STRIDED_ROW(u16, uint16_t, ts_strided_binary_u16)
TS_STRIDED_INTEGER_EXTENDED(s32, uint32_t, ts_strided_binary_s32)
TS_STRIDED_ROW(s32, uint32_t, ts_strided_binary_s32)
TS_STRIDED_INTEGER_EXTENDED(u32, uint32_t, ts_strided_binary_u32)
TS_STRIDED_ROW(u32, uint32_t, ts_strided_binary_u32)
TS_STRIDED_INTEGER_EXTENDED(s64, uint64_t, ts_strided_binary_s64)
TS_STRIDED_ROW(s64, uint64_t, ts_strided_binary_s64)
TS_STRIDED_INTEGER_EXTENDED(u64, uint64_t, ts_strided_binary_u64)
TS_STRIDED_ROW(u64, uint64_t, ts_strided_binary_u64)
#undef TS_STRIDED_ROW
#undef TS_STRIDED_INTEGER_EXTENDED


#include "strided-memory.h"

#define TS_STRIDED_INPUT(suffix, pointer, step, safe) \
    ts_strided_load_##suffix(pointer + (int64_t)i * step, step, n - i, i, specialized, safe)
#define TS_STRIDED_FLOAT_LOOP(suffix, width, vector, expression) \
    for (; n - i >= width; i += width) { \
        vector result = expression; \
        ts_strided_store_##suffix(out + (int64_t)i * s[0], s[0], result, specialized); \
    }

#define TS_STRIDED_FLOAT(suffix, type, width, vector, load, store, splat, add, sub, mul, div, neg, absv, minv, maxv, fused, mode, selected) \
static int ts_strided_float_##suffix##_##mode(unsigned op, void *const *p, const int64_t *s, size_t n) { \
    type *out = p[0]; const type *a = p[1], *b = p[2], *c = p[3]; size_t i = 0; \
    const int specialized = selected; \
    int64_t steps[] = {s[0], s[1], s[2], s[3]}; s = steps; \
    int safe_a = specialized && ts_strided_memory_disjoint(a, s[1], out, s[0], sizeof(type), n); \
    int safe_b = specialized && ts_strided_memory_disjoint(b, s[2], out, s[0], sizeof(type), n); \
    int safe_c = specialized && ts_strided_memory_disjoint(c, s[3], out, s[0], sizeof(type), n); \
    switch (op) { \
    case TS_ND_ADD: TS_STRIDED_FLOAT_LOOP(suffix, width, vector, add(TS_STRIDED_INPUT(suffix, a, s[1], safe_a), TS_STRIDED_INPUT(suffix, b, s[2], safe_b))); break; \
    case TS_ND_SUBTRACT: TS_STRIDED_FLOAT_LOOP(suffix, width, vector, sub(TS_STRIDED_INPUT(suffix, a, s[1], safe_a), TS_STRIDED_INPUT(suffix, b, s[2], safe_b))); break; \
    case TS_ND_MULTIPLY: TS_STRIDED_FLOAT_LOOP(suffix, width, vector, mul(TS_STRIDED_INPUT(suffix, a, s[1], safe_a), TS_STRIDED_INPUT(suffix, b, s[2], safe_b))); break; \
    case TS_ND_DIVIDE: TS_STRIDED_FLOAT_LOOP(suffix, width, vector, div(TS_STRIDED_INPUT(suffix, a, s[1], safe_a), TS_STRIDED_INPUT(suffix, b, s[2], safe_b))); break; \
    case TS_ND_NEGATE: TS_STRIDED_FLOAT_LOOP(suffix, width, vector, neg(TS_STRIDED_INPUT(suffix, a, s[1], safe_a))); break; \
    case TS_ND_ABS: TS_STRIDED_FLOAT_LOOP(suffix, width, vector, absv(TS_STRIDED_INPUT(suffix, a, s[1], safe_a))); break; \
    case TS_ND_MIN: TS_STRIDED_FLOAT_LOOP(suffix, width, vector, minv(TS_STRIDED_INPUT(suffix, a, s[1], safe_a), TS_STRIDED_INPUT(suffix, b, s[2], safe_b))); break; \
    case TS_ND_MAX: TS_STRIDED_FLOAT_LOOP(suffix, width, vector, maxv(TS_STRIDED_INPUT(suffix, a, s[1], safe_a), TS_STRIDED_INPUT(suffix, b, s[2], safe_b))); break; \
    case TS_STRIDED_SCALE: TS_STRIDED_FLOAT_LOOP(suffix, width, vector, mul(TS_STRIDED_INPUT(suffix, out, s[0], 0), TS_STRIDED_INPUT(suffix, a, s[1], safe_a))); break; \
    case TS_STRIDED_AXPY: TS_STRIDED_FLOAT_LOOP(suffix, width, vector, add(mul(TS_STRIDED_INPUT(suffix, a, s[1], safe_a), TS_STRIDED_INPUT(suffix, b, s[2], safe_b)), TS_STRIDED_INPUT(suffix, out, s[0], 0))); break; \
    case TS_STRIDED_FMA: TS_STRIDED_FLOAT_LOOP(suffix, width, vector, fused(TS_STRIDED_INPUT(suffix, a, s[1], safe_a), TS_STRIDED_INPUT(suffix, b, s[2], safe_b), TS_STRIDED_INPUT(suffix, c, s[3], safe_c))); break; \
    default: return -1; \
    } \
    if (i < n) { \
        type values[4][width]; void *q[4] = {values[0], values[1], values[2], values[3]}; \
        size_t count = n - i; \
        for (size_t operand = 0; operand < 4; ++operand) { \
            if (!p[operand]) { q[operand] = NULL; continue; } \
            if (operand || op == TS_STRIDED_SCALE || op == TS_STRIDED_AXPY) \
                ts_strided_load(q[operand], (type *)p[operand] + (int64_t)i * s[operand], s[operand], sizeof(type), count); \
        } \
        if (op == TS_STRIDED_FMA) ts_bulk_fma_##suffix(q[0], q[1], q[2], q[3], 0, 0, 0, count); \
        else { int status = ts_strided_row_##suffix(op, q, count, 0); if (status) return status; } \
        ts_strided_store(out + (int64_t)i * s[0], q[0], s[0], sizeof(type), count); \
    } \
    return 0; \
}
#define TS_STRIDED_FLOAT_TYPE(suffix, type, width, vector, load, store, splat, add, sub, mul, div, neg, absv, minv, maxv, fused) \
    TS_STRIDED_FLOAT(suffix, type, width, vector, load, store, splat, add, sub, mul, div, neg, absv, minv, maxv, fused, general, 0) \
    TS_STRIDED_FLOAT(suffix, type, width, vector, load, store, splat, add, sub, mul, div, neg, absv, minv, maxv, fused, packed, 1) \
static int ts_strided_float_##suffix(unsigned op, void *const *p, const int64_t *s, size_t n) { \
    if (ts_strided_memory_enabled(op, sizeof(type) == 8, n, s)) \
        return ts_strided_float_##suffix##_packed(op, p, s, n); \
    return ts_strided_float_##suffix##_general(op, p, s, n); \
}
TS_STRIDED_FLOAT_TYPE(f32, float, TS_F32_WIDTH, TS_F32_VECTOR, TS_F32_LOAD, TS_F32_STORE, TS_F32_SPLAT,
                 TS_F32_ADD, TS_F32_SUB, TS_F32_MUL, TS_F32_DIV, TS_F32_NEGATE, TS_F32_ABS, TS_F32_MIN, TS_F32_MAX, TS_F32_FMA)
TS_STRIDED_FLOAT_TYPE(f64, double, TS_F64_WIDTH, TS_F64_VECTOR, TS_F64_LOAD, TS_F64_STORE, TS_F64_SPLAT,
                 TS_F64_ADD, TS_F64_SUB, TS_F64_MUL, TS_F64_DIV, TS_F64_NEGATE, TS_F64_ABS, TS_F64_MIN, TS_F64_MAX, TS_F64_FMA)
#undef TS_STRIDED_FLOAT_TYPE
#undef TS_STRIDED_FLOAT
#undef TS_STRIDED_FLOAT_LOOP
#undef TS_STRIDED_INPUT

uint64_t ts_strided_mask_reduce(unsigned, const uint8_t *, size_t, int64_t);
int ts_extended_conversion_supported(unsigned, unsigned);
int ts_extended_convert_numeric(void *, const void *, size_t, unsigned, unsigned);
void ts_extended_convert_encoded(void *, const void *, size_t, unsigned, unsigned, int);
void ts_complex_binary_c32(unsigned, float *, const float *, const float *, size_t);
void ts_complex_binary_c64(unsigned, double *, const double *, const double *, size_t);

int ts_strided_execute(unsigned op, unsigned type, unsigned destination_type, unsigned input_type,
                       unsigned comparison, int rounding, size_t n, const int64_t *steps, void *const *p) {
    typedef int (*row)(unsigned, void *const *, size_t, unsigned);
    static const row functions[] = {ts_strided_row_f32, ts_strided_row_f64, ts_strided_row_s8,
        ts_strided_row_u8, ts_strided_row_s16, ts_strided_row_u16, ts_strided_row_s32,
        ts_strided_row_u32, ts_strided_row_s64, ts_strided_row_u64};
    if (op > TS_STRIDED_SWAP || type >= 12 || destination_type >= 14 || input_type >= 14 ||
        comparison > 5 || rounding < 0 || rounding > 3) return -1;
    if (!n) return 0;
    if (!p[0] || !p[1] || !steps[0] ||
        ((op < TS_ND_NEGATE || op == TS_ND_MIN || op == TS_ND_MAX ||
          op == TS_ND_COMPARE || op == TS_ND_SELECT || op == TS_ND_CLAMP ||
          op == TS_STRIDED_AXPY || op == TS_STRIDED_FMA) && !p[2]) ||
        ((op == TS_ND_CLAMP || op == TS_ND_SELECT || op == TS_STRIDED_FMA) && !p[3])) return -1;
    if (type >= 10 && op > 2 && op < TS_STRIDED_COPY && op != TS_STRIDED_SCALE && op != TS_STRIDED_AXPY) return -1;
    if (op == TS_STRIDED_FMA && type > 1) return -1;
    if (op == TS_ND_CONVERT && destination_type < 12 && input_type < 12 &&
        !(destination_type < 2 && input_type < 2) &&
        !ts_extended_conversion_supported(destination_type, input_type)) return -1;
    if (type < 2 && (op <= TS_ND_ABS || op == TS_ND_MIN || op == TS_ND_MAX ||
                     op == TS_STRIDED_SCALE || op == TS_STRIDED_AXPY || op == TS_STRIDED_FMA))
        return type == 0 ? ts_strided_float_f32(op, p, steps, n) : ts_strided_float_f64(op, p, steps, n);
    size_t bytes[4] = {ts_strided_sizes[type], ts_strided_sizes[type],
                      ts_strided_sizes[type], ts_strided_sizes[type]};
    if (op == TS_ND_COMPARE) bytes[0] = 1;
    if (op == TS_ND_SELECT) bytes[1] = 1;
    if (op == TS_ND_CONVERT) {
        bytes[0] = ts_strided_sizes[destination_type]; bytes[1] = ts_strided_sizes[input_type];
        if ((destination_type >= 12 || input_type >= 12) &&
            !((destination_type < 2 || destination_type >= 12) && (input_type < 2 || input_type >= 12))) return -1;
    }
    for (size_t start = 0; start < n;) {
        size_t count = n - start < TS_STRIDED_TILE ? n - start : TS_STRIDED_TILE;
        union { double align; unsigned char bytes[TS_STRIDED_TILE * 16]; } buffers[4];
        void *q[4] = {buffers[0].bytes, buffers[1].bytes, buffers[2].bytes, buffers[3].bytes};
        for (size_t operand = 1; operand < 4; ++operand) {
            if (!p[operand]) { q[operand] = NULL; continue; }
            ts_strided_load(q[operand], (char *)p[operand] + (int64_t)start * steps[operand] * (int64_t)bytes[operand],
                            steps[operand], bytes[operand], count);
        }
        void *out = (char *)p[0] + (int64_t)start * steps[0] * (int64_t)bytes[0];
        if (op == TS_STRIDED_SCALE || op == TS_STRIDED_AXPY || op == TS_STRIDED_SWAP)
            ts_strided_load(q[0], out, steps[0], bytes[0], count);
        int status = 0;
        if (op >= TS_STRIDED_COPY) {
            memcpy(q[0], q[1], count * bytes[0]);
            if (op == TS_STRIDED_SWAP) {
                q[2] = buffers[2].bytes;
                ts_strided_load(q[2], out, steps[0], bytes[0], count);
                ts_strided_store((char *)p[1] + (int64_t)start * steps[1] * (int64_t)bytes[1],
                                 q[2], steps[1], bytes[1], count);
            }
        } else if (op == TS_ND_CONVERT) {
            if (destination_type >= 12 || input_type >= 12)
                ts_extended_convert_encoded(q[0], q[1], count,
                                            destination_type >= 12 ? destination_type - 10 : destination_type,
                                            input_type >= 12 ? input_type - 10 : input_type, rounding);
            else if (destination_type < 2 && input_type < 2)
                ts_nd_convert(q[0], q[1], count, 1, 1, destination_type, input_type, rounding);
            else status = ts_extended_convert_numeric(q[0], q[1], count, destination_type, input_type);
        } else if (type >= 10) {
            unsigned binary_op = op == TS_STRIDED_SCALE || op == TS_STRIDED_AXPY ? 2 : op;
            if (type == 10) ts_complex_binary_c32(binary_op, q[0], op == TS_STRIDED_SCALE ? q[0] : q[1],
                                                 op == TS_STRIDED_SCALE ? q[1] : q[2], count);
            else ts_complex_binary_c64(binary_op, q[0], op == TS_STRIDED_SCALE ? q[0] : q[1],
                                        op == TS_STRIDED_SCALE ? q[1] : q[2], count);
            if (op == TS_STRIDED_AXPY) {
                ts_strided_load(q[2], out, steps[0], bytes[0], count);
                if (type == 10) ts_complex_binary_c32(0, q[0], q[0], q[2], count);
                else ts_complex_binary_c64(0, q[0], q[0], q[2], count);
            }
        } else if (op == TS_STRIDED_FMA) {
            if (type == 0) ts_bulk_fma_f32(q[0], q[1], q[2], q[3], 0, 0, 0, count);
            else ts_bulk_fma_f64(q[0], q[1], q[2], q[3], 0, 0, 0, count);
        } else status = functions[type](op, q, count, comparison);
        if (status) return status;
        ts_strided_store(out, q[0], steps[0], bytes[0], count);
        start += count;
    }
    return 0;
}

#define TS_STRIDED_REDUCE_LOAD(suffix, type) \
static void ts_strided_reduce_load_##suffix(type *out, const type *p, int64_t step, \
                                            size_t remaining, size_t processed, int specialized) { \
    TS_##suffix##_STORE(out, ts_strided_load_##suffix(p, step, remaining, processed, specialized, 1)); \
}
#define TS_f32_STORE TS_F32_STORE
#define TS_f64_STORE TS_F64_STORE
TS_STRIDED_REDUCE_LOAD(f32, float)
TS_STRIDED_REDUCE_LOAD(f64, double)
#undef TS_STRIDED_REDUCE_LOAD
#undef TS_f32_STORE
#undef TS_f64_STORE
#define TS_STRIDED_INTEGER_LOAD(suffix, type, width) \
static void ts_strided_reduce_load_##suffix(type *out, const type *p, int64_t step, \
                                            size_t remaining, size_t processed, int specialized) { \
    (void)remaining; (void)processed; (void)specialized; \
    ts_strided_load(out, p, step, sizeof(type), width); \
}
TS_STRIDED_INTEGER_LOAD(s8, int8_t, 16) TS_STRIDED_INTEGER_LOAD(u8, uint8_t, 16)
TS_STRIDED_INTEGER_LOAD(s16, int16_t, 8) TS_STRIDED_INTEGER_LOAD(u16, uint16_t, 8)
TS_STRIDED_INTEGER_LOAD(s32, int32_t, 4) TS_STRIDED_INTEGER_LOAD(u32, uint32_t, 4)
TS_STRIDED_INTEGER_LOAD(s64, int64_t, 2) TS_STRIDED_INTEGER_LOAD(u64, uint64_t, 2)
#undef TS_STRIDED_INTEGER_LOAD

#define TS_STRIDED_REDUCE(suffix, type, bits_type, width, binary, abs_value, less, greater, memory_type) \
static int ts_strided_reduce_##suffix(unsigned op, const type *a, const type *b, size_t n, \
                                      int64_t as, int64_t bs, void *result, double *wide_result, \
                                      uint64_t *index, int wide) { \
    if (op == TS_STRIDED_NRM2 || op == TS_STRIDED_DOTC) return -1; \
    type lanes[width], x[width], y[width], best = 0; \
    double wide_lanes[4] = {0}; \
    size_t winning = 0, start = 0; \
    int64_t memory_steps[] = {1, as, op == TS_STRIDED_DOT ? bs : 1, 1}; \
    int specialized = (op == TS_STRIDED_SUM || op == TS_STRIDED_DOT) && \
        ts_strided_memory_enabled(32 + op + (wide ? 64 : 0), memory_type, n, memory_steps); \
    for (size_t j = 0; j < width; ++j) lanes[j] = op == TS_STRIDED_PROD ? 1 : 0; \
    if (op >= TS_STRIDED_ARGMIN) { \
        if (!n) { *index = 0; return 0; } \
        best = op == TS_STRIDED_IAMAX ? abs_value(a[0]) : a[0]; \
        for (size_t i = 1; i < n;) { \
            size_t count = n - i < width ? n - i : width; \
            uint8_t mask[width]; \
            ts_strided_load(x, a + (int64_t)i * as, as, sizeof(type), count); \
            for (size_t j = 0; j < count; ++j) { \
                if (op == TS_STRIDED_IAMAX) x[j] = abs_value(x[j]); \
                y[j] = best; \
            } \
            ts_extended_compare_##suffix(op == TS_STRIDED_ARGMIN ? 2 : 4, mask, x, y, 0, 0, count); \
            for (size_t j = 0; j < count; ++j) if (mask[j] && \
                (op == TS_STRIDED_ARGMIN ? less(x[j], best) : greater(x[j], best))) { \
                best = x[j]; winning = i + j; \
            } \
            i += count; \
        } \
        *index = winning; memcpy(result, &best, sizeof best); return 0; \
    } \
    if (wide) { \
        for (; n - start >= 4; start += 4) { \
            double wx[4], wy[4]; \
            float packed_x[4], packed_y[4]; \
            if (specialized) { \
                TS_F32_STORE(packed_x, ts_strided_load_f32((const float *)a + (int64_t)start * as, as, n - start, start, 1, 1)); \
                if (op == TS_STRIDED_DOT) \
                    TS_F32_STORE(packed_y, ts_strided_load_f32((const float *)b + (int64_t)start * bs, bs, n - start, start, 1, 1)); \
            } \
            for (size_t j = 0; j < 4; ++j) { \
                wx[j] = specialized ? packed_x[j] : a[(int64_t)(start + j) * as]; \
                if (op == TS_STRIDED_DOT) wy[j] = specialized ? packed_y[j] : b[(int64_t)(start + j) * bs]; \
                else if (op == TS_STRIDED_ASUM) wx[j] = fabs(wx[j]); \
            } \
            if (op == TS_STRIDED_DOT) ts_strided_binary_f64(TS_OP_MULTIPLY, wx, wx, wy, 0, 0, 4); \
            ts_strided_binary_f64(TS_OP_ADD, wide_lanes, wide_lanes, wx, 0, 0, 4); \
        } \
        double total = (wide_lanes[0] + wide_lanes[1]) + wide_lanes[2] + wide_lanes[3]; \
        for (; start < n; ++start) { \
            double term = a[(int64_t)start * as]; \
            if (op == TS_STRIDED_DOT) term *= (double)b[(int64_t)start * bs]; \
            else if (op == TS_STRIDED_ASUM) term = fabs(term); \
            total += term; \
        } \
        *wide_result = total; return 0; \
    } \
    for (; n - start >= width; start += width) { \
        ts_strided_reduce_load_##suffix(x, a + (int64_t)start * as, as, n - start, start, specialized); \
        if (op == TS_STRIDED_DOT) { \
            ts_strided_reduce_load_##suffix(y, b + (int64_t)start * bs, bs, n - start, start, specialized); \
            binary(TS_OP_MULTIPLY, (bits_type *)x, (const bits_type *)x, (const bits_type *)y, 0, 0, width); \
        } else if (op == TS_STRIDED_ASUM) { \
            void *p[] = {x, x, NULL, NULL}; ts_strided_extended_##suffix(TS_ND_ABS, p, width); \
        } \
        binary(op == TS_STRIDED_PROD ? TS_OP_MULTIPLY : TS_OP_ADD, (bits_type *)lanes, \
               (const bits_type *)lanes, (const bits_type *)x, 0, 0, width); \
    } \
    type value = op == TS_STRIDED_PROD ? 1 : 0; \
    for (size_t j = 0; j < width; ++j) \
        binary(op == TS_STRIDED_PROD ? TS_OP_MULTIPLY : TS_OP_ADD, (bits_type *)&value, \
               (const bits_type *)&value, (const bits_type *)&lanes[j], 0, 0, 1); \
    for (; start < n; ++start) { \
        type term = a[(int64_t)start * as]; \
        if (op == TS_STRIDED_DOT) { type right = b[(int64_t)start * bs]; \
            binary(TS_OP_MULTIPLY, (bits_type *)&term, (const bits_type *)&term, (const bits_type *)&right, 0, 0, 1); } \
        else if (op == TS_STRIDED_ASUM) term = abs_value(term); \
        binary(op == TS_STRIDED_PROD ? TS_OP_MULTIPLY : TS_OP_ADD, (bits_type *)&value, \
               (const bits_type *)&value, (const bits_type *)&term, 0, 0, 1); \
    } \
    memcpy(result, &value, sizeof value); return 0; \
}
TS_STRIDED_REDUCE(f32, float, float, TS_F32_WIDTH, ts_strided_binary_f32, fabsf, ts_reduce_less_f32, ts_reduce_greater_f32, 0)
TS_STRIDED_REDUCE(f64, double, double, TS_F64_WIDTH, ts_strided_binary_f64, fabs, ts_reduce_less_f64, ts_reduce_greater_f64, 1)
TS_STRIDED_REDUCE(s8, int8_t, uint8_t, 16, ts_strided_binary_s8, ts_reduce_abs_s8, ts_reduce_less_s8, ts_reduce_greater_s8, 2)
TS_STRIDED_REDUCE(u8, uint8_t, uint8_t, 16, ts_strided_binary_u8, ts_reduce_abs_u8, ts_reduce_less_u8, ts_reduce_greater_u8, 2)
TS_STRIDED_REDUCE(s16, int16_t, uint16_t, 8, ts_strided_binary_s16, ts_reduce_abs_s16, ts_reduce_less_s16, ts_reduce_greater_s16, 2)
TS_STRIDED_REDUCE(u16, uint16_t, uint16_t, 8, ts_strided_binary_u16, ts_reduce_abs_u16, ts_reduce_less_u16, ts_reduce_greater_u16, 2)
TS_STRIDED_REDUCE(s32, int32_t, uint32_t, 4, ts_strided_binary_s32, ts_reduce_abs_s32, ts_reduce_less_s32, ts_reduce_greater_s32, 2)
TS_STRIDED_REDUCE(u32, uint32_t, uint32_t, 4, ts_strided_binary_u32, ts_reduce_abs_u32, ts_reduce_less_u32, ts_reduce_greater_u32, 2)
TS_STRIDED_REDUCE(s64, int64_t, uint64_t, 2, ts_strided_binary_s64, ts_reduce_abs_s64, ts_reduce_less_s64, ts_reduce_greater_s64, 2)
TS_STRIDED_REDUCE(u64, uint64_t, uint64_t, 2, ts_strided_binary_u64, ts_reduce_abs_u64, ts_reduce_less_u64, ts_reduce_greater_u64, 2)
#undef TS_STRIDED_REDUCE


#define TS_STRIDED_NORM(suffix, type) \
static double ts_strided_norm_##suffix(const type *a, size_t n, int64_t step) { \
    double largest = 0, lanes[4] = {0}, sum = 0; \
    size_t width = sizeof(type) == sizeof(float) ? 4 : TS_F64_WIDTH; \
    fenv_t fast_environment; feholdexcept(&fast_environment); \
    size_t start = 0; \
    for (; n - start >= width; start += width) { \
        double x[4] = {0}; \
        for (size_t j = 0; j < width; ++j) x[j] = a[(int64_t)(start + j) * step]; \
        ts_strided_binary_f64(TS_OP_MULTIPLY, x, x, x, 0, 0, width); \
        ts_strided_binary_f64(TS_OP_ADD, lanes, lanes, x, 0, 0, width); \
    } \
    for (size_t j = 0; j < width; ++j) sum += lanes[j]; \
    for (; start < n; ++start) { double x = a[(int64_t)start * step]; sum += x * x; } \
    fesetenv(&fast_environment); \
    if (sizeof(type) == sizeof(float) || (sum >= 1e-280 && isfinite(sum))) return sqrt(sum); \
    memset(lanes, 0, sizeof lanes); \
    for (size_t i = 0; i < n; ++i) { \
        double value = fabs((double)a[(int64_t)i * step]); \
        if (!isfinite(value)) return value; \
        if (value > largest) largest = value; \
    } \
    if (!largest) return 0; \
    fenv_t environment; feholdexcept(&environment); \
    for (size_t i = 0; i < n; i += 4) { \
        double x[4] = {0}; size_t count = n - i < 4 ? n - i : 4; \
        for (size_t j = 0; j < count; ++j) x[j] = (double)a[(int64_t)(i + j) * step] / largest; \
        ts_strided_binary_f64(TS_OP_MULTIPLY, x, x, x, 0, 0, 4); \
        ts_strided_binary_f64(TS_OP_ADD, lanes, lanes, x, 0, 0, 4); \
    } \
    double norm = sqrt((lanes[0] + lanes[1]) + lanes[2] + lanes[3]); \
    fesetenv(&environment); return largest * norm; \
}
TS_STRIDED_NORM(f32, float)
TS_STRIDED_NORM(f64, double)
#undef TS_STRIDED_NORM

#define TS_STRIDED_COMPLEX_REDUCE(suffix, type, width, binary, complex_binary) \
static void ts_strided_complex_reduce_##suffix(unsigned op, const type *a, const type *b, size_t n, \
                                               int64_t as, int64_t bs, type *out) { \
    type lanes[2 * width] = {0}, x[2 * width], y[2 * width]; \
    if (op == TS_STRIDED_PROD) for (size_t j = 0; j < width; ++j) lanes[2 * j] = 1; \
    size_t i = 0; \
    for (; n - i >= width; i += width) { \
        ts_strided_load(x, a + 2 * (int64_t)i * as, as, 2 * sizeof(type), width); \
        if (op == TS_STRIDED_DOT || op == TS_STRIDED_DOTC) { \
            ts_strided_load(y, b + 2 * (int64_t)i * bs, bs, 2 * sizeof(type), width); \
            if (op == TS_STRIDED_DOTC) for (size_t j = 0; j < width; ++j) x[2 * j + 1] = -x[2 * j + 1]; \
            complex_binary(2, x, x, y, width); \
        } \
        if (op == TS_STRIDED_PROD) complex_binary(2, lanes, lanes, x, width); \
        else binary(0, lanes, lanes, x, 0, 0, 2 * width); \
    } \
    type value[2] = {op == TS_STRIDED_PROD ? 1 : 0, 0}; \
    for (size_t j = 0; j < width; ++j) \
        if (op == TS_STRIDED_PROD) complex_binary(2, value, value, lanes + 2 * j, 1); \
        else binary(0, value, value, lanes + 2 * j, 0, 0, 2); \
    for (; i < n; ++i) { \
        memcpy(x, a + 2 * (int64_t)i * as, 2 * sizeof(type)); \
        if (op == TS_STRIDED_DOT || op == TS_STRIDED_DOTC) { \
            memcpy(y, b + 2 * (int64_t)i * bs, 2 * sizeof(type)); \
            if (op == TS_STRIDED_DOTC) x[1] = -x[1]; \
            complex_binary(2, x, x, y, 1); \
        } \
        if (op == TS_STRIDED_PROD) complex_binary(2, value, value, x, 1); \
        else binary(0, value, value, x, 0, 0, 2); \
    } \
    memcpy(out, value, sizeof value); \
}
TS_STRIDED_COMPLEX_REDUCE(c32, float, 4, ts_bulk_binary_f32, ts_complex_binary_c32)
TS_STRIDED_COMPLEX_REDUCE(c64, double, 2, ts_bulk_binary_f64, ts_complex_binary_c64)
#undef TS_STRIDED_COMPLEX_REDUCE

static void ts_strided_complex_wide(const float *a, const float *b, size_t n, int64_t as, int64_t bs,
                                     unsigned op, double *out) {
    double lanes[8] = {0};
    size_t i = 0;
    for (; n - i >= 4; i += 4) {
        double x[8], y[8];
        for (size_t j = 0; j < 4; ++j) {
            x[2 * j] = a[2 * (int64_t)(i + j) * as];
            x[2 * j + 1] = a[2 * (int64_t)(i + j) * as + 1];
            if (op == TS_STRIDED_DOT || op == TS_STRIDED_DOTC) {
                y[2 * j] = b[2 * (int64_t)(i + j) * bs];
                y[2 * j + 1] = b[2 * (int64_t)(i + j) * bs + 1];
                if (op == TS_STRIDED_DOTC) x[2 * j + 1] = -x[2 * j + 1];
            }
        }
        if (op == TS_STRIDED_DOT || op == TS_STRIDED_DOTC) ts_complex_binary_c64(2, x, x, y, 4);
        ts_bulk_binary_f64(0, lanes, lanes, x, 0, 0, 8);
    }
    out[0] = out[1] = 0;
    for (size_t j = 0; j < 4; ++j) { out[0] += lanes[2 * j]; out[1] += lanes[2 * j + 1]; }
    for (; i < n; ++i) {
        double x[2] = {a[2 * (int64_t)i * as], a[2 * (int64_t)i * as + 1]};
        if (op == TS_STRIDED_DOT || op == TS_STRIDED_DOTC) {
            double y[2] = {b[2 * (int64_t)i * bs], b[2 * (int64_t)i * bs + 1]};
            if (op == TS_STRIDED_DOTC) x[1] = -x[1];
            ts_complex_binary_c64(2, x, x, y, 1);
        }
        out[0] += x[0]; out[1] += x[1];
    }
}

int ts_strided_reduce(unsigned op, unsigned type, size_t n, const void *a, const void *b,
                      int64_t as, int64_t bs, int wide, void *result, double *wide_result, uint64_t *index) {
    if (op > TS_STRIDED_ALL || type >= 12 || !as || !result || !wide_result || !index ||
        (wide && (type != 0 && type != 10 ||
                  (op != TS_STRIDED_SUM && op != TS_STRIDED_DOT && op != TS_STRIDED_DOTC &&
                   op != TS_STRIDED_ASUM && op != TS_STRIDED_NRM2))) || (n && (!a || ((op == TS_STRIDED_DOT || op == TS_STRIDED_DOTC) && (!b || !bs))))) return -1;
    if (type >= 10) {
        if (op != TS_STRIDED_SUM && op != TS_STRIDED_DOT && op != TS_STRIDED_DOTC && op != TS_STRIDED_PROD) return -1;
        if (wide) {
            ts_strided_complex_wide(a, b, n, as, bs, op, wide_result);
        } else if (type == 10) ts_strided_complex_reduce_c32(op, a, b, n, as, bs, result);
        else ts_strided_complex_reduce_c64(op, a, b, n, as, bs, result);
        return 0;
    }
    if (op == TS_STRIDED_NRM2) {
        if (type > 1) return -1;
        *wide_result = type == 0 ? ts_strided_norm_f32(a, n, as) : ts_strided_norm_f64(a, n, as);
        return 0;
    }
    if (op >= TS_STRIDED_COUNT) {
        if (type != 3) return -1;
        uint64_t value = ts_strided_mask_reduce(op - TS_STRIDED_COUNT, a, n, as);
        if (value == UINT64_MAX) return -1;
        *index = value; return 0;
    }
    switch (type) {
#define TS_STRIDED_REDUCE_CASE(code, suffix) \
    case code: return ts_strided_reduce_##suffix(op, a, b, n, as, bs, result, wide_result, index, wide);
        TS_STRIDED_REDUCE_CASE(0, f32) TS_STRIDED_REDUCE_CASE(1, f64)
        TS_STRIDED_REDUCE_CASE(2, s8) TS_STRIDED_REDUCE_CASE(3, u8)
        TS_STRIDED_REDUCE_CASE(4, s16) TS_STRIDED_REDUCE_CASE(5, u16)
        TS_STRIDED_REDUCE_CASE(6, s32) TS_STRIDED_REDUCE_CASE(7, u32)
        TS_STRIDED_REDUCE_CASE(8, s64) TS_STRIDED_REDUCE_CASE(9, u64)
#undef TS_STRIDED_REDUCE_CASE
    }
    return -1;
}
