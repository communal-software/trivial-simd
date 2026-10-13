#include <stdint.h>
#include <stdlib.h>
#include <string.h>

static uintptr_t scratch_start;
static size_t scratch_size, allocations, reads, writes;

static void *profile_malloc(size_t size) {
    void *buffer = malloc(size);
    ++allocations;
    scratch_start = (uintptr_t)buffer;
    scratch_size = size;
    return buffer;
}

static void profile_free(void *buffer) {
    free(buffer);
    scratch_start = 0;
    scratch_size = 0;
}

static int in_scratch(const void *pointer, size_t size) {
    uintptr_t address = (uintptr_t)pointer;
    return scratch_start && address >= scratch_start &&
        size <= scratch_size && address - scratch_start <= scratch_size - size;
}

static void *profile_memcpy(void *destination, const void *source, size_t size) {
    if (in_scratch(source, size)) reads += size;
    if (in_scratch(destination, size)) writes += size;
    return memcpy(destination, source, size);
}

#define malloc profile_malloc
#define free profile_free
#undef memcpy
#define memcpy profile_memcpy
/* Keep VM calls bound to this instrumented copy when the normal library is loaded. */
#define ts_kernel_mask_f32 ts_sharing_kernel_mask_f32
#define ts_kernel_mask_s8 ts_sharing_kernel_mask_s8
#define ts_kernel_mask_u64 ts_sharing_kernel_mask_u64
#define ts_kernel_with_scratch_f32 ts_sharing_kernel_with_scratch_f32
#define ts_kernel_with_scratch_s8 ts_sharing_kernel_with_scratch_s8
#define ts_kernel_with_scratch_u64 ts_sharing_kernel_with_scratch_u64
#define ts_kernel_reduction_f32 ts_sharing_kernel_reduction_f32
#define ts_kernel_reduction_s8 ts_sharing_kernel_reduction_s8
#define ts_kernel_reduction_u64 ts_sharing_kernel_reduction_u64
#include "../native/trivial_simd.c"
#undef memcpy
#undef free
#undef malloc

#define PROFILE_CASE(tag, suffix, type) \
    case tag: { \
        type value; double wide; size_t index; \
        status = lazy ? ts_kernel_reduction_##suffix(code, length, constants, inputs, 2, n, slots, \
                                                     TS_REDUCE_SUM, 1, &value, &wide, &index) \
                      : ts_kernel_mask_##suffix(code, length, constants, inputs, 2, NULL, n, slots, 1, &index); \
        break; \
    }

int ts_sharing_profile(const uint8_t *code, size_t length, const void *constants,
                       const void *inputs, size_t n, size_t slots, unsigned type,
                       int lazy, size_t *allocation_count, size_t *read_bytes, size_t *write_bytes) {
    allocations = reads = writes = 0;
    int status;
    switch (type) {
        PROFILE_CASE(0, f32, float)
        PROFILE_CASE(2, s8, uint8_t)
        PROFILE_CASE(9, u64, uint64_t)
        default: return -4;
    }
    *allocation_count = allocations;
    *read_bytes = reads;
    *write_bytes = writes;
    return status;
}
