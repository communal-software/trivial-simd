from pathlib import Path
root=Path('/Users/george/git/trivial-simd');work=Path('/tmp/encoded-format-specialization-2026-10-20/f16-only');work.mkdir(exist_ok=True)
s=(root/'native/encoded-matmul.c').read_text();(work/'before.c').write_text(s)
s=s.replace('#define DEFINE_ENCODED_TILE(name, ROWS, COLS)', '#define DEFINE_ENCODED_TILE(name, ROWS, COLS, MODE)')
s=s.replace('float *out, int64_t os) { \\\n    for', 'float *out, int64_t os) { \\\n    (void)f16; \\\n    for')
s=s.replace('ws + e, f16)', 'ws + e, MODE)')
s=s.replace('float w = f16 ? ts_f16_to_f32_scalar(bits)', 'float w = MODE ? ts_f16_to_f32_scalar(bits)', 1)
s=s.replace('DEFINE_ENCODED_TILE(encoded_tile1, 1, 4)', 'DEFINE_ENCODED_TILE(encoded_tile1, 1, 4, f16)')
s=s.replace('DEFINE_ENCODED_TILE(encoded_tile_batch, 6, 4)', '''DEFINE_ENCODED_TILE(encoded_tile_batch, 6, 4, f16)
#if defined(__aarch64__)
DEFINE_ENCODED_TILE(encoded_tile1_f16_native, 1, 4, 2)
#endif''')
s=s.replace('DEFINE_ENCODED_TILE(encoded_tile_batch, 4, 2)', 'DEFINE_ENCODED_TILE(encoded_tile_batch, 4, 2, f16)')
marker='''#ifdef TS_ENCODED_PACKED
    (n == 1 ? encoded_tile1 : encoded_tile_batch)'''
replacement='''#ifdef TS_ENCODED_PACKED
#if defined(__aarch64__)
    if (n == 1 && f16 == 2) {
        encoded_tile1_f16_native(f16, n, m, k, weights, weights_stride, x, x_stride, out, out_stride);
        return 0;
    }
#endif
    (n == 1 ? encoded_tile1 : encoded_tile_batch)'''
assert marker in s;s=s.replace(marker,replacement);(work/'after.c').write_text(s)
