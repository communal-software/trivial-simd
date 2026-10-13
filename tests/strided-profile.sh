#!/bin/sh
set -eu

output=${1:?usage: tests/strided-profile.sh OUTPUT_DIRECTORY [SBCL]}
lisp=${2:-sbcl}
mkdir -p "$output"
export TRIVIAL_SIMD_STRIDED_PROFILE=1
for trial in 0 1 2 3 4; do
  export TRIVIAL_SIMD_STRIDED_TRIAL=$trial
  variants="general candidate"
  if [ $((trial % 2)) -eq 1 ]; then variants="candidate general"; fi
  for variant in $variants; do
    export TRIVIAL_SIMD_STRIDED_VARIANT=$variant
    export TRIVIAL_SIMD_STRIDED_OUTPUT=$output/$variant-$trial.csv
    "$lisp" --dynamic-space-size 4096 --script tests/strided-bench.lisp
  done
done
