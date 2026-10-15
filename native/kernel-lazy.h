/* Branch scratch holds the parent mask and its false lanes. Inactive operands
 * are sanitized before packed operations; writes preserve inactive bits. */
static int ts_lazy_validate(const uint8_t *code, size_t length, size_t slots,
                            size_t input_count, void *scratch, size_t element_size) {
    if (!code || length < 4 || length % 4 || code[0] != TS_OP_LAZY) return -4;
    if (slots && !scratch) return -1;
    size_t stride = TS_KERNEL_BLOCK * element_size, current = SIZE_MAX;
    if (slots) memset(scratch, 0, slots * stride);
    for (size_t pc = 4; pc < length; pc += 4) {
        unsigned op = code[pc], dst = code[pc + 1], a = code[pc + 2], b = code[pc + 3];
        size_t slot = a | ((size_t)b << 8);
        if (op == TS_OP_BRANCH || op == TS_OP_ELSE || op == TS_OP_END) {
            if (slot >= slots || slots - slot < 2) return -4;
            unsigned char *frame = (unsigned char *)scratch + slot * stride;
            unsigned char *state = frame + sizeof(size_t);
            if (op == TS_OP_BRANCH) {
                if (*state || dst == TS_KERNEL_OUTPUT || dst >= TS_KERNEL_REGISTERS + input_count) return -4;
                memcpy(frame, &current, sizeof current);
                *state = 1;
                current = slot;
            } else {
                if (slot != current) return -4;
                if (op == TS_OP_ELSE) {
                    if (dst > 1 || *state != dst + 1) return -4;
                    ++*state;
                } else {
                    if (*state != 3) return -4;
                    memcpy(&current, frame, sizeof current);
                    *state = 0;
                }
            }
        } else if (op == TS_OP_SPILL || op == TS_OP_RELOAD) {
            if (slot >= slots || (dst != TS_KERNEL_OUTPUT && dst >= TS_KERNEL_REGISTERS + input_count) ||
                (op == TS_OP_RELOAD && dst != TS_KERNEL_OUTPUT && dst >= TS_KERNEL_REGISTERS)) return -4;
        } else {
            if (op > TS_OP_SIGMOID || (dst != TS_KERNEL_OUTPUT && dst >= TS_KERNEL_REGISTERS)) return -4;
            if (op == TS_OP_CONSTANT) continue;
            if (a >= TS_KERNEL_REGISTERS + input_count) return -4;
            if (((op >= TS_OP_ADD && op <= TS_OP_DIVIDE) || op == TS_OP_MIN || op == TS_OP_MAX ||
                 op == TS_OP_FMA || (op >= TS_OP_EQ && op <= TS_OP_SELECT)) &&
                b >= TS_KERNEL_REGISTERS + input_count) return -4;
        }
    }
    return current == SIZE_MAX ? 0 : -4;
}

#define TS_LAZY_INTEGER_APPLY(suffix, type) \
static int ts_lazy_apply_##suffix(unsigned op, type *out, const type *left, const type *right, size_t n) { \
    if (op == TS_OP_COPY) { if (out != left) memcpy(out, left, n * sizeof(type)); return 0; } \
    if (op == TS_OP_NEGATE || op == TS_OP_ABS) { \
        for (size_t j = 0; j < n; ++j) out[j] = ts_value_##suffix(op, left[j], 0); \
        return 0; \
    } \
    if (op >= TS_OP_EQ && op <= TS_OP_GE) { \
        size_t j = ts_mask_compare_##suffix(op - TS_OP_EQ, out, left, right, 0, 0, n, 0); \
        for (; j < n; ++j) { \
            type x = left[j], y = right[j]; \
            int less = x != y && ts_value_##suffix(TS_OP_MIN, x, y) == x; \
            out[j] = op == TS_OP_EQ ? x == y : op == TS_OP_NE ? x != y : \
                op == TS_OP_LT ? less : op == TS_OP_LE ? (less || x == y) : \
                op == TS_OP_GT ? (!less && x != y) : !less; \
        } \
        return 0; \
    } \
    if ((op >= TS_OP_ADD && op <= TS_OP_DIVIDE) || op == TS_OP_MIN || op == TS_OP_MAX) \
        return ts_binary_##suffix(op, out, left, right, n); \
    return -4; \
}
TS_LAZY_INTEGER_APPLY(s8, uint8_t)
TS_LAZY_INTEGER_APPLY(u8, uint8_t)
TS_LAZY_INTEGER_APPLY(s16, uint16_t)
TS_LAZY_INTEGER_APPLY(u16, uint16_t)
TS_LAZY_INTEGER_APPLY(s32, uint32_t)
TS_LAZY_INTEGER_APPLY(u32, uint32_t)
TS_LAZY_INTEGER_APPLY(s64, uint64_t)
TS_LAZY_INTEGER_APPLY(u64, uint64_t)
#undef TS_LAZY_INTEGER_APPLY

#define TS_LAZY_KERNEL(suffix, type, apply) \
static int ts_lazy_kernel_##suffix(const uint8_t *code, size_t length, const type *constants, \
        const type *const *inputs, type *out, size_t n, size_t slots, type *scratch, size_t input_offset) { \
    if (!length || length % 4 || (slots && !scratch)) return -4; \
    type registers[TS_KERNEL_REGISTERS][TS_KERNEL_BLOCK]; \
    type safe_left[TS_KERNEL_BLOCK], safe_right[TS_KERNEL_BLOCK], result[TS_KERNEL_BLOCK]; \
    uint8_t active[TS_KERNEL_BLOCK]; \
    for (size_t base = 0; base < n; base += TS_KERNEL_BLOCK) { \
        size_t m = n - base < TS_KERNEL_BLOCK ? n - base : TS_KERNEL_BLOCK; \
        memset(active, 1, m); \
        size_t active_count = m; \
        for (size_t pc = 4; pc < length; pc += 4) { \
            unsigned op = code[pc], dst = code[pc + 1], a = code[pc + 2], b = code[pc + 3]; \
            size_t slot = a | ((size_t)b << 8); \
            if (op == TS_OP_BRANCH || op == TS_OP_ELSE || op == TS_OP_END) { \
                if (slot >= slots || slots - slot < 2) return -4; \
                type *parent = scratch + slot * TS_KERNEL_BLOCK, *otherwise = parent + TS_KERNEL_BLOCK; \
                if (op == TS_OP_BRANCH) { \
                    const type *mask = dst < TS_KERNEL_REGISTERS ? registers[dst] : inputs[dst - TS_KERNEL_REGISTERS] + input_offset + base; \
                    for (size_t j = 0; j < m; ++j) { \
                        parent[j] = active[j]; \
                        otherwise[j] = active[j] && mask[j] == 0; \
                        active[j] = active[j] && !otherwise[j]; \
                    } \
                } else for (size_t j = 0; j < m; ++j) \
                    active[j] = op == TS_OP_END ? parent[j] != 0 : \
                        dst == 0 ? otherwise[j] != 0 : parent[j] != 0 && otherwise[j] == 0; \
                active_count = 0; \
                for (size_t j = 0; j < m; ++j) active_count += active[j]; \
                continue; \
            } \
            if (!active_count) continue; \
            if (op == TS_OP_SPILL || op == TS_OP_RELOAD) { \
                if (slot >= slots) return -4; \
                type *saved = scratch + slot * TS_KERNEL_BLOCK; \
                type *value = dst == TS_KERNEL_OUTPUT ? out + base : dst < TS_KERNEL_REGISTERS ? \
                    registers[dst] : (type *)(inputs[dst - TS_KERNEL_REGISTERS] + input_offset + base); \
                if (active_count == m) { \
                    if (op == TS_OP_SPILL) memcpy(saved, value, m * sizeof(type)); \
                    else memcpy(value, saved, m * sizeof(type)); \
                } else for (size_t j = 0; j < m; ++j) if (active[j]) { \
                    if (op == TS_OP_SPILL) memcpy(saved + j, value + j, sizeof(type)); \
                    else memcpy(value + j, saved + j, sizeof(type)); \
                } \
                continue; \
            } \
            type *destination = dst == TS_KERNEL_OUTPUT ? out + base : registers[dst]; \
            if (op == TS_OP_CONSTANT) { \
                for (size_t j = 0; j < m; ++j) if (active[j]) memcpy(destination + j, constants + a, sizeof(type)); \
                continue; \
            } \
            const type *left = a < TS_KERNEL_REGISTERS ? registers[a] : inputs[a - TS_KERNEL_REGISTERS] + input_offset + base; \
            int binary = (op >= TS_OP_ADD && op <= TS_OP_DIVIDE) || op == TS_OP_MIN || op == TS_OP_MAX || \
                op == TS_OP_FMA || (op >= TS_OP_EQ && op <= TS_OP_SELECT); \
            const type *right = binary ? (b < TS_KERNEL_REGISTERS ? registers[b] : inputs[b - TS_KERNEL_REGISTERS] + input_offset + base) : NULL; \
            if (active_count == m) { \
                int status = apply(op, destination, left, right, m); \
                if (status) return status; \
            } else { \
                for (size_t j = 0; j < m; ++j) { \
                    safe_left[j] = active[j] ? left[j] : op == TS_OP_LOG ? 1 : 0; \
                    if (binary) safe_right[j] = active[j] ? right[j] : op == TS_OP_DIVIDE ? 1 : 0; \
                    if (op == TS_OP_FMA) result[j] = active[j] ? destination[j] : 0; \
                } \
                int status = apply(op, result, safe_left, binary ? safe_right : NULL, m); \
                if (status) return status; \
                for (size_t j = 0; j < m; ++j) if (active[j]) memcpy(destination + j, result + j, sizeof(type)); \
            } \
        } \
    } \
    return 0; \
}
TS_LAZY_KERNEL(f32, float, ts_kernel_apply_elementwise_f32)
TS_LAZY_KERNEL(f64, double, ts_kernel_apply_elementwise_f64)
TS_LAZY_KERNEL(s8, uint8_t, ts_lazy_apply_s8)
TS_LAZY_KERNEL(u8, uint8_t, ts_lazy_apply_u8)
TS_LAZY_KERNEL(s16, uint16_t, ts_lazy_apply_s16)
TS_LAZY_KERNEL(u16, uint16_t, ts_lazy_apply_u16)
TS_LAZY_KERNEL(s32, uint32_t, ts_lazy_apply_s32)
TS_LAZY_KERNEL(u32, uint32_t, ts_lazy_apply_u32)
TS_LAZY_KERNEL(s64, uint64_t, ts_lazy_apply_s64)
TS_LAZY_KERNEL(u64, uint64_t, ts_lazy_apply_u64)
#undef TS_LAZY_KERNEL

#if defined(__clang__)
#define TS_LAZY_FENV _Pragma("STDC FENV_ACCESS ON")
#else
#define TS_LAZY_FENV
#endif

#define TS_LAZY_EVALUATE(suffix, type, integral, reduce) \
static int ts_lazy_evaluate_##suffix(const uint8_t *code, size_t length, const type *constants, \
        const type *const *inputs, type *out, size_t n, size_t slots, type *scratch, int sum) { \
    TS_LAZY_FENV \
    if (!n) { if (sum) *out = 0; return 0; } \
    if (slots > SIZE_MAX / TS_KERNEL_BLOCK / sizeof(type)) return -1; \
    int status = ts_lazy_validate(code, length, slots, TS_KERNEL_OUTPUT - TS_KERNEL_REGISTERS, scratch, sizeof(type)); \
    if (status) return status; \
    fenv_t environment; \
    if (!integral && feholdexcept(&environment)) return -5; \
    if (!sum) status = ts_lazy_kernel_##suffix(code, length, constants, inputs, out, n, slots, scratch, 0); \
    else { \
        type total = 0; \
        for (size_t base = 0; base < n; base += TS_KERNEL_BLOCK) { \
            size_t m = n - base < TS_KERNEL_BLOCK ? n - base : TS_KERNEL_BLOCK; \
            type values[TS_KERNEL_BLOCK], block; \
            status = ts_lazy_kernel_##suffix(code, length, constants, inputs, values, m, slots, scratch, base); \
            if (status) break; \
            reduce; \
            total = integral ? (type)((uint64_t)total + (uint64_t)block) : total + block; \
        } \
        if (!status) *out = total; \
    } \
    if (!integral) { \
        int exceptions = fetestexcept(FE_INVALID | FE_DIVBYZERO | FE_OVERFLOW | FE_UNDERFLOW); \
        if (fesetenv(&environment) || exceptions) status = -5; \
    } \
    return status; \
}

TS_LAZY_EVALUATE(f32, float, 0, block = ts_sum_f32(values, m))
TS_LAZY_EVALUATE(f64, double, 0, block = ts_sum_f64(values, m))
TS_LAZY_EVALUATE(s8, uint8_t, 1, ts_sum_s8(values, &block, m))
TS_LAZY_EVALUATE(u8, uint8_t, 1, ts_sum_u8(values, &block, m))
TS_LAZY_EVALUATE(s16, uint16_t, 1, ts_sum_s16(values, &block, m))
TS_LAZY_EVALUATE(u16, uint16_t, 1, ts_sum_u16(values, &block, m))
TS_LAZY_EVALUATE(s32, uint32_t, 1, ts_sum_s32(values, &block, m))
TS_LAZY_EVALUATE(u32, uint32_t, 1, ts_sum_u32(values, &block, m))
TS_LAZY_EVALUATE(s64, uint64_t, 1, ts_sum_s64(values, &block, m))
TS_LAZY_EVALUATE(u64, uint64_t, 1, ts_sum_u64(values, &block, m))

#undef TS_LAZY_EVALUATE
#undef TS_LAZY_FENV
