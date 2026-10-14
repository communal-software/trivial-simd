"""Check SIMD and scalar native products against pinned llama.cpp fixtures."""
import ctypes
import pathlib
import re
import subprocess
import tempfile
import sys

root = pathlib.Path(__file__).resolve().parents[1]
fixtures = (root / "tests/packed-golden.lisp").read_text()
with tempfile.TemporaryDirectory() as temporary:
    extension = ".dylib" if sys.platform == "darwin" else ".so"
    scalar = pathlib.Path(temporary) / ("packed-scalar" + extension)
    flags = ["-dynamiclib"] if sys.platform == "darwin" else ["-shared", "-fPIC"]
    subprocess.run(["cc", "-O3", "-DTS_SCALAR", *flags, str(root / "native/packed-matmul.c"), "-o", str(scalar)], check=True)
    for path in (root / ("build/libtrivial_simd" + extension), scalar):
        library = ctypes.CDLL(str(path))
        function = library.ts_packed_matmul
        function.argtypes = (ctypes.c_int, ctypes.c_int64, ctypes.c_int64, ctypes.c_int64,
                             ctypes.c_void_p, ctypes.c_void_p, ctypes.c_int64, ctypes.c_void_p, ctypes.c_int64)
        for dtype, payload, expected in re.findall(r"\(:(q4_0|q4_k|q6_k)\s+#\((.*?)\)\s+#\((.*?)\)\)", fixtures, re.S):
            type_id = {"q4_0": 2, "q4_k": 12, "q6_k": 14}[dtype]
            bytes_ = [int(v) for v in payload.split()]
            weights = [float(v.replace("f", "e")) for v in expected.split()]
            blocks = (ctypes.c_uint8 * len(bytes_))(*bytes_)
            for m in (1, 5):
                k = len(weights) // m
                for n in (1, 3, 4, 5, 9):
                    xs, os = k+3, m+2
                    x = (ctypes.c_float * (n*xs))(*((i*7 % 19 - 9)*0.1 for i in range(n*xs)))
                    out = (ctypes.c_float * (n*os))(*([-99.0]*(n*os)))
                    assert function(type_id, n, m, k, blocks, x, xs, out, os) == 0
                    for i in range(n):
                        for j in range(m):
                            products = [x[i*xs+e]*weights[j*k+e] for e in range(k)]
                            assert abs(out[i*os+j]-sum(products)) <= 1e-5 + 1e-5*sum(map(abs, products)), (path, dtype, n, m)
                        assert list(out)[i*os+m:(i+1)*os] == [-99.0]*2
            offset = {2: 1, 12: 3, 14: 209}[type_id]
            blocks[offset] = 124
            out = (ctypes.c_float * 5)(*([-99.0]*5))
            assert function(type_id, 1, 5, k, blocks, x, xs, out, 5) == 2
            assert list(out) == [-99.0]*5
print("Native SIMD and scalar packed kernels pass")
