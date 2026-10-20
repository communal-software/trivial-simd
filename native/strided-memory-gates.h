#if defined(__x86_64__) || defined(_M_X64)
#define TS_STRIDED_MEMORY_MIN_COUNT 256
{40393, 16384}, /* f32 sum 1,-2,1,1 */
{40418, 256}, /* f32 sum 1,-1,1,1 */
{40493, 256}, /* f32 sum 1,2,1,1 */
#else
#define TS_STRIDED_MEMORY_MIN_COUNT SIZE_MAX
{UINT32_MAX, SIZE_MAX}
#endif
