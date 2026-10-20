from pathlib import Path
root=Path('/Users/george/git/trivial-simd');work=Path('/tmp/encoded-format-specialization-2026-10-20');work.mkdir(exist_ok=True)
s=(root/'native/encoded-matmul.c').read_text();(work/'before.c').write_text(s)
s=s.replace('#define DEFINE_ENCODED_TILE(name, ROWS, COLS)', '#define DEFINE_ENCODED_TILE(name, ROWS, COLS, MODE)')
s=s.replace('float *out, int64_t os) { \\\n    for', 'float *out, int64_t os) { \\\n    (void)f16; \\\n    for')
s=s.replace('ws + e, f16)', 'ws + e, MODE)')
s=s.replace('float w = f16 ? ts_f16_to_f32_scalar(bits)', 'float w = MODE ? ts_f16_to_f32_scalar(bits)', 1)
a='''DEFINE_ENCODED_TILE(encoded_tile1, 1, 4)
DEFINE_ENCODED_TILE(encoded_tile_batch, 6, 4)'''
b='''DEFINE_ENCODED_TILE(encoded_tile1_bf16, 1, 4, 0)
DEFINE_ENCODED_TILE(encoded_tile1_f16_portable, 1, 4, 1)
DEFINE_ENCODED_TILE(encoded_tile1_f16_native, 1, 4, 2)
DEFINE_ENCODED_TILE(encoded_tile_batch, 6, 4, f16)

static void encoded_tile1(int f16, int64_t n, int64_t m, int64_t k,
                          const uint16_t *weights, int64_t ws,
                          const float *x, int64_t xs, float *out, int64_t os) {
    if (f16 == 0)
        encoded_tile1_bf16(f16, n, m, k, weights, ws, x, xs, out, os);
    else if (f16 == 2)
        encoded_tile1_f16_native(f16, n, m, k, weights, ws, x, xs, out, os);
    else
        encoded_tile1_f16_portable(f16, n, m, k, weights, ws, x, xs, out, os);
}'''
assert a in s;s=s.replace(a,b)
s=s.replace('DEFINE_ENCODED_TILE(encoded_tile1, 1, 4)','DEFINE_ENCODED_TILE(encoded_tile1, 1, 4, f16)')
s=s.replace('DEFINE_ENCODED_TILE(encoded_tile_batch, 4, 2)','DEFINE_ENCODED_TILE(encoded_tile_batch, 4, 2, f16)')
(work/'after.c').write_text(s)
